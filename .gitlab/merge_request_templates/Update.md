# ⬆️ Application Update

*Expected MR Title and git commit message*
*`feat/fix(<app-name>): Update from <old-version> to <new-version>`*

## 📋 Changelog/Release Notes

- [ ] [README.md](../../README.md) component table updated including the link to the related release notes of the updated application.
- [ ] Provide significant improvements you would like to see in the [openDesk release notes](https://www.opendesk.eu/en/blog/opendesk-1-6). If you have a lot of details to provide or someone else is providing the details, you can use a comment on this MR and provide a link here.

## 🔄 Requirements for migrations

- [ ] Minimum version of the application required in existing deployments to update/upgrade:
- [ ] Describe manual steps required to update existing deployments. This especially applies if the upgrade includes any breaking changes:
- [ ] Any other considerations in context of the update:

# Checklist / Sign-offs

## 🏷️ Labels

Set labels:

```
/label ~"MR-Type::AppUpdate"
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
