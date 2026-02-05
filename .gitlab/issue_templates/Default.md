## 🐛 Issue Report Template

Thank you for reporting an issue!
Please provide the details below to help us investigate and resolve it efficiently.
If you have a feature request, please select the "Feature Request" template.

### 📦 Deployment Details
- **Release version deployed**:
  _(e.g. v1.4.2, commit hash, or branch name)_

- **Deployment type**:
  - [ ] Fresh installation
  - [ ] Upgrade (from version: ___ )

### ☸️ Kubernetes Environment
- **Kubernetes distribution** (select one):
  - [ ] Rancher RKE / RKE2
  - [ ] OpenShift
  - [ ] k3s
  - [ ] kind / minikube
  - [ ] Other: ___________

- **Kubernetes version**:
  _(e.g. v1.27.3)_

### 🌐 Ingress & Certificates
- **Ingress controller in use**:
  - [ ] Ingress NGINX Controller version: ___
  - [ ] Other: Currently only Ingress NGINX is supported

- **Certificate status**:
  - [ ] Let’s Encrypt
  - [ ] Other publicly verifiable certificate (issuer: ___ )
  - [ ] Self-signed certificate (see [`self-signed-certificated.md`](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/develop/docs/enhanced-configuration/self-signed-certificates.md))
    - [ ] Option 1
    - [ ] Option 2a
    - [ ] Option 2b

### 📅 Data persistence

Are you using your own services for data persistence (required for production) or the openDesk bundled ones (development, test and evaluation only)?

- [ ] Separate services configured via `databases.*` and `objectstore.*`
- [ ] openDesk bundled "external services"

### 🔧 Tooling Versions
- **Helm version (`helm version`)**: ___________
- **Helmfile version (`helmfile --version`)**: ___________

### 🔍 Problem Description
- **Expected behavior**:

- **Observed behavior / error message**:

- **Steps to reproduce**:
  1.
  2.
  3.

### 📄 Additional context

- Relevant logs (please redact sensitive info):
- Screenshots (if applicable):
- Other notes that might help:

## 🙌 Thank you for contributing to the project!
