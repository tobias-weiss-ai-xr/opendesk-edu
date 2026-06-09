# 🪲 Bugfix

*Expected MR Title and git commit message*
*`fix(<app-name>): <Short description of what has been fixed>`*

## ➡️ References

*Where applicable. Remove (sub)section(s) when not needed*

### Related issues or tickets

- *e.g. `OP#123`*

### Related MRs

- *e.g. https://gitlab.opencode.de/bmi/opendesk/components/platform-development/charts/opendesk-nextcloud/-/merge_requests/35*

## ✅ Changes

Explain for the reviewer how the change addresses the issue, providing some insights on the underlaying cause of the bug.

- ...

## 🧪 How to reproduce & test

Provide a link to the issue or document the required details below.
In case it is a GitLab issue, reference it at the end of the commit message in square brackets, like `[#123]`
Provide steps for QA or reviewers to test the fix and mention anything reviewers should be aware of.

### Steps to reproduce

1. ...

### Actual behaviour

*Based on the "Steps to reproduce" explain what the user sees while the bug isn't fixed.*

### Expected behaviour

*Based on the "Steps to reproduce" explain what the user gets to see with the bug fix merged.*

## 🔄 Requirements for migrations

- [ ] Describe manual steps required to update existing deployments. This especially applies if this MR introduces breaking changes:
- [ ] Any other considerations in context of the update:

# 👷 Developer Checklist

Does this MR introduce **ANY** new (non migration related) Helmfile options?
- [ ] No
- [ ] Yes, and the documentation (updates.md) is addressing these changes.

Does this MR introduce new (migration related) Helmfile options or other changes requiring automated or manual migrations?
- [ ] No
- [ ] Yes -> **This should not happen on bugfix MRs**

**Quality Assurance:**

- [ ] Verified that the fix works as expected, including upgrade scenarios
- [ ] Performed regression testing

# Set labels

```
/label ~"MR-Type::Bugfix"
/label ~"PO::👀"
/label ~"QA::👀"
/label ~"Testautomation::👀"
```
