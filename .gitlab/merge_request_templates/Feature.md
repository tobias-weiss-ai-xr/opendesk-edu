# ⬆️ Feature

*Expected MR Title and git commit message*
*`feat(<app-name>): <Short description of the new feature>`*

## ✅ Changes

List the key changes made in this MR:

- ...

## 🧪 Tests

Provide steps for QA or reviewers to test the feature and mention anything reviewers should be aware of:

- ...

## 🔄 Requirements for migrations

- [ ] Describe manual steps required to update existing deployments. This especially applies if this MR introduces breaking changes:
- [ ] Any other considerations in context of the update:

# Checklist / Sign-offs

## 🏷️ Labels

Set labels:

```
/label ~"MR-Type::Feature"
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
- [ ] How you verified the feature is working as expected, also in upgrade scenarios.
- [ ] Any regression testing done.

--> Link to comment:
