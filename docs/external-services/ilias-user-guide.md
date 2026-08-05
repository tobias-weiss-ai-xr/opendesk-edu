# ILIAS User Guide

## Accessing ILIAS via openDesk Portal

### From Portal

1. Log into the openDesk portal at `https://portal.opendesk.example.com`
2. Click the **LMS** tile in the portal navigation
3. You will be automatically logged into ILIAS via SSO (no separate login required)

### Direct Access

1. Navigate to `https://lms.opendesk.example.com/shib_login.php`
2. If you are already logged into the portal, you will be authenticated automatically
3. If not logged in, you will be redirected to the Keycloak login page

### Requirements

- You must be a member of the `managed-by-attribute-Learnmanagement` LDAP group
- Contact your administrator if the LMS tile is not visible in the portal

## Logout

When you log out of the openDesk portal, your ILIAS session will also be terminated. You do not need to log out of ILIAS separately.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| LMS tile not visible | Ask your administrator to add you to the `managed-by-attribute-Learnmanagement` group |
| Redirected to login page | Your session may have expired. Log into the portal again |
| Error after login | Clear your browser cookies for `lms.opendesk.example.com` and try again |
