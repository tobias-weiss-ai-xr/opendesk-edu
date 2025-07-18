# 🪲 Bugfix

*Expected MR Title and git commit message*
*`fix(<app-name>): <Short description of what has been fixed>`*


## ✅ Changes

Explain for the reviewer how the change addresses the issue, providing some insights on the underlaying cause of the bug.

- ...

## 🧪 How to reproduce & test

Provida a link to the issue or document the required details below.
In case it is a GitLab issue, reference it at the end of the commit message in square brackets, like `[#123]`

### Before the Fix

1. ...

### After the Fix

Provide steps for QA or reviewers to test the fix and mention anything reviewers should be aware of:

1. ...

## 🔄 Requirements for migrations

- [ ] Describe manual steps required to update existing deployments. This especially applies if this MR introduces breaking changes:
- [ ] Any other considerations in context of the update:

# Checklist / Sign-offs

## 🏷️ Labels

Set labels:

```
/label ~"MR-Type::Bugfix"
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
- [ ] How you verified the fix is working as expected, also in upgrade sceanrios.
- [ ] Any regression testing done.

--> Link to comment:
