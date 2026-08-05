# Sensitive Defaults Audit — Edu Helm Charts

**Date:** 2026-03-29
**Scope:** All `helmfile/charts/*/values.yaml` files (14 charts audited)

---

## Summary

| Severity | Count |
|----------|------:|
| HIGH     |     17 |
| MEDIUM   |     40 |
| LOW      |     20 |
| **Total**| **77** |

---

## HIGH — Security-Critical

These must be overridden before any production deployment. Leaving them unchanged leads to
compromised secrets, encryption bypass, or full database takeover.

### CHANGE_ME Strings

| # | Chart | Field Path | Current Value | Action |
|---|-------|-----------|---------------|--------|
| 1 | ilias | `mariadbgalera.galera.mariabackup.password` | `"CHANGE_ME_IN_PRODUCTION"` | Replace with a strong random password. Galera SST uses this to authenticate backups between nodes. |

### Hardcoded Placeholder Credentials / Tokens

| # | Chart | Field Path | Current Value | Action |
|---|-------|-----------|---------------|--------|
| 2 | ilias | `mariadbgalera.rootUser.password` | `""` | Set a strong root password; empty may fall back to chart-generated or no password. |
| 3 | ilias | `mariadb.auth.rootPassword` | `""` | Set a strong root password; comment says "generated if empty" — verify behavior. |
| 4 | opencloud | `jwtSecret` | `""` | JWT signing secret — generate a cryptographically random string. |
| 5 | opencloud | `transferSecret` | `""` | Inter-service transfer secret — generate a cryptographically random string. |
| 6 | opencloud | `machineAuthApiKey` | `""` | Machine-to-machine API key — generate a strong random key. |
| 7 | opencloud | `systemUserApiKey` | `""` | System user API key — generate a strong random key. |
| 8 | opencloud | `urlSigningSecret` | `""` | URL signing secret — generate a cryptographically random string. |
| 9 | planka | `secretKey` | `""` | Encryption secret key for Planka — generate a cryptographically random string. |
| 10 | planka | `defaultPassword` | `""` | Admin password — set a strong password or rely on secretRef. |
| 11 | bigbluebutton | `greenlight.secretKeyBase` | `""` | Rails secret key base for session encryption — generate a random string. |
| 12 | bigbluebutton | `greenlight.databaseUrl` | `""` | Database connection URL — required before deployment. |
| 13 | f13 | `secrets.llmApi` | `""` | LLM provider API key — required for chat/summary/parser services. |
| 14 | f13 | `secrets.huggingfaceToken` | `""` | Hugging Face token — required for model downloads. |

### Empty Secret Keys (Cryptographic Material)

| # | Chart | Field Path | Current Value | Action |
|---|-------|-----------|---------------|--------|
| 15 | opencloud | `oidc.clientSecret` | `""` | OIDC client secret — generate and register with Keycloak. |
| 16 | sogo | `oidc.clientSecret` | `""` | OIDC client secret — generate and register with Keycloak. |
| 17 | planka | `oidc.clientSecret` | `""` | OIDC client secret — generate and register with Keycloak. |

---

## MEDIUM — Configuration Risks

These will cause deployment failures, broken integrations, or insecure configurations if left unchanged.

### Empty Database Passwords (Application-Level)

| # | Chart | Field Path | Current Value | Action |
|---|-------|-----------|---------------|--------|
| 1 | ilias | `ilias.db.password` | `""` | Set or confirm auto-generation via mariadb chart. |
| 2 | ilias | `ilias.rootPassword` | `""` | ILIAS root password — set a strong value. |
| 3 | ilias | `mariadbgalera.db.password` | `""` | Galera DB user password — set a strong value. |
| 4 | ilias | `mariadb.auth.password` | `""` | MariaDB user password — set or confirm auto-generation. |
| 5 | zammad | `zammad.db.password` | `""` | Set or confirm auto-generation via postgresql chart. |
| 6 | zammad | `postgresql.auth.password` | `""` | PostgreSQL user password — set a strong value. |
| 7 | sogo | `sogo.db.password` | `""` | Set a strong password for SOGo database access. |
| 8 | limesurvey | `limesurvey.db.password` | `""` | Set or confirm auto-generation via mariadb chart. |
| 9 | limesurvey | `mariadb.auth.password` | `""` | MariaDB user password — set a strong value. |
| 10 | limesurvey | `mariadb.auth.rootPassword` | `""` | MariaDB root password — set a strong value. |
| 11 | bookstack | `bookstack.db.password` | `""` | Set or confirm auto-generation via mariadb chart. |
| 12 | bookstack | `mariadb.auth.password` | `""` | MariaDB user password — set a strong value. |
| 13 | planka | `postgresql.auth.password` | `""` | PostgreSQL user password — set a strong value. |
| 14 | etherpad | `etherpad.db.password` | `""` | Set a strong password for Etherpad database access. |

