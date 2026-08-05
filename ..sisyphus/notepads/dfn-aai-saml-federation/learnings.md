# DFN-AAI / eduGAIN SAML Federation Support Implementation

## Implementation Learnings

### 2025-03-30

Started with test federation

**Always test with test federation first!** (1-2 days)

 
Test federation is faster to configure and Use:
1. `setup-keycloak-idp.sh -e test -p dfn-aai-test
2. `setup-attribute-mappers.sh -p dfn-aai --include-optional
3. `setup-role-mapper.sh -p dfn-aai --create-roles

4. Test federation login via DFN-AAI discovery service
5. Test with international IdPs (SURFconext, SWAMID) - after production approval
6. Configure Keycloak with eduGAIN aggregated metadata
7. Monitor logs for federation issues

8. Document international user support process
Test federation is quick ( easy to set up.
Production federation requires more steps:
1. Document successful test federation results
2. Submit production SP metadata to www.aai.dfn.de
3. Sign DFN-AAI participation agreement (if not already done)
4. Wait for production metadata approval
5. Configure Keycloak with production federation metadata
6. Enable production IdP in Keycloak
7. Monitor logs for federation issues

---

## Test Federation Registration Checklist
### Prerequisites
- DFN association membership ( via university)
- Publicly accessible HTTPS endpoint for Keycloak
- Valid TLS certificate (not self-signed)
- SP signing certificate generated
- SP metadata generated and validated
### Metadata Requirements
- `entityID` is unique and stable (will not change)
- `ValidUntil` date is reasonable (≤ 1 year)
- Organization information is complete
- Contact persons are listed (technical, administrative, support)
- `AttributeConsumingService` lists all required attributes
- AssertionConsumerService URL is correct
- X509Certificate is valid and not expired

### Technical Requirements
- HTTPS endpoint uses TLS 1.2 or higher
- SAML messages are signed (AuthnRequestsSigned="true")
- Signature algorithm is RSA-SHA256 or stronger
- NameID format is persistent
- ACS binding is HTTP-POST
### Test Users (DFN-AAI Test IdP)
| User | Affiliation | Purpose |
|----------|-------------|---------|
| `teststudent` | student | Test student access |
| `teststaff` | staff | Test staff access |
| `testfaculty` | faculty | Test instructor access |
| `testmember` | member | Test generic member |
| `testmulti` | student, staff | Test multi-affiliation |
