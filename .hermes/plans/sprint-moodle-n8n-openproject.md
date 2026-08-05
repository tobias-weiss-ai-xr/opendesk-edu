# Sprint: Deploy MOODLE, n8n, OpenProject

**Goal:** Deploy three new edu services in opendesk-edu

## Tasks

1. **MOODLE**
   - Build Docker image (`weissto/moodle-shib:4.4.0`) from existing Dockerfile
   - Push to Docker Hub
   - Configure values (image ref, DB creds, ingress host)
   - Deploy via `helm install`
   - Fix any issues (DB init, probes, network policy)
   - Verify ingress + portal entry

2. **n8n**
   - No existing chart or app config
   - Use upstream Helm chart (community/bitnami) or write minimal chart
   - Configure values: ingress host `n8n.opendesk.hrz.uni-marburg.de`, DB (SQLite or shared PG), storage
   - Deploy via `helm install`
   - Verify ingress

3. **OpenProject**
   - Uses upstream Bitnami chart (no local chart dir)
   - Needs PostgreSQL and Redis
   - Configure values: ingress host `projects.opendesk.hrz.uni-marburg.de`, resource sizing
   - Deploy via `helm install`
   - Verify ingress + portal entry
