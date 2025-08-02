# 🎉 Other

*Expected MR Title and git commit message*
*`fix(<component>): <Short description of what has been changed>`*

## ✅ Changes

Explain for the reviewer and QA the reason for the MR and what changes are included.

- ...

## 🔄 Requirements for migrations

- [ ] Describe manual steps required to update existing deployments. This especially applies if this MR introduces breaking changes:
- [ ] Any other considerations in context of the update:

# Checklist / Sign-offs

## 🏷️ Labels

Set labels:

```
/label ~"MR-Type::Other"
/label ~"PO::👀"
/label ~"Tech Lead::👀"
/label ~"QA::👀"
/label ~"Testautomation::👀"
```

# 👷 Developer Checklist

- Does the MR include new bits and pieces (e.g. new secrets) that require documentation?
  - [ ] No.
  - [ ] Yes, and the documentation was updated accordingly.

Document in an extra comment and link to that comment:
- [ ] How you verified the change is working as expected, also in upgrade scenarios.
- [ ] Any regression testing done.

--> Link to comment:
