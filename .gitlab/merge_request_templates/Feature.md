# ⬆️ Feature

*Expected MR Title and git commit message*
*`feat(<app-name>): <Short description of the new feature>`*

## ➡️ References

*Where applicable. Remove (sub)section(s) when not needed*

### Related issues or tickets

- *e.g. `OP#123`*

### Related MRs

- *e.g. https://gitlab.opencode.de/bmi/opendesk/components/platform-development/charts/opendesk-nextcloud/-/merge_requests/35*

## ✅ Changes

List the key changes made in this MR:

- ...

## 🧪 Tests

Provide steps for QA or reviewers to test the feature and mention anything reviewers should be aware of:

- ...

# 👷 Developer Checklist

**Documentation:**

This MR introduce **ANY** new (non migration related) Helmfile options:
- [ ] No
- [ ] Yes, and the documentation (updates.md) is addressing these changes.

This MR introduce new (migration related) Helmfile options or other changes requiring automated or manual migrations:
- [ ] No
- [ ] Yes, and the documentation (migrations-*.md) is addressing these changes.

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
