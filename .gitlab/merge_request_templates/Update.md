# ⬆️ Application Update

*Expected MR Title and git commit message*
*`feat/fix(<app-name>): Update from <old-version> to <new-version>`*

## ➡️ References

Reference related issues or tickets where applicable.

- *e.g. `OP#123`*

## 📋 Changelog/Release Notes

- [ ] [README.md](../../README.md) component table updated including the link to the related release notes of the updated application.
- [ ] Provide significant improvements you would like to see in the [openDesk release notes](https://www.opendesk.eu/en/blog/opendesk-1-6). If you have a lot of details to provide or someone else is providing the details, you can use a comment on this MR and provide a link here.

## 🔄 Requirements for migrations

- [ ] Minimum version of the application required in existing deployments to update/upgrade:
- [ ] Describe manual steps required to update existing deployments. This especially applies if the upgrade includes any breaking changes:
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

- [ ] Verified that the update works as expected, including upgrade scenarios
- [ ] Performed regression testing

## Set labels

```
/label ~"MR-Type::AppUpdate"
/label ~"PO::👀"
/label ~"QA::👀"
/label ~"Testautomation::👀"
```
