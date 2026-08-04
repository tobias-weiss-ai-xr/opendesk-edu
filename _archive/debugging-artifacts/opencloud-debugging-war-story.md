# Three Bugs That Blocked OpenCloud OIDC Login — A Debugging War Story

After a user auto-provisioned via Keycloak OIDC is successfully created in LDAP, OpenCloud's proxy can't issue a session token. The user sees "Sie werden eingeloggt" followed by "Nicht angemeldet". Every. Single. Time.

This is the story of how three independent bugs stacked to create that failure — and what it took to find them.

---

## The Setup

OpenCloud 4.0.3, deployed via Helm on Kubernetes, configured with an external UMS LDAP (OpenLDAP) as the identity backend. Users authenticate through Keycloak/Shibboleth via OIDC. Auto-provisioning is enabled: when a user logs in for the first time, OpenCloud creates their LDAP entry on the fly.

The error was consistent and reproducible:

1. User navigates to `https://opencloud...`
2. Clicks login → redirected to Keycloak → authenticates
3. Redirected back to OpenCloud → "Sie werden eingeloggt"
4. **"Nicht angemeldet"** — access denied

The OpenCloud logs showed a clear pattern:

```
graph:   failed to add user → LDAP Result Code 68 "Entry Already Exists"
graph:   could not create user: backend error → nameAlreadyExists
proxy:   Error Response → OData Error: a user with that name already exists
proxy:   Error getting token for autoprovisioned user → user not found
```

The auto-provision flow was:
1. Get UUID from OIDC "sub" claim
2. Search LDAP for existing user by UUID → **not found**
3. Try to create user in LDAP → **"Entry Already Exists"** (DN collision)
4. Fall through to → **"Nicht angemeldet"**

Every login attempt hit a wall. And the user DID exist in LDAP. Three independent bugs were responsible.

---

## Bug #1: LDAP Schema Missing `EQUALITY` on `openCloudUUID`

### The Symptom

The auto-provision code searches LDAP for an existing user by UUID before creating one. In our case, the user existed — but the search returned zero results.

### The Investigation

Testing the LDAP search directly:

```
$ ldapsearch ... "(openCloudUUID=*)"
→ returns the entry (presence check works)

$ ldapsearch ... "(openCloudUUID=b7ada882-...)"
→ returns 0 entries (equality check FAILS)
```

The attribute existed. The value was correct. But equality matching didn't work.

### The Root Cause

The `openCloudUUID` attribute type in the OpenLDAP schema was loaded **without** an `EQUALITY` rule:

```
# Loaded schema (broken):
olcAttributeTypes: ( 1.3.6.1.4.1.99999.1.1
  NAME 'openCloudUUID'
  SYNTAX 1.3.6.1.4.1.1466.115.121.1.15
  SINGLE-VALUE )

# Configmap definition (correct):
olcAttributeTypes: ( 1.3.6.1.4.1.99999.1.1
  NAME 'openCloudUUID'
  EQUALITY caseIgnoreMatch          ← MISSING from loaded schema!
  SYNTAX 1.3.6.1.4.1.1466.115.121.1.15
  SINGLE-VALUE )
```

Without `EQUALITY caseIgnoreMatch`, OpenLDAP can't perform equality matching on the attribute. The LDAP schema job only checked for the presence of new attribute OIDs — it never verified that existing attributes had correct matching rules. So when an old schema was loaded (from an earlier chart version that lacked `EQUALITY`), subsequent upgrades never fixed it.

### The Fix

1. **Live fix**: Add the `EQUALITY` rule to the running OpenLDAP via `ldapmodify`:

```bash
ldapmodify -Y EXTERNAL -H ldapi:/// <<'EOF'
dn: cn={53}opencloud,cn=schema,cn=config
changetype: modify
replace: olcAttributeTypes
olcAttributeTypes: ( 1.3.6.1.4.1.99999.1.1 NAME 'openCloudUUID'
  DESC 'OpenCloud user UUID'
  EQUALITY caseIgnoreMatch
  SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 SINGLE-VALUE )
olcAttributeTypes: ( 1.3.6.1.4.1.99999.1.2 ... )
olcAttributeTypes: ( 1.3.6.1.4.1.99999.1.3 ... )
olcAttributeTypes: ( 1.3.6.1.4.1.99999.1.4 ... )
EOF
```

2. **Persistent fix**: Updated the Helm chart's schema job to also check for `EQUALITY` on `openCloudUUID`, not just the presence of attribute OIDs.

---

## Bug #2: The Invisible Disabled Filter

### The Symptom

After fixing the UUID search, the LDAP lookup **still returned zero results** — but this time the reason was buried in the search filter.

### The Investigation

The reva LDAP user provider builds a search filter for `GetUserByClaim("userid", uuid)`. By tracing through the OpenCloud source code, the filter construction was:

```go
filter = fmt.Sprintf("(&%s(objectclass=%s)(%s=%s)%s%s)",
    i.User.Filter,
    i.User.Objectclass,           // "openCloudUser"
    attribute,                    // "openCloudUUID"
    value,                        // "b7ada882-..."
    i.tenantFilter(tenantID),     // ""
    i.disabledFilter(),           // "(!(openCloudUserEnabled=FALSE))"
)
```

The resulting filter:

```
(&(objectclass=openCloudUser)(openCloudUUID=b7ada882-...)(!(openCloudUserEnabled=FALSE)))
```

Testing it directly:

```
$ ldapsearch ... "(&(objectclass=openCloudUser)(openCloudUUID=b7ada882-...))"
→ 1 entry found

$ ldapsearch ... "(&(objectclass=openCloudUser)(openCloudUUID=b7ada882-...)(!(openCloudUserEnabled=FALSE)))"
→ 0 entries found
```

