# 🪲 Bugfix

*Expected MR Title and git commit message*
*`fix(<app-name>): <Short description of what has been fixed>`*


## ✅ Changes

Explain for the reviewer how the change addresses the issue, providing some insights on the underlaying cause of the bug.

- ...

## 🧪 How to reproduce & test

Provida a link to the issue or document the required details below.
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

# Checklist / Sign-offs

## 🏷️ Labels

Set labels:

```
/label ~"MR-Type::Bugfix"
/label ~"PO::👀"
/label ~"QA::👀"
/label ~"Testautomation::👀"
```

 # 👷 Developer Checklist

**Documentation:**

Does this MR introduce changes (e.g., new secrets, configuration options) that require documentation?
- [ ] No
- [ ] Yes, and the documentation has been updated accordingly

**Quality Assurance:**
- [ ] Verified that the feature works as expected, including upgrade scenarios
- [ ] Performed regression testing
- Link to internal comment(s) with detailed QA results (to avoid exposing infrastructure details):
  - ...
