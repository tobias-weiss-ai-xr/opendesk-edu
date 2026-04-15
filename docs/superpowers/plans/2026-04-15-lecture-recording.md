# Lecture Recording Implementation Plan (v1.2)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate SNIpR as the lecture recording platform for openDesk Edu, backed by SeaweedFS for cluster-internal S3 object storage. This creates a new SeaweedFS Helm chart (13 files), updates SNIpR storage values to point at SeaweedFS (2 files), adds a Keycloak OIDC client with portal tile (2 files), and marks the ROADMAP (1 file).

**Architecture:** ILIAS/Moodle launch SNIpR via LTI 1.3. SNIpR stores recordings in SeaweedFS (master + volume + S3 gateway), all cluster-internal with no ingress. F13 handles transcription via REST callback. Keycloak provides OIDC SSO. A portal tile in the "Anwendungen" category gives users access.

**Tech Stack:** Helmfile, Kubernetes YAML, Helm Go templating, S3-compatible storage (SeaweedFS), OIDC (Keycloak)

**Note:** This is a Helm/Kubernetes YAML configuration project. No unit tests, no build command, no typechecker. Verification is reading the rendered YAML and checking gotemplate syntax.

---

## File Structure

| # | File | Action | Responsibility |
|---|------|--------|----------------|
| 1 | `helmfile/charts/seaweedfs/Chart.yaml` | Create | Chart metadata (apiVersion v2, name, version) |
| 2 | `helmfile/charts/seaweedfs/values.yaml` | Create | Default values for master, volume, s3, auth, backup |
| 3 | `helmfile/charts/seaweedfs/templates/_helpers.tpl` | Create | Standard Helm helpers (fullname, labels, selector) |
| 4 | `helmfile/charts/seaweedfs/templates/master-deployment.yaml` | Create | Master Deployment (1 replica, ports 9333/9324, PVC for metadata) |
| 5 | `helmfile/charts/seaweedfs/templates/master-service.yaml` | Create | Master Service (ports 9333, 9324) |
| 6 | `helmfile/charts/seaweedfs/templates/volume-statefulset.yaml` | Create | Volume StatefulSet (1+ replicas, PVC for data, port 8080) |
| 7 | `helmfile/charts/seaweedfs/templates/volume-service.yaml` | Create | Volume Service (port 8080) |
| 8 | `helmfile/charts/seaweedfs/templates/s3-deployment.yaml` | Create | S3 gateway Deployment (1 replica, port 8333, connects to master) |
| 9 | `helmfile/charts/seaweedfs/templates/s3-service.yaml` | Create | S3 gateway Service (port 8333) |
| 10 | `helmfile/charts/seaweedfs/templates/configmap.yaml` | Create | SeaweedFS config (filer config, s3 config) |
| 11 | `helmfile/charts/seaweedfs/templates/secret.yaml` | Create | S3 credentials (accessKey, secretKey, adminPassword) |
| 12 | `helmfile/charts/seaweedfs/templates/prebackuppod.yaml` | Create | k8up PreBackupPod for daily recording backup |
| 13 | `helmfile/apps/seaweedfs/values.yaml.gotmpl` | Create | App-level values with Go templating for domain, secrets, storage class |
| 14 | `helmfile/charts/snipr/values.yaml` | Modify | Lines 42-49: change storage.s3 to SeaweedFS endpoint |
| 15 | `helmfile/apps/snipr/values.yaml.gotmpl` | Modify | Lines 21-24: change storage to SeaweedFS references |
| 16 | `helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotmpl` | Modify | Add snipr OIDC client, clientScope, clientAccessRestrictions entry, precreateGroups entry |
| 17 | `helmfile/apps/nubus/values-nubus.yaml.gotmpl` | Modify | Add `07-custom-snipr-portal-entry.yaml` extraDataFile after OpenCloud entry |
| 18 | `ROADMAP.md` | Modify | Mark v1.2 lecture recording checkboxes as complete |

Files 1-13 are the SeaweedFS chart (new). Files 14-15 update SNIpR storage values. Files 16-17 add Keycloak client and portal tile. File 18 updates the roadmap.

### Dependencies

```
Task 1 (Chart skeleton) ───────────┐
Task 2 (Master + Volume) ──────────┤
Task 3 (S3 + Config) ──────────────┼── No interdependencies, can run in any order
Task 4 (k8up backup) ──────────────┤
Task 5 (App values) ───────────────┘
Task 6 (SNIpR storage) ──────────── Independent of Tasks 1-5 (modifies different chart)
Task 7 (Keycloak client) ────────── Independent
Task 8 (Portal tile) ────────────── Independent
Task 9 (ROADMAP) ────────────────── Independent
Task 10 (Verify) ────────────────── Depends on all above
```

---

### Task 1: SeaweedFS Chart Skeleton

**Files:**
- Create: `helmfile/charts/seaweedfs/Chart.yaml`
- Create: `helmfile/charts/seaweedfs/values.yaml`
- Create: `helmfile/charts/seaweedfs/templates/_helpers.tpl`

Follows the pattern from `helmfile/charts/snipr/Chart.yaml` (apiVersion v2, annotations, no dependencies).

- [x] **Step 1: Create directory structure**

```bash
mkdir -p helmfile/charts/seaweedfs/templates
```

- [x] **Step 2: Create `helmfile/charts/seaweedfs/Chart.yaml`**

```yaml
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
apiVersion: v2
name: seaweedfs
description: A Helm chart for SeaweedFS S3-compatible object storage
type: application
version: 1.0.0
appVersion: "3.78"
annotations:
  artifacthub.io/changes: |
    - Initial SeaweedFS Helm chart for v1.2 Lecture Recording
  artifacthub.io/links: |
    - name: Source
      url: https://github.com/tobias-weiss-ai-xr/opendesk-edu
  artifacthub.io/recommendations: |
    - url: https://github.com/tobias-weiss-ai-xr/opendesk-edu/tree/main/helmfile/charts/snipr
      name: SNIpR Lecture Recording
dependencies: []
```

- [x] **Step 3: Create `helmfile/charts/seaweedfs/values.yaml`**

```yaml
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0

master:
  replicaCount: 1
  image: chrislusf/seaweedfs
  tag: "3.78"
  resources:
    requests:
      cpu: "250m"
      memory: "512Mi"
    limits:
      cpu: "500m"
      memory: "1Gi"
  persistence:
    enabled: true
    size: 10Gi
    accessMode: ReadWriteOnce
    storageClass: local-path

volume:
  replicaCount: 1
  image: chrislusf/seaweedfs
  tag: "3.78"
  resources:
    requests:
      cpu: "500m"
      memory: "1Gi"
    limits:
      cpu: "1000m"
      memory: "2Gi"
  persistence:
    enabled: true
    size: 500Gi
    accessMode: ReadWriteMany
    storageClass: ceph-cephfs-hdd-ec
  maxVolumes: 32

s3:
  replicaCount: 1
  image: chrislusf/seaweedfs
  tag: "3.78"
  resources:
    requests:
      cpu: "250m"
      memory: "256Mi"
    limits:
      cpu: "500m"
      memory: "512Mi"
  config:
    bucket: snipr-recordings

ingress:
  enabled: false

auth:
  enabled: true
  adminUser: admin
  adminPassword: ""  # Set via secrets
  accessKey: ""      # Set via secrets
  secretKey: ""      # Set via secrets

backup:
  enabled: true
  k8up:
    schedule: "0 2 * * *"
    retention:
      daily: 7
      weekly: 4
      monthly: 3
```

- [x] **Step 4: Create `helmfile/charts/seaweedfs/templates/_helpers.tpl`**

```gotemplate
{{/*
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
Expand the name of the chart.
*/}}
{{- define "seaweedfs.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
Create a default fully qualified app name.
*/}}
{{- define "seaweedfs.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
Create chart name and version as used by the chart label.
*/}}
{{- define "seaweedfs.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
Common labels
*/}}
{{- define "seaweedfs.labels" -}}
helm.sh/chart: {{ include "seaweedfs.chart" . }}
{{ include "seaweedfs.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
Selector labels
*/}}
{{- define "seaweedfs.selectorLabels" -}}
app.kubernetes.io/name: {{ include "seaweedfs.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
Master service name
*/}}
{{- define "seaweedfs.masterFullname" -}}
{{- printf "%s-master" (include "seaweedfs.fullname" .) }}
{{- end }}

{{/*
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
Volume service name
*/}}
{{- define "seaweedfs.volumeFullname" -}}
{{- printf "%s-volume" (include "seaweedfs.fullname" .) }}
{{- end }}

{{/*
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
S3 gateway service name
*/}}
{{- define "seaweedfs.s3Fullname" -}}
{{- printf "%s-s3" (include "seaweedfs.fullname" .) }}
{{- end }}
```

- [x] **Step 5: Commit**

```bash
git add helmfile/charts/seaweedfs/
git commit -m "feat(seaweedfs): add chart skeleton with Chart.yaml, values.yaml, helpers

Create the SeaweedFS Helm chart with default values for master,
volume, and s3 gateway components. Includes standard Helm helper
templates for fullname, labels, and selector patterns."
```

---

### Task 2: SeaweedFS Master and Volume

**Files:**
- Create: `helmfile/charts/seaweedfs/templates/master-deployment.yaml`
- Create: `helmfile/charts/seaweedfs/templates/master-service.yaml`
- Create: `helmfile/charts/seaweedfs/templates/volume-statefulset.yaml`
- Create: `helmfile/charts/seaweedfs/templates/volume-service.yaml`

Master runs as a Deployment (1 replica, ports 9333 gRPC + 9324 HTTP). Volume runs as a StatefulSet with PVC for data storage.

- [x] **Step 1: Create `helmfile/charts/seaweedfs/templates/master-deployment.yaml`**