### Empty LDAP Bind Credentials

| # | Chart | Field Path | Current Value | Action |
|---|-------|-----------|---------------|--------|
| 15 | sogo | `sogo.ldap.bindPassword` | `""` | Set the LDAP service bind password. |
| 16 | self-service-password | `selfServicePassword.ldap.bindDn` | `""` | Set the LDAP bind DN for password operations. |
| 17 | self-service-password | `selfServicePassword.ldap.baseDn` | `""` | Set the LDAP base DN. |

### Empty Endpoints / URLs

| # | Chart | Field Path | Current Value | Action |
|---|-------|-----------|---------------|--------|
| 18 | ilias | `ilias.db.host` | `""` | Confirm auto-population by mariadb chart. |
| 19 | ilias | `ilias.hostName` | `""` | Set to actual FQDN; defaults to pod hostname which may break external access. |
| 20 | zammad | `zammad.db.host` | `""` | Confirm auto-population by postgresql chart. |
| 21 | zammad | `zammad.elasticsearch.host` | `""` | Confirm auto-population by elasticsearch chart. |
| 22 | limesurvey | `limesurvey.db.host` | `""` | Confirm auto-population by mariadb chart. |
| 23 | bookstack | `bookstack.db.host` | `""` | Confirm auto-population by mariadb chart. |
| 24 | etherpad | `etherpad.db.host` | `""` | Set to actual PostgreSQL host. |
| 25 | planka | `planka.baseUrl` | `""` | Set to the public base URL of Planka. |
| 26 | planka | `planka.oidc.authEndpoint` | `""` | Set to Keycloak auth endpoint. |
| 27 | planka | `planka.oidc.tokenEndpoint` | `""` | Set to Keycloak token endpoint. |
| 28 | planka | `planka.oidc.userinfoEndpoint` | `""` | Set to Keycloak userinfo endpoint. |
| 29 | f13 | `global.keycloakUrl` | `""` | Set to Keycloak URL. |
| 30 | f13 | `authentication.keycloakBaseUrl` | `""` | Set to Keycloak base URL. |
| 31 | f13 | `authentication.keycloakRealm` | `""` | Set to Keycloak realm name. |
| 32 | f13 | `llm.apiUrl` | `""` | Set to LLM provider API URL. |
| 33 | f13 | `elasticsearch.existingHost` | `""` | Set if using external Elasticsearch. |
| 34 | opencloud | `oidc.internalIssuer` | `""` | Set to internal Keycloak issuer URL. |
| 35 | opencloud | `oidc.adminUserId` | `""` | Set to the admin user ID for OpenCloud. |

### Empty Identifiers / Credentials

| # | Chart | Field Path | Current Value | Action |
|---|-------|-----------|---------------|--------|
| 36 | planka | `planka.defaultEmail` | `""` | Set admin email for default Planka user. |
| 37 | planka | `planka.oidc.clientId` | `""` | Register OIDC client in Keycloak and set ID. |
| 38 | f13 | `rag.embeddingModel` | `""` | Set the embedding model name for RAG. |
| 39 | f13 | `llm.models.chat` | `""` | Set the chat model name. |
| 40 | f13 | `llm.models.summary` | `""` | Set the summary model name. |

### Placeholder Image References

| # | Chart | Field Path | Current Value | Action |
|---|-------|-----------|---------------|--------|
| 41 | moodle | `moodle.image` | `ghcr.io/<your-org>/moodle-shib` | Replace `<your-org>` with actual registry org. |
| 42 | opencloud | `image.repository` | `<your-org>/opencloud` | Replace `<your-org>` with actual registry org. |
| 43 | bigbluebutton | `bigbluebutton.image` | `ghcr.io/<your-org>/greenlight-saml` | Replace `<your-org>` with actual registry org. |

---

## LOW — Example Domains & Cosmetic Defaults

These use placeholder domains that must be changed for any real deployment but pose no direct security risk.

