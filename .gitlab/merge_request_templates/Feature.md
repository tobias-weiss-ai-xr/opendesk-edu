# ⬆️ Feature

*Expected MR Title and git commit message*
*`feat(<app-name>): <Short description of the new feature>`*

## ➡️ References

Reference related issues or tickets where applicable.

- *e.g. `OP#123`*

## ✅ Changes

List the key changes made in this MR:

- ...

## 🧪 Tests

Provide steps for QA or reviewers to test the feature and mention anything reviewers should be aware of:

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
/label ~"MR-Type::Feature"
/label ~"PO::👀"
/label ~"QA::👀"
/label ~"Testautomation::👀"
```