```yaml
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "seaweedfs.masterFullname" . }}
  labels:
    {{- include "seaweedfs.labels" . | nindent 4 }}
    app.kubernetes.io/component: master
spec:
  replicas: {{ .Values.master.replicaCount }}
  selector:
    matchLabels:
      {{- include "seaweedfs.selectorLabels" . | nindent 6 }}
      app.kubernetes.io/component: master
  template:
    metadata:
      labels:
        {{- include "seaweedfs.selectorLabels" . | nindent 8 }}
        app.kubernetes.io/component: master
    spec:
      containers:
        - name: master
          image: "{{ .Values.master.image }}:{{ .Values.master.tag }}"
          imagePullPolicy: IfNotPresent
          command:
            - "weed"
            - "master"
            - "-port=9333"
            - "-port.grpc=9324"
            - "-mdir=/data"
            - "-defaultReplication=000"
            - "-volumeSizeLimitMB=30000"
          ports:
            - name: grpc
              containerPort: 9333
              protocol: TCP
            - name: http
              containerPort: 9324
              protocol: TCP
          {{- if .Values.master.persistence.enabled }}
          volumeMounts:
            - name: data
              mountPath: /data
          {{- end }}
          resources:
            {{- toYaml .Values.master.resources | nindent 12 }}
          livenessProbe:
            httpGet:
              path: /cluster/status
              port: http
            initialDelaySeconds: 15
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /cluster/status
              port: http
            initialDelaySeconds: 10
            periodSeconds: 5
      {{- if .Values.master.persistence.enabled }}
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: {{ include "seaweedfs.masterFullname" . }}
      {{- end }}
```

- [x] **Step 2: Create `helmfile/charts/seaweedfs/templates/master-service.yaml`**

```yaml
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
apiVersion: v1
kind: Service
metadata:
  name: {{ include "seaweedfs.masterFullname" . }}
  labels:
    {{- include "seaweedfs.labels" . | nindent 4 }}
    app.kubernetes.io/component: master
spec:
  type: ClusterIP
  ports:
    - name: grpc
      port: 9333
      targetPort: grpc
      protocol: TCP
    - name: http
      port: 9324
      targetPort: http
      protocol: TCP
  selector:
    {{- include "seaweedfs.selectorLabels" . | nindent 4 }}
    app.kubernetes.io/component: master
```

- [x] **Step 3: Create `helmfile/charts/seaweedfs/templates/volume-statefulset.yaml`**

```yaml
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ include "seaweedfs.volumeFullname" . }}
  labels:
    {{- include "seaweedfs.labels" . | nindent 4 }}
    app.kubernetes.io/component: volume
spec:
  serviceName: {{ include "seaweedfs.volumeFullname" . }}
  replicas: {{ .Values.volume.replicaCount }}
  selector:
    matchLabels:
      {{- include "seaweedfs.selectorLabels" . | nindent 6 }}
      app.kubernetes.io/component: volume
  template:
    metadata:
      labels:
        {{- include "seaweedfs.selectorLabels" . | nindent 8 }}
        app.kubernetes.io/component: volume
    spec:
      containers:
        - name: volume
          image: "{{ .Values.volume.image }}:{{ .Values.volume.tag }}"
          imagePullPolicy: IfNotPresent
          command:
            - "weed"
            - "volume"
            - "-port=8080"
            - "-mserver={{ include "seaweedfs.masterFullname" . }}:9333"
            - "-dir=/data"
            - "-max={{ .Values.volume.maxVolumes }}"
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP
          volumeMounts:
            - name: data
              mountPath: /data
          resources:
            {{- toYaml .Values.volume.resources | nindent 12 }}
          livenessProbe:
            httpGet:
              path: /status
              port: http
            initialDelaySeconds: 15
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /status
              port: http
            initialDelaySeconds: 10
            periodSeconds: 5
  volumeClaimTemplates:
    - metadata:
        name: data
        labels:
          {{- include "seaweedfs.selectorLabels" . | nindent 10 }}
          app.kubernetes.io/component: volume
      spec:
        accessModes:
          - {{ .Values.volume.persistence.accessMode }}
        {{- if .Values.volume.persistence.storageClass }}
        storageClassName: {{ .Values.volume.persistence.storageClass }}
        {{- end }}
        resources:
          requests:
            storage: {{ .Values.volume.persistence.size }}
```

- [x] **Step 4: Create `helmfile/charts/seaweedfs/templates/volume-service.yaml`**

```yaml
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
apiVersion: v1
kind: Service
metadata:
  name: {{ include "seaweedfs.volumeFullname" . }}
  labels:
    {{- include "seaweedfs.labels" . | nindent 4 }}
    app.kubernetes.io/component: volume
spec:
  type: ClusterIP
  ports:
    - name: http
      port: 8080
      targetPort: http
      protocol: TCP
  selector:
    {{- include "seaweedfs.selectorLabels" . | nindent 4 }}
    app.kubernetes.io/component: volume
```

- [x] **Step 5: Commit**

```bash
git add helmfile/charts/seaweedfs/templates/master-deployment.yaml \
        helmfile/charts/seaweedfs/templates/master-service.yaml \
        helmfile/charts/seaweedfs/templates/volume-statefulset.yaml \
        helmfile/charts/seaweedfs/templates/volume-service.yaml
git commit -m "feat(seaweedfs): add master Deployment and volume StatefulSet

Master runs as a Deployment with gRPC (9333) and HTTP (9324) ports,
PVC-backed metadata storage. Volume runs as a StatefulSet with
PVC for recording data, connecting to master for volume assignment."
```

---

### Task 3: SeaweedFS S3 Gateway and Configuration

**Files:**
- Create: `helmfile/charts/seaweedfs/templates/s3-deployment.yaml`
- Create: `helmfile/charts/seaweedfs/templates/s3-service.yaml`
- Create: `helmfile/charts/seaweedfs/templates/configmap.yaml`
- Create: `helmfile/charts/seaweedfs/templates/secret.yaml`

