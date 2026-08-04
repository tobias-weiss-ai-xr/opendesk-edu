# Collab Services — Interactive Computing for openDesk Edu

> **Design Doc** — 2026-05-27
> **Status:** Approved
> **Project:** openDesk Edu extension: collab-services

## 1. Overview

openDesk Edu is a Kubernetes-based open-source digital workplace platform for education. It currently provides productivity tools (Nextcloud, Element, Jitsi, XWiki, OpenProject), educational tools (ILIAS, Moodle, BBB, Etherpad), and content tools (BookStack, Planka, Zammad). However, it lacks the **interactive computing / data science** capabilities that platforms like CoCalc offer.

**Collab Services** fills this gap by adding ~15 computational tools (JupyterHub, Overleaf, Open WebUI, RStudio, code-server, Dask, etc.) as a new helmfile app group inside openDesk Edu. It also provides a **React dashboard** — a feature catalog page akin to cocalc.com/features — that maps each CoCalc feature to its open-source K8s alternative.

### Goals

1. Add interactive computing tools (notebooks, LaTeX, AI, R, Julia, terminals, X11 desktops) to openDesk Edu
2. Match ~90% of CoCalc's feature surface with open-source tools
3. Follow openDesk Edu conventions: helmfile, upstream charts, Keycloak SSO, unified ingress
4. Provide a visual dashboard (React SPA) at `collab.opendesk.example.com`

### Non-Goals

- Not replacing existing openDesk Edu apps (Nextcloud, Element, Jitsi, XWiki, etc.)
- Not forking openDesk Edu — a pure additive extension
- Not creating new operators or CRDs (per openDesk conventions)
- Not handling production-scale AI training — Ollama for interactive use only

## 2. Architecture

### Repository Structure

All changes live **inside** the existing `opendesk-edu` repository at `~/git/opendesk_git/opendesk-edu/`:

```
opendesk-edu/
├── helmfile/apps/
│   ├── jupyterhub/              # 🆕
│   ├── overleaf/                # 🆕
│   ├── open-webui/              # 🆕
│   ├── ollama/                  # 🆕
│   ├── rstudio/                 # 🆕
│   ├── code-server/             # 🆕
│   ├── ttyd/                    # 🆕
│   ├── kasmvnc/                 # 🆕
│   ├── dask/                    # 🆕
│   ├── slidev/                  # 🆕
│   ├── collab-dashboard/        # 🆕
│   ├── ... (existing apps unchanged)
├── helmfile/charts/
│   ├── rstudio/                 # 🆕 custom chart
│   ├── ttyd/                    # 🆕 custom chart
│   ├── slidev/                  # 🆕 custom chart
│   ├── collab-dashboard/        # 🆕 custom chart (React SPA)
│   ├── ... (existing charts unchanged)
├── helmfile_generic.yaml.gotmpl # 🖊️ Add new app paths
├── helmfile/environments/default/
│   ├── a0-global.yaml.gotmpl    # 🖊️ Add app flags & config
│   ├── ... (existing configs unchanged)
└── collab-dashboard/            # 🆕 React app source (outside helmfile tree)
    ├── src/
    ├── package.json
    ├── vite.config.ts
    └── Dockerfile
```

### Integration Points

| Integration | Mechanism |
|---|---|
| **SSO** | JupyterHub → OAuthenticator (Keycloak OIDC); Open WebUI → generic OAuth; others → oauth2-proxy reverse proxy sidecar |
| **Portal** | Nubus portal tiles (existing openDesk Edu mechanism) pointing to each service + the dashboard |
| **Ingress** | HAProxy ingress controller; `*.opendesk.example.com` subdomains per service |
| **Backup** | k8up (existing) for user persistent volumes |
| **Storage** | RWO / RWX storage classes from openDesk Edu config |
| **Monitoring** | Existing Prometheus stack; no new exporters |

### Deployment Order

| Stage (commonLabels) | Releases |
|---|---|
| `010-infra` | ollama (LLM backend dependency) |
| `050-components` | jupyterhub, overleaf, open-webui, rstudio, code-server, ttyd, kasmvnc, dask, slidev |
| `060-frontend` | collab-dashboard |

## 3. CoCalc Feature Map

| CoCalc Feature | Open-Source Tool | Strategy | Upstream Chart? |
|---|---|---|---|
| Jupyter Notebooks | **JupyterHub** + nbgrader | Standalone Helm chart | ✅ `jupyterhub/jupyterhub` |
| Collaborative LaTeX | **Overleaf CE** (ShareLaTeX) | Standalone Helm chart | ✅ Community |
| AI Assistant | **Open WebUI** + **Ollama** | 2 charts, linked via internal service | ✅ Community |
| Whiteboard | Excalidraw (already in opendesk-edu) | Already deployed | — |
| Slides | **Slidev** (markdown → slides) | Custom chart | ❌ Custom |
| R Statistics | **RStudio Server** | Custom chart | ❌ Custom |
| SageMath | **SageMath** container | JupyterHub profile (singleuser image) | Bundled in JH |
| GNU Octave | **Octave** (Jupyter kernel) | JupyterHub profile | Bundled in JH |
| Python | **code-server** (VS Code in browser) | Standalone Helm chart | ✅ `coder/code-server` |
| Julia | **Pluto.jl** | JupyterHub profile | Bundled in JH |
| Linux Terminal | **ttyd** | Custom chart | ❌ Custom |
| Linux Environment | K8s exec/cronjobs | Platform feature | — |
| Teaching | **nbgrader** + ILIAS/Moodle | JH extension + existing | Existing |
| X11 Desktop | **KasmVNC** | Standalone Helm chart | ✅ Community |
| Compute Servers | **Dask** + **Ray** | Standalone Helm charts | ✅ `dask/dask-gateway` |
| API Interface | JupyterHub REST API + K8s API | Platform feature | — |