### Example Domains in Ingress Hosts

| # | Chart | Field Path | Current Value | Action |
|---|-------|-----------|---------------|--------|
| 1 | ilias | `ingress.hosts[0].host` | `lms.opendesk.example.com` | Replace with actual domain. |
| 2 | ilias | `ingress.tls[0].hosts[0]` | `lms.opendesk.example.com` | Replace with actual domain. |
| 3 | zammad | `ingress.hosts[0].host` | `helpdesk.opendesk.example.com` | Replace with actual domain. |
| 4 | zammad | `ingress.tls[0].hosts[0]` | `helpdesk.opendesk.example.com` | Replace with actual domain. |
| 5 | sogo | `ingress.hosts[0].host` | `sogo.opendesk.example.com` | Replace with actual domain. |
| 6 | planka | `ingress.hosts[0].host` | `planka.opendesk.example.com` | Replace with actual domain. |
| 7 | planka | `ingress.tls[0].hosts[0]` | `planka.opendesk.example.com` | Replace with actual domain. |
| 8 | moodle | `ingress.hosts[0].host` | `moodle.opendesk.example.com` | Replace with actual domain. |
| 9 | moodle | `ingress.tls[0].hosts[0]` | `moodle.opendesk.example.com` | Replace with actual domain. |
| 10 | opencloud | `ingress.hosts[0].host` | `opencloud.opendesk.example.com` | Replace with actual domain. |
| 11 | opencloud | `ingress.tls[0].hosts[0]` | `opencloud.opendesk.example.com` | Replace with actual domain. |
| 12 | limesurvey | `ingress.hosts[0].host` | `survey.opendesk.example.com` | Replace with actual domain. |
| 13 | limesurvey | `ingress.tls[0].hosts[0]` | `survey.opendesk.example.com` | Replace with actual domain. |
| 14 | f13 | `ingress.hostname` | `f13.opendesk.example.com` | Replace with actual domain. |
| 15 | bookstack | `ingress.hosts[0].host` | `wiki.opendesk.example.com` | Replace with actual domain. |
| 16 | bookstack | `ingress.tls[0].hosts[0]` | `wiki.opendesk.example.com` | Replace with actual domain. |
| 17 | bigbluebutton | `ingress.hosts.host` | `bbb.opendesk.example.com` | Replace with actual domain. |

### Example Domains in Other Configuration

| # | Chart | Field Path | Current Value | Action |
|---|-------|-----------|---------------|--------|
| 18 | ilias | `ilias.setupJson` (email field) | `noreply@opendesk.example.com` | Replace with actual notification email. |
| 19 | moodle | `moodle.moodleEmail` | `admin@opendesk.example.com` | Replace with actual admin email. |
| 20 | limesurvey | `limesurvey.adminEmail` | `admin@opendesk.example.com` | Replace with actual admin email. |

### Additional Example Domains in URLs

| # | Chart | Field Path | Current Value | Action |
|---|-------|-----------|---------------|--------|
| 21 | sogo | `sogo.mailDomain` | `opendesk.example.com` | Replace with actual mail domain. |
| 22 | sogo | `sogo.oidc.configUrl` | `https://keycloak.opendesk.example.com/realms/opendesk/.well-known/openid-configuration` | Replace with actual Keycloak URL. |
| 23 | opencloud | `oidc.issuer` | `https://id.opendesk.example.com/realms/opendesk` | Replace with actual Keycloak issuer. |
| 24 | opencloud | `oidc.accountEditLink` | `https://id.opendesk.example.com/realms/opendesk/account` | Replace with actual Keycloak account URL. |

---

## Charts with No Findings

| Chart | Notes |
|-------|-------|
| excalidraw | Clean — no sensitive defaults. |
| drawio | Clean — no sensitive defaults. |

---

## Recommendations

1. **Immediate (before any deployment):** Address all HIGH findings. Add helmfile `--set` overrides or a `secrets.yaml.gotmpl` environment file with `{{ randAlphaNum 32 }}` for cryptographic secrets.
2. **Before production:** Address all MEDIUM findings. Set database passwords, configure endpoints, and replace placeholder image references.
3. **Before go-live:** Replace all `opendesk.example.com` domains with actual deployment domains.
4. **Validation:** Consider adding a helmfile linter or CI check that rejects deployments containing `CHANGE_ME`, `<your-org>`, or empty password/secret fields.