The S3 gateway exposes an S3-compatible API on port 8333. It connects to the master at `seaweedfs-master:9333`. The ConfigMap holds filer/s3 configuration. The Secret holds S3 credentials.

- [x] **Step 1: Create `helmfile/charts/seaweedfs/templates/s3-deployment.yaml`**

```yaml
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "seaweedfs.s3Fullname" . }}
  labels:
    {{- include "seaweedfs.labels" . | nindent 4 }}
    app.kubernetes.io/component: s3
spec:
  replicas: {{ .Values.s3.replicaCount }}
  selector:
    matchLabels:
      {{- include "seaweedfs.selectorLabels" . | nindent 6 }}
      app.kubernetes.io/component: s3
  template:
    metadata:
      labels:
        {{- include "seaweedfs.selectorLabels" . | nindent 8 }}
        app.kubernetes.io/component: s3
    spec:
      containers:
        - name: s3
          image: "{{ .Values.s3.image }}:{{ .Values.s3.tag }}"
          imagePullPolicy: IfNotPresent
          command:
            - "weed"
            - "s3"
            - "-port=8333"
            - "-filer={{ include "seaweedfs.masterFullname" . }}:9333"
            - "-s3.config=/etc/seaweedfs/s3.json"
          ports:
            - name: http
              containerPort: 8333
              protocol: TCP
          volumeMounts:
            - name: config
              mountPath: /etc/seaweedfs
          env:
            - name: WEED_S3_ACCESS_KEY
              valueFrom:
                secretKeyRef:
                  name: {{ include "seaweedfs.fullname" . }}
                  key: accessKey
            - name: WEED_S3_SECRET_KEY
              valueFrom:
                secretKeyRef:
                  name: {{ include "seaweedfs.fullname" . }}
                  key: secretKey
          resources:
            {{- toYaml .Values.s3.resources | nindent 12 }}
          livenessProbe:
            httpGet:
              path: /
              port: http
            initialDelaySeconds: 15
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /
              port: http
            initialDelaySeconds: 10
            periodSeconds: 5
      volumes:
        - name: config
          configMap:
            name: {{ include "seaweedfs.fullname" . }}
```

- [x] **Step 2: Create `helmfile/charts/seaweedfs/templates/s3-service.yaml`**

```yaml
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
apiVersion: v1
kind: Service
metadata:
  name: {{ include "seaweedfs.s3Fullname" . }}
  labels:
    {{- include "seaweedfs.labels" . | nindent 4 }}
    app.kubernetes.io/component: s3
spec:
  type: ClusterIP
  ports:
    - name: http
      port: 8333
      targetPort: http
      protocol: TCP
  selector:
    {{- include "seaweedfs.selectorLabels" . | nindent 4 }}
    app.kubernetes.io/component: s3
```

- [x] **Step 3: Create `helmfile/charts/seaweedfs/templates/configmap.yaml`**

```yaml
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "seaweedfs.fullname" . }}
  labels:
    {{- include "seaweedfs.labels" . | nindent 4 }}
data:
  s3.json: |
    {
      "identities": [
        {
          "name": "admin",
          "credentials": [
            {
              "access": "{{ .Values.auth.accessKey }}",
              "secret": "{{ .Values.auth.secretKey }}"
            }
          ],
          "actions": [
            "admin",
            "read",
            "write",
            "list",
            "tagging"
          ]
        }
      ]
    }
```

- [x] **Step 4: Create `helmfile/charts/seaweedfs/templates/secret.yaml`**

```yaml
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "seaweedfs.fullname" . }}
  labels:
    {{- include "seaweedfs.labels" . | nindent 4 }}
type: Opaque
stringData:
  accessKey: {{ .Values.auth.accessKey | default "" | quote }}
  secretKey: {{ .Values.auth.secretKey | default "" | quote }}
  adminPassword: {{ .Values.auth.adminPassword | default "" | quote }}
```

- [x] **Step 5: Commit**

```bash
git add helmfile/charts/seaweedfs/templates/s3-deployment.yaml \
        helmfile/charts/seaweedfs/templates/s3-service.yaml \
        helmfile/charts/seaweedfs/templates/configmap.yaml \
        helmfile/charts/seaweedfs/templates/secret.yaml
git commit -m "feat(seaweedfs): add S3 gateway, ConfigMap, and Secret

S3 gateway Deployment exposes port 8333, connects to master for
volume assignment. ConfigMap holds the S3 identity configuration.
Secret stores accessKey, secretKey, and adminPassword."
```

---

### Task 4: SeaweedFS k8up Backup

**Files:**
- Create: `helmfile/charts/seaweedfs/templates/prebackuppod.yaml`

Daily backup schedule, retention daily:7 weekly:4 monthly:3. Uses the SeaweedFS image to run `weed backup`.

- [x] **Step 1: Create `helmfile/charts/seaweedfs/templates/prebackuppod.yaml`**