## 4. React Dashboard (`collab-dashboard`)

### Purpose

A landing page at `collab.opendesk.example.com` that recreates the look and feel of cocalc.com/features — a clean card grid showing each CoCalc feature mapped to its open-source K8s alternative.

### Tech Stack

- **React 18** + TypeScript
- **Vite** for build
- **Tailwind CSS** for styling
- **React Router** for page navigation
- **Nginx** for serving the SPA (Docker image)

### Routes

| Route | Content |
|---|---|
| `/` | Card grid dashboard (all tools) |
| `/:toolId` | Feature detail page per tool |
| `/about` | About collab-services |

### Data Model

```typescript
interface CollabTool {
  id: string;
  name: string;
  logo: string;               // URL or SVG path
  coCalcFeature: string;       // "↔ Jupyter Notebooks"
  description: string;
  category: 'computing' | 'editing' | 'ai' | 'visualization' | 'teaching' | 'infrastructure';
  status: 'stable' | 'beta' | 'planned';
  helmChart: string;
  docsUrl: string;
  launchUrl?: string;          // URL if deployed
  upstreamUrl: string;         // GitHub/GitLab of upstream project
  screenshots?: string[];
}
```

### Card Layout

Clean card grid (responsive: 1-col mobile → 4-col desktop), each card showing:
- Tool logo/icon (SVG)
- Tool name
- CoCalc feature badge
- Status badge
- Short description
- Launch / Learn More buttons

### Build & Deploy

1. Source code in `opendesk-edu/collab-dashboard/` (outside helmfile tree, build-time only)
2. Docker image built with `nginx:alpine` serving the SPA
3. Helm chart in `helmfile/charts/collab-dashboard/` references the image

## 5. Custom Helm Charts

### 5.1 `rstudio`

Minimal chart wrapping the `rocker/rstudio` container image. No upstream Helm chart exists for RStudio Server.

**Key features:**
- Deployment + Service + Ingress
- Persistent volume for user workspace (`/home/rstudio`)
- OIDC via oauth2-proxy sidecar
- Environment config for Shiny Server

### 5.2 `ttyd`

Minimal chart wrapping `tsl0922/ttyd` (web terminal).

**Key features:**
- Deployment + Service + Ingress
- OIDC via oauth2-proxy sidecar
- Configurable shell (bash, zsh)
- Session timeout config

### 5.3 `slidev`

Minimal chart wrapping Slidev in production mode.

**Key features:**
- Deployment + Service + Ingress
- Persistent volume for slide markdown files
- Build-on-startup init container

### 5.4 `collab-dashboard`

Chart for serving the React SPA.

**Key features:**
- Nginx serving static files
- Environment variable injection for runtime config (API endpoints)
- Ingress with host `collab.opendesk.example.com`

## 6. Configuration

### App Enable/Disable Flags

Added to `helmfile/environments/default/a0-global.yaml.gotmpl`:

```yaml
apps:
  jupyterhub:
    enabled: true
  overleaf:
    enabled: true
  openWebui:
    enabled: true
  ollama:
    enabled: true
  rstudio:
    enabled: true
  codeServer:
    enabled: true
  ttyd:
    enabled: true
  kasmvnc:
    enabled: true
  dask:
    enabled: true
  slidev:
    enabled: true
  collabDashboard:
    enabled: true
```

### Repository References

```yaml
repositories:
  jupyterhub:
    url: "https://hub.jupyter.org/helm-chart/"
    name: jupyterhub
  dask:
    url: "https://helm.dask.org/"
    name: dask
  codeServer:
    url: "https://helm.coder.com/coder-v2/"
    name: coder
```

## 7. Implementation Order

The work breaks into 3 phases:

**Phase A — Foundation (helmfile plumbing + React dashboard)**
1. Create collab-dashboard React app + Helm chart
2. Add helmfile child entries to helmfile_generic.yaml.gotmpl
3. Add environment config (flags, repos, annotations)
4. Deploy and verify dashboard works standalone

**Phase B — Core Tools (JupyterHub + Overleaf + Open WebUI)**
5. JupyterHub app (chart ref + values + profiles for Sage/Octave/Julia)
6. Overleaf app (chart ref + values)
7. Open WebUI + Ollama apps (chart refs + values + integration)
8. code-server app (chart ref + values)

**Phase C — Remaining Tools + Polish**
9. RStudio custom chart + app
10. ttyd custom chart + app
11. KasmVNC app (upstream chart ref + values)
12. Dask app (upstream chart ref + values)
13. Slidev custom chart + app
14. Portal tiles for all new apps
15. Feature detail pages in React dashboard

## 8. Appendix: Upstream Chart Sources

| App | Chart | Source |
|---|---|---|
| JupyterHub | `jupyterhub/jupyterhub` | https://hub.jupyter.org/helm-chart/ |
| Overleaf | Community chart | https://github.com/overleaf/overleaf (or oci registry) |
| Open WebUI | `open-webui/open-webui` | https://helm.openwebui.com/ |
| Ollama | `ollama/ollama` | https://ollama.github.io/helm-chart/ |
| code-server | `coder/coder-v2/coder` | https://helm.coder.com/coder-v2/ |
| KasmVNC | Community chart | https://kasmweb.com/ or custom |
| Dask | `dask/dask-gateway` | https://helm.dask.org/ |
