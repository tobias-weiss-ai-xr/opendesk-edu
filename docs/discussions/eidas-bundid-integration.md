# Proposal: bundID + EUDI Wallet Integration for openDesk

## Summary

Integrate German federal eID (bundID) and EU Digital Identity Wallet (EUDI) into
openDesk to meet OZG compliance and prepare for eIDAS 2.0 mandates.

## Motivation

- **OZG compliance** (Germany): Required for public sector platforms
- **eIDAS 2.0** (EU): Mandatory for EU public sector by 2028
- **Education use case**: Cross-border student mobility (Erasmus+), verifiable
  enrollment credentials, semester tickets
- **Accessibility**: Students without university accounts (guest auditors,
  cross-registration) can authenticate via national ID or EUDI Wallet

## Proposed Architecture

```
bundID ──SAML──┐
               ├──→ Keycloak (broker) ──→ Services (ILIAS, Moodle, …)
EUDI Wallet ──OIDC4VP─┘
```

- **Keycloak 26.7** acts as identity broker for both bundID (SAML) and EUDI Wallet (OIDC4VP/SIOP)
- Account linking: first-time external login matches to existing LDAP accounts or creates shadow users
- No changes needed in downstream services — Keycloak handles all brokering

## Implementation Phases

| Phase | Scope | Effort | Status |
|-------|-------|--------|--------|
| 1 | bundID SAML IdP in Keycloak | Low (config) | ✅ Implemented at HRZ |
| 2 | EUDI Wallet SIOP/OIDC4VP | Medium (KC config) | ✅ Client scaffolded |
| 3 | EUDI Issuer Service (VCs) | Large (new service) | ⏳ Helm chart scaffolded |

## Questions for the Community

1. Is there ongoing work on this topic elsewhere in openDesk?
2. Should the bundID IdP config become part of the base Keycloak Helm chart?
3. Is there interest in a shared EUDI Issuer service component?
4. Preferred approach for DID method (did:key vs cheqd vs ION)?

## References

- Full architecture doc: [`opendesk-edu` → `architecture/eidas.md`](https://github.com/opendesk-edu/opendesk-edu-knowledge)
- bundID docs: https://id.bund.de/dokumentation
- eIDAS 2.0: https://digital-strategy.ec.europa.eu/en/policies/eidas-regulation
- KC OID4VC: https://www.keycloak.org/docs/latest/securing_apps/#_oid4vc
