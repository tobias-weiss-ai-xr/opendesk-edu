# 🎉 Other

*Expected MR Title and git commit message*
*`fix(<component>): <Short description of what has been changed>`*

## ✅ Changes

Explain for the reviewer and QA the reason for the MR and what changes are included.

- ...

## 🔄 Requirements for migrations

- [ ] Describe manual steps required to update existing deployments. This especially applies if this MR introduces breaking changes:
- [ ] Any other considerations in context of the update:

# 👷 Developer Checklist

**Documentation:**

Does this MR introduce **ANY** new (non migration related) Helmfile options?

- [ ] No
- [ ] Yes, and the documentation (updates.md) is addressing these changes.
Does this MR introduce new (migration related) Helmfile options or other changes requiring automated or manual migrations?
- [ ] No
- [ ] Yes, and the documentation (migrations.md) is addressing these changes.

**Quality Assurance:**

- [ ] Verified that the feature works as expected, including upgrade scenarios
- [ ] Performed regression testing

## Set labels

```
/label ~"MR-Type::Other"
/label ~"PO::👀"
/label ~"QA::👀"
/label ~"Testautomation::👀"
```