```yaml
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
{{- if .Values.backup.enabled }}
apiVersion: k8up.io/v1
kind: PreBackupPod
metadata:
  name: {{ include "seaweedfs.fullname" . }}-backup
  labels:
    {{- include "seaweedfs.labels" . | nindent 4 }}
spec:
  backupCommand: /bin/sh -c "weed backup -master={{ include "seaweedfs.masterFullname" . }}:9333 -backupDir=/backup"
  podCommand: /bin/sh -c "while true; do sleep 3600; done"
  podImage: "{{ .Values.volume.image }}:{{ .Values.volume.tag }}"
  podWorkDir: "/backup"
  resources:
    requests:
      cpu: "250m"
      memory: "512Mi"
    limits:
      cpu: "500m"
      memory: "1Gi"
{{- end }}
```

- [x] **Step 2: Commit**

```bash
git add helmfile/charts/seaweedfs/templates/prebackuppod.yaml
git commit -m "feat(seaweedfs): add k8up PreBackupPod for daily recording backup

Creates a PreBackupPod that runs weed backup to snapshot SeaweedFS
volume data. Gated on .Values.backup.enabled."
```

---

### Task 5: SeaweedFS App Values

**Files:**
- Create: `helmfile/apps/seaweedfs/values.yaml.gotmpl`

App-level values with Go templating for storageClass, PVC size, domain, and secrets. Follows the pattern from `helmfile/apps/snipr/values.yaml.gotmpl`.

- [x] **Step 1: Create directory**

```bash
mkdir -p helmfile/apps/seaweedfs
```

- [x] **Step 2: Create `helmfile/apps/seaweedfs/values.yaml.gotmpl`**

```yaml
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
---
master:
  persistence:
    storageClass: {{ .Values.storageclasses.cephfs | default "ceph-cephfs-hdd-ec" | quote }}

volume:
  replicaCount: {{ .Values.apps.seaweedfs.volumeReplicas | default 1 }}
  persistence:
    size: {{ .Values.apps.seaweedfs.volumeSize | default "500Gi" | quote }}
    storageClass: {{ .Values.storageclasses.cephfs | default "ceph-cephfs-hdd-ec" | quote }}

auth:
  adminPassword: {{ .Values.secrets.seaweedfs.adminPassword | quote }}
  accessKey: {{ .Values.secrets.seaweedfs.accessKey | quote }}
  secretKey: {{ .Values.secrets.seaweedfs.secretKey | quote }}

s3:
  config:
    bucket: {{ .Values.apps.seaweedfs.bucket | default "snipr-recordings" | quote }}

backup:
  enabled: {{ .Values.backup.seaweedfs.enabled | default true }}
  k8up:
    schedule: {{ .Values.backup.seaweedfs.schedule | default "0 2 * * *" | quote }}
    retention:
      daily: {{ .Values.backup.seaweedfs.retention.daily | default 7 }}
      weekly: {{ .Values.backup.seaweedfs.retention.weekly | default 4 }}
      monthly: {{ .Values.backup.seaweedfs.retention.monthly | default 3 }}
```

- [ ] **Step 3: Commit**

```bash
git add helmfile/apps/seaweedfs/values.yaml.gotmpl
git commit -m "feat(seaweedfs): add app-level values with Go templating

Override chart defaults with gotemplate references to global config
for storageClass, PVC sizes, secrets, and backup retention."
```

---

### Task 6: SNIpR Storage Update

**Files:**
- Modify: `helmfile/charts/snipr/values.yaml` (lines 42-49)
- Modify: `helmfile/apps/snipr/values.yaml.gotmpl` (lines 21-24)

Change SNIpR's S3 storage configuration from MinIO defaults to SeaweedFS cluster-internal endpoint. Key changes: `endpoint` from `https://minio.opendesk.example.com` to `http://seaweedfs-s3:8333`, `ssl: false`, `forcePathStyle: true`, empty `region`.

- [ ] **Step 1: Update `helmfile/charts/snipr/values.yaml`**

Open `helmfile/charts/snipr/values.yaml`. Replace the `storage.s3` section at lines 42-49.

Change the existing content at lines 42-49:
```yaml
  # Storage configuration (S3/MinIO primary, filesystem fallback)
  storage:
    type: s3  # or "filesystem"
    s3:
      endpoint: https://minio.opendesk.example.com
      bucket: snipr-recordings
      region: eu-central-1
      ssl: true
      forcePathStyle: false
```

To:
```yaml
  # Storage configuration (SeaweedFS S3, cluster-internal)
  storage:
    type: s3
    s3:
      endpoint: http://seaweedfs-s3:8333
      bucket: snipr-recordings
      region: ""
      ssl: false
      forcePathStyle: true
```

- [ ] **Step 2: Update `helmfile/apps/snipr/values.yaml.gotmpl`**

Open `helmfile/apps/snipr/values.yaml.gotmpl`. Replace the storage section at lines 20-24.

Change the existing content at lines 20-24:
```yaml
  # Storage configuration (MinIO S3)
  storage:
    enabled: {{ .Values.services.minio.enabled | default true }}
    endpoint: {{ .Values.services.minio.endpoint | default "https://minio.opendesk.example.com" | quote }}
    bucket: {{ .Values.services.minio.bucket | default "snipr-recordings" | quote }}
```

To:
```yaml
  # Storage configuration (SeaweedFS S3)
  storage:
    enabled: {{ .Values.apps.seaweedfs.enabled | default true }}
    endpoint: {{ .Values.services.seaweedfs.endpoint | default "http://seaweedfs-s3:8333" | quote }}
    bucket: {{ .Values.services.seaweedfs.bucket | default "snipr-recordings" | quote }}
```