### The Root Cause

LDAP uses three-valued logic: TRUE, FALSE, and **UNDEFINED**. When an attribute doesn't exist on an entry:

- `(attr=FALSE)` → UNDEFINED (the attribute isn't present, so the comparison can't be evaluated)
- `(!(attr=FALSE))` → NOT(UNDEFINED) → **UNDEFINED**
- `(TRUE AND TRUE AND UNDEFINED)` → **UNDEFINED** → entry is **not returned**

The user entry in our UMS LDAP didn't have an `openCloudUserEnabled` attribute. This is an OpenCloud-internal attribute that doesn't exist in the external LDAP. The `disabledFilter()` was designed for OpenCloud's internal IDM LDAP (which has this attribute), but when pointed at an external LDAP, it silently filtered out **every user**.

The `DisableUserMechanism` was set to `"attribute"` by default, which adds the `(!(openCloudUserEnabled=FALSE))` filter. In OpenCloud's internal IDM, every user has this attribute set to `TRUE`. In an external LDAP, nobody does.

### The Fix

```yaml
# values.yaml
oidc:
  roleAssignmentDriver: "default"

# → sets env var OC_LDAP_DISABLE_USER_MECHANISM=none
```

Setting `OC_LDAP_DISABLE_USER_MECHANISM=none` tells the users service to skip the disabled filter entirely. This is the correct setting when using an external LDAP that doesn't manage OpenCloud-specific attributes.

---

## Bug #3: OIDC Role Assignment Driver Requires Roles That Don't Exist

### The Symptom

After fixing the LDAP search, the login flow progressed further — but failed with a new error:

```
proxy: no roles in user claims
proxy: Error mapping role names to role ids → oidcroles.go:84
proxy: Could not get user roles → account_resolver.go:192
```

### The Investigation

The proxy was configured with `PROXY_ROLE_ASSIGNMENT_DRIVER=oidc`, which reads role information from OIDC claims and maps them to OpenCloud roles. Our Keycloak instance doesn't send roles in the OIDC token — it's a simple authentication-only setup.

The OIDC role mapper iterates over the claims, looks for roles, finds none, and returns an error. This error propagates up through the account resolver, which aborts the login.

I initially tried `GRAPH_ASSIGN_DEFAULT_USER_ROLE=true`, which controls whether the **Graph API** assigns a default role when creating users. But the error was coming from the **Proxy** after user creation, during token issuance. Two different code paths, two different env vars.

### The Root Cause

The `PROXY_ROLE_ASSIGNMENT_DRIVER` supports two values:

| Driver | Behaviour |
|--------|-----------|
| `oidc` | Reads roles from OIDC claims. Fails if claims have no roles. |
| `default` | Assigns the role "user" to any user without a role at login time. |

The `oidc` driver is designed for setups where Keycloak sends roles via an OIDC claim (e.g., `roles`, `groups`, or a custom mapper). When used with a Keycloak that doesn't send roles, it's a hard blocker.

### The Fix

```yaml
# values.yaml
oidc:
  roleAssignmentDriver: "default"

# → sets env var PROXY_ROLE_ASSIGNMENT_DRIVER=default
```

The `default` driver checks if the user already has a role assigned. If not, it assigns the built-in "user" role. This is the correct choice for most simple OIDC setups.

---

## The Stack

Here's how the three bugs interacted:

```
User authenticates via OIDC
  ↓
Proxy calls GetUserByClaims("userid", uuid)
  ↓
Gateway delegates to users service (LDAP backend)
  ↓
Bug #1: LDAP schema → UUID equality search returns 0 entries
Bug #2: disabledFilter → existing user silently excluded from results
  ↓
GetUserByClaims → ErrAccountNotFound
  ↓
Proxy calls CreateUserFromClaims → Graph API → LDAP add → "Entry Already Exists"
  ↓
Cloud returns nameAlreadyExists → CreateUserFromClaims re-reads user → returns user
  ↓
Proxy calls GetUserByClaims again → STILL ErrAccountNotFound (bugs 1 & 2 again)
  ↓
Proxy falls through → tries role assignment
Bug #3: OIDC driver → no roles in claims → error
  ↓
"No roles in user claims" → 401 → "Nicht angemeldet"
```

Each bug alone would have been survivable in a different configuration:
- Bug #1 only matters if someone loads a broken schema
- Bug #2 only matters with external LDAP that lacks OpenCloud attributes
- Bug #3 only matters with OIDC providers that don't send roles

But **together**, they created a perfectly impenetrable wall.

---

## Lessons Learned

1. **Verify LDAP schema equality rules.** Presence checks (`attr=*`) can work fine while equality checks (`attr=value`) silently fail. Always test both.

2. **LDAP's three-valued logic is not intuitive.** `(!(attr=FALSE))` is NOT a no-op for absent attributes — it's **UNDEFINED**, which excludes entries from search results. If you're adding a "disabled" filter, make sure every user actually has the attribute.

3. **Know which service owns which env var.** `GRAPH_ASSIGN_DEFAULT_USER_ROLE` (Graph API, during user creation) and `PROXY_ROLE_ASSIGNMENT_DRIVER` (Proxy, during login/token issuance) control different stages of the same flow. Fixing the wrong one changes nothing.

4. **Always re-test after each fix.** Debugging three stacked bugs is only feasible if you verify each fix independently before moving to the next. The error messages changed at each step — that's how we knew we were making progress.

All three fixes are deployed in OpenCloud revision 50, with chart templates updated to prevent recurrence on future deployments.