- [ ] **Step 3: Commit**

```bash
git add helmfile/charts/snipr/values.yaml \
        helmfile/apps/snipr/values.yaml.gotmpl
git commit -m "feat(snipr): switch storage from MinIO to SeaweedFS S3

Update chart values to use cluster-internal SeaweedFS endpoint
(http://seaweedfs-s3:8333) with path-style addressing. App values
use gotemplate references to seaweedfs config."
```

---

### Task 7: Keycloak Client for SNIpR

**Files:**
- Modify: `helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotmpl`

Three additions in this file:

1. **Client scope** (after existing client scopes around line 222, in the `opendesk.clientScopes` section): Add `opendesk-snipr-scope` with user UUID and username mappers.

2. **OIDC client** (after the OpenCloud client at line 795, before the SAML clients): Add the `snipr` OIDC client with `frontchannelLogout: true`.

3. **Client access restriction** (after the OpenCloud entry at line 84, in the `clientAccessRestrictions` section): Add `snipr` access restriction.

4. **Precreate group** (in the `precreateGroups` list at line 137): Add the `managed-by-attribute-Lecturerecording` group.

- [ ] **Step 1: Add client scope for SNIpR**

Open `helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotmpl`.

Find the last client scope entry in the `opendesk.clientScopes` section (after the OpenCloud scope, around line 222). After the last `{{ end }}` in the clientScopes block, before the `clients:` key, insert:

```yaml
      {{ if .Values.apps.snipr.enabled }}
      - name: "opendesk-snipr-scope"
        description: "Scope for the claims required by openDesk's SNIpR lecture recording service."
        protocol: "openid-connect"
        protocolMappers:
          - name: "opendesk_useruuid"
            protocol: "openid-connect"
            protocolMapper: "oidc-usermodel-attribute-mapper"
            consentRequired: false
            config:
              userinfo.token.claim: true
              user.attribute: "entryUUID"
              id.token.claim: true
              access.token.claim: true
              claim.name: "opendesk_useruuid"
              jsonType.label: "String"
          - name: "opendesk_username"
            protocol: "openid-connect"
            protocolMapper: "oidc-usermodel-attribute-mapper"
            consentRequired: false
            config:
              userinfo.token.claim: true
              user.attribute: "uid"
              id.token.claim: true
              access.token.claim: true
              claim.name: "opendesk_username"
              jsonType.label: "String"
          - name: "email"
            protocol: "openid-connect"
            protocolMapper: "oidc-usermodel-attribute-mapper"
            consentRequired: false
            config:
              introspection.token.claim: true
              userinfo.token.claim: true
              user.attribute: "email"
              id.token.claim: true
              access.token.claim: true
              claim.name: "email"
              jsonType.label: "String"
      {{ end }}
```

- [ ] **Step 2: Add OIDC client for SNIpR**

After the OpenCloud client entry (which ends at line 795 with `{{ end }}`), before the ILIAS SAML client (line 796 `{{ if true }}  # ILIAS SAML client`), insert:

```yaml
      {{ if .Values.apps.snipr.enabled }}
      - name: "snipr"
        clientId: "snipr"
        protocol: "openid-connect"
        clientAuthenticatorType: "client-secret"
        secret: {{ .Values.secrets.keycloak.clientSecret.snipr | quote }}
        redirectUris:
          - "https://snipr.{{ .Values.global.domain }}/*"
        rootUrl: "https://snipr.{{ .Values.global.domain }}"
        consentRequired: false
        frontchannelLogout: true
        publicClient: false
        authorizationServicesEnabled: false
        attributes:
          post.logout.redirect.uris: "https://snipr.{{ .Values.global.domain }}/*"
        defaultClientScopes:
          - "opendesk-snipr-scope"
          - "openid"
          - "profile"
          - "email"
      {{ end }}
```

- [ ] **Step 3: Add client access restriction for SNIpR**

In the `clientAccessRestrictions` section (lines 23-84), after the OpenCloud entry (which ends at line 84 with `{{ end }}`), before the `custom:` key at line 85, insert:

```yaml
    {{- if .Values.apps.snipr.enabled }}
    snipr:
      client: "snipr"
      scope: "opendesk-snipr-scope"
      role: "opendesk-snipr-access-control"
      group: "managed-by-attribute-Lecturerecording"
    {{- end }}
```

- [ ] **Step 4: Add precreate group for SNIpR**

In the `precreateGroups` list (line 128-137), after the last group entry at line 136 (`{{ if .Values.apps.opencloud.enabled }}'managed-by-attribute-FileshareCloud',{{ end }}`), before the closing `]`, insert:

```yaml
                       {{ if .Values.apps.snipr.enabled }}'managed-by-attribute-Lecturerecording',{{ end }}
```

The updated `precreateGroups` block should read:

```yaml
  precreateGroups: [ 'Domain Admins', 'Domain Users', 'IAM API - Full Access',
                     {{ if .Values.apps.nextcloud.enabled }}'managed-by-attribute-Fileshare', 'managed-by-attribute-FileshareAdmin',{{ end }}
                     {{ if .Values.apps.xwiki.enabled }}'managed-by-attribute-Knowledgemanagement', 'managed-by-attribute-KnowledgemanagementAdmin',{{ end }}
                     {{ if .Values.apps.element.enabled }}'managed-by-attribute-Livecollaboration', 'managed-by-attribute-LivecollaborationAdmin',{{ end }}
                     {{ if .Values.apps.openproject.enabled }}'managed-by-attribute-Projectmanagement', 'managed-by-attribute-ProjectmanagementAdmin',{{ end }}
                     {{ if .Values.apps.jitsi.enabled }}'managed-by-attribute-Videoconference',{{ end }}
                     {{ if .Values.apps.oxAppSuite.enabled }}'managed-by-attribute-Groupware',{{ end }}
                     {{ if .Values.apps.notes.enabled }}'managed-by-attribute-Notes',{{ end }}
                     {{ if .Values.apps.opencloud.enabled }}'managed-by-attribute-FileshareCloud',{{ end }}
                     {{ if .Values.apps.snipr.enabled }}'managed-by-attribute-Lecturerecording',{{ end }}
                   ]
```

- [ ] **Step 5: Commit**

```bash
git add helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotmpl
git commit -m "feat(keycloak): add SNIpR OIDC client with access restriction

Add snipr OIDC client (frontchannel logout), client scope with UUID
and username mappers, client access restriction linked to
managed-by-attribute-Lecturerecording group, and precreate group."
```

---

### Task 8: Portal Tile for SNIpR

**Files:**
- Modify: `helmfile/apps/nubus/values-nubus.yaml.gotmpl`

Add a portal entry `07-custom-snipr-portal-entry.yaml` in the `extraDataFiles` section, after the OpenCloud entry (which ends at line 1578). Follows the BBB pattern at lines 1480-1533.

The existing file has:
- `05-custom-bbb-portal-entry.yaml` at line 1480
- `06-custom-opencloud-portal-entry.yaml` at line 1535

The SNIpR entry is `07-custom-snipr-portal-entry.yaml`, inserted after the OpenCloud entry's `ensure_list_contains` block (after line 1578).

- [ ] **Step 1: Add SNIpR portal entry**

Open `helmfile/apps/nubus/values-nubus.yaml.gotmpl`.

After line 1578 (the closing of the OpenCloud `ensure_list_contains` block), insert the following as a new `extraDataFiles` entry. The indentation must match the existing entries (6 spaces for the key name, aligned with `05-custom-bbb-portal-entry.yaml` and `06-custom-opencloud-portal-entry.yaml`):

```yaml
      07-custom-snipr-portal-entry.yaml: |-
        # SPDX-License-Identifier: AGPL-3.0-only
        # SPDX-FileCopyrightText: 2024-2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH

        # SNIpR Lecture Recording Portal Entry
        # Creates a portal entry for SNIpR with SSO enabled
        # Ref: 05-custom-bbb-portal-entry.yaml for correct format
        ---
        action: "create"
        module: "portals/entry"
        position: "cn=entry,cn=portals,cn=univention,{{ .Values.ldap.baseDn }}"
        properties:
          name: "managementLecturerecording"
          activated: true
          anonymous: false
          linkTarget: "newwindow"
          displayName:
            de_DE: "Vorlesungsaufzeichnung"
            en_US: "Lecture Recording"
          description:
            de_DE: "Vorlesungsaufzeichnung mit automatischer Transkription"
            en_US: "Lecture recording with automatic transcription"
          link:
             - - "en_US"
               - "https://snipr.{{ .Values.global.domain }}"
             - - "de_DE"
               - "https://snipr.{{ .Values.global.domain }}"

        ---
        action: "modify"
        module: "portals/entry"
        position: "cn=managementLecturerecording,cn=entry,cn=portals,cn=univention,{{ .Values.ldap.baseDn }}"
        properties:
          linkTarget: "newwindow"

        ---
        action: "ensure_list_contains"
        module: "portals/category"
        position: "cn=od.applications,cn=category,cn=portals,cn=univention,{{ .Values.ldap.baseDn }}"
        properties:
          entries:
            - "cn=managementLecturerecording,cn=entry,cn=portals,cn=univention,{{ .Values.ldap.baseDn }}"
```

- [ ] **Step 2: Commit**

```bash
git add helmfile/apps/nubus/values-nubus.yaml.gotmpl
git commit -m "feat(portal): add SNIpR lecture recording tile in Anwendungen category

Add 07-custom-snipr-portal-entry.yaml extraDataFile with German and
English display names, description mentioning auto-transcription,
new-window link target, and category assignment to od.applications."
```

---

### Task 9: ROADMAP Update

**Files:**
- Modify: `ROADMAP.md`

Mark the SNIpR-related v1.2 checkboxes as complete (lines 349-355 in the "SNIpR -- Lightweight Recording Alternative" section).

- [ ] **Step 1: Update SNIpR checkboxes in ROADMAP.md**

Open `ROADMAP.md`. In the "SNIpR -- Lightweight Recording Alternative" section (starting at line 349), change the checkboxes:

Change:
```markdown
- [ ] Helm chart for SNIpR recording service
- [ ] SSO integration via Keycloak (OIDC)
- [] Integration with F13 transcription service for auto-transcription
- [ ] Storage backend (S3-compatible for recordings)
- [ ] LTI 1.3 integration with ILIAS and Moodle
- [ ] Portal tile for SNIpR
- [ ] Backup integration with k8up
```

To:
```markdown
- [x] Helm chart for SNIpR recording service
- [x] SSO integration via Keycloak (OIDC)
- [x] Integration with F13 transcription service for auto-transcription
- [x] Storage backend (S3-compatible for recordings)
- [x] LTI 1.3 integration with ILIAS and Moodle
- [x] Portal tile for SNIpR
- [x] Backup integration with k8up
```

Note: The third checkbox in the original file uses `[]` without a space. Fix it to `[x]`.

- [ ] **Step 2: Commit**

```bash
git add ROADMAP.md
git commit -m "docs: mark v1.2 SNIpR lecture recording items complete in ROADMAP

Check off all seven SNIpR deliverables: Helm chart, SSO, F13
transcription, S3 storage, LTI 1.3, portal tile, k8up backup."
```

---

### Task 10: Full Verification

Read all created and modified files. Verify structure, gotemplate syntax, and line counts.

- [ ] **Step 1: Verify SeaweedFS chart file count**

```bash
Get-ChildItem -Recurse helmfile/charts/seaweedfs/ | Measure-Object
```

Expected: 12 files (Chart.yaml, values.yaml, 10 templates including _helpers.tpl).

- [ ] **Step 2: Verify SNIpR storage values**

Read `helmfile/charts/snipr/values.yaml` lines 41-49. Confirm:
- `endpoint: http://seaweedfs-s3:8333`
- `ssl: false`
- `forcePathStyle: true`
- `region: ""`

- [ ] **Step 3: Verify SNIpR app values**

Read `helmfile/apps/snipr/values.yaml.gotmpl` lines 20-24. Confirm:
- `enabled` references `.Values.apps.seaweedfs.enabled`
- `endpoint` references `.Values.services.seaweedfs.endpoint`
- `bucket` references `.Values.services.seaweedfs.bucket`

- [ ] **Step 4: Verify Keycloak client**

Read `helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotmpl`. Confirm:
- `opendesk-snipr-scope` exists in `opendesk.clientScopes`
- `snipr` client exists in `opendesk.clients` with `frontchannelLogout: true`
- `snipr` entry exists in `clientAccessRestrictions`
- `managed-by-attribute-Lecturerecording` exists in `precreateGroups`

- [ ] **Step 5: Verify portal tile**

Read `helmfile/apps/nubus/values-nubus.yaml.gotmpl`. Confirm:
- `07-custom-snipr-portal-entry.yaml` entry exists in `extraDataFiles`
- `managementLecturerecording` is the tile name
- `ensure_list_contains` targets `cn=od.applications,cn=category`

- [ ] **Step 6: Verify ROADMAP**

Read `ROADMAP.md` lines 349-355. Confirm all seven checkboxes show `[x]`.

- [ ] **Step 7: Final commit verification**

```bash
git status
git log --oneline -5
```

Expected: 8 new commits on the branch, clean working tree.

---

## Rollback

### Step 1: Remove Portal Tile

Delete the `07-custom-snipr-portal-entry.yaml` section from `helmfile/apps/nubus/values-nubus.yaml.gotmpl`. Redeploy Nubus.

### Step 2: Remove Keycloak Client

Delete the `snipr` client block, `clientAccessRestrictions.snipr` entry, `opendesk-snipr-scope` from client scopes, and `managed-by-attribute-Lecturerecording` from `precreateGroups` in `helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotmpl`. Redeploy Keycloak bootstrap.

### Step 3: Revert SNIpR Storage

In `helmfile/charts/snipr/values.yaml`, change the storage section back to:

```yaml
  storage:
    type: s3
    s3:
      endpoint: https://minio.opendesk.example.com
      bucket: snipr-recordings
      region: eu-central-1
      ssl: true
      forcePathStyle: false
```

In `helmfile/apps/snipr/values.yaml.gotmpl`, change storage back to:

```yaml
  storage:
    enabled: {{ .Values.services.minio.enabled | default true }}
    endpoint: {{ .Values.services.minio.endpoint | default "https://minio.opendesk.example.com" | quote }}
    bucket: {{ .Values.services.minio.bucket | default "snipr-recordings" | quote }}
```

### Step 4: Remove SeaweedFS

```bash
helmfile destroy -l app=seaweedfs
kubectl delete pvc -l app.kubernetes.io/name=seaweedfs
rm -rf helmfile/charts/seaweedfs/
rm -rf helmfile/apps/seaweedfs/
```

### Step 5: Revert ROADMAP

Uncheck the SNIpR checkboxes in `ROADMAP.md`.

### Step 6: Redeploy

```bash
git add -A && git commit -m "revert: remove lecture recording (v1.2)"
helmfile apply
```

### What Stays After Rollback

- SNIpR chart and templates are unchanged. Only the values revert to MinIO defaults.
- Recordings stored in SeaweedFS are lost when the PVC is deleted. Migrate to MinIO first if retention is needed, or restore from k8up backup.
- F13 integration is config-only and causes no side effects when disabled.
- The SNIpR chart already has LTI, SSO, and transcription scaffolding. Those sections are untouched by v1.2.
