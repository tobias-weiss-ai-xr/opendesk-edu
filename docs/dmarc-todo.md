# DMARC-TODO: opendesk-edu (Produktion – uni-marburg.de)

> **Kontext:** openDesk‑Edu‑Deployment auf Kubernetes (k3s).  
> Stalwart Mail Server (edu‑Variante) als IMAP/SMTP/JMAP‑Backend,  
> Postfix‑Base + Postfix‑OX mit `dkimpy-milter` für SMTP‑Relay,  
> HAProxy‑Ingress, Keycloak‑OIDC, OpenLDAP, Ceph‑Storage.  
> **Live‑Domain: `uni-marburg.de`**  
> Aktueller DMARC: `p=quarantine; sp=quarantine; rua=mailto:dmarc-report@hrz.uni-marburg.de`

---

## Phase 0: Vollständige Bestandsaufnahme

- [ ] **0.1** Aktuelle DNS‑Records von `uni-marburg.de` sichern
  ```bash
  for type in MX TXT AAAA A; do
    echo "=== $type ==="
    dig $type uni-marburg.de +short
  done
  dig TXT _dmarc.uni-marburg.de +short
  dig TXT dkim._domainkey.uni-marburg.de +short 2>/dev/null || echo "Kein DKIM-Record"
  dig TXT *._domainkey.uni-marburg.de +short 2>/dev/null || echo "Kein Wildcard-DKIM"
  ```

- [ ] **0.2** Alle sendenden Systeme im Cluster identifizieren
  ```bash
  # Postfix-Pods
  kubectl get pods -n opendesk -l app.kubernetes.io/name=postfix -o wide
  kubectl get pods -n opendesk -l app.kubernetes.io/name=postfix-ox -o wide
  
  # Stalwart-Pods
  kubectl get pods -n opendesk -l app.kubernetes.io/name=stalwart -o wide
  
  # LoadBalancer-IPs (HAProxy / Metallb)
  kubectl get svc -n opendesk -o wide | grep LoadBalancer
  
  # Node-IPs (für eingehende Verbindungen)
  kubectl get nodes -o wide
  ```

- [ ] **0.3** Stalwart‑DKIM‑Status prüfen
  ```bash
  kubectl exec -n opendesk deploy/stalwart -- stalwart-cli domain list
  kubectl exec -n opendesk deploy/stalwart -- stalwart-cli domain key list uni-marburg.de
  ```

- [ ] **0.4** dkimpy‑milter‑Status prüfen
  ```bash
  kubectl get pods -n opendesk -l app.kubernetes.io/name=opendesk-dkimpy-milter
  kubectl logs -n opendesk -l app.kubernetes.io/name=opendesk-dkimpy-milter --tail=50
  ```

- [ ] **0.5** Postfix‑Milter‑Konfiguration prüfen
  ```bash
  kubectl exec -n opendesk deploy/postfix -- postconf -n | grep milter
  kubectl exec -n opendesk deploy/postfix-ox -- postconf -n | grep milter
  ```

- [ ] **0.6** Aktuelle SPF‑Includes dokumentieren
  ```
  uni-marburg.de TXT "v=spf1 include:_spf.uni-marburg.de include:_spf.plan.io ~all"
  ```
  Prüfen, ob `_spf.uni-marburg.de` auch den opendesk‑Cluster umfasst.

- [ ] **0.7** Mail‑Routing verstehen (Postfix‑Base ↔ Postfix‑OX ↔ Stalwart)
  ```bash
  kubectl exec -n opendesk deploy/postfix -- postconf -n | grep transport
  kubectl exec -n opendesk deploy/postfix-ox -- postconf -n | grep transport
  ```

---

## Phase 1: SPF – Cluster-IPs in SPF aufnehmen

- [ ] **1.1** Cluster‑Netzwerk‑Bereich ermitteln
  ```bash
  # Pod-Netzwerk-CIDR
  kubectl get nodes -o jsonpath='{.items[*].spec.podCIDR}'
  
  # Service‑Cluster‑IP‑Bereich
  kubectl cluster-info dump | grep -m1 service-cluster-ip-range
  
  # Egress‑IPs (über welche IP gehen ausgehende Mails raus?)
  kubectl run tmp --image=busybox -it --rm -- wget -qO- http://ifconfig.me
  ```

- [ ] **1.2** SPF‑Record aktualisieren
  ```
  uni-marburg.de.  TXT  "v=spf1 include:_spf.uni-marburg.de include:_spf.plan.io ip4:<CLUSTER_EGRESS_CIDR> ~all"
  ```
  > **Oder** dedizierten Include-Mechanismus für opendesk:
  ```
  _spf.opendesk.uni-marburg.de.  TXT  "v=spf1 ip4:<CIDR1> ip4:<CIDR2> ~all"
  uni-marburg.de.  TXT  "v=spf1 include:_spf.uni-marburg.de include:_spf.plan.io include:_spf.opendesk.uni-marburg.de ~all"
  ```

- [ ] **1.3** SPF‑Validierung testen
  ```bash
  # Von einer Cluster‑IP
  python3 -c "
  import spf
  result, detail = spf.check(i='<CLUSTER_EGRESS_IP>', s='test@uni-marburg.de', h='mail.opendesk.hrz.uni-marburg.de')
  print(f'Result: {result} - {detail}')
  "
  ```

- [ ] **1.4** `checkSpf` in Postfix aktivieren (nach Proxy‑Protocol‑Setup)
  ```yaml
  # helmfile/environments/edu/ce-overrides.yaml
  technical:
    postfix:
      checkSpf: true
      smtpdUpstreamProxyProtocol: "haproxy"  # damit Postfix echte Client-IP sieht
      restrictions:
        unknownReverseClientHostname: true
        unknownClientHostname: true
        invalidHeloHostname: true
        nonFQDNSender: true
        unknownSenderDomain: true
  ```

- [ ] **1.5** Nach Aktivierung 24h Monitoring (keine False Positives)

---

## Phase 2: DKIM – Harmonisierung zwischen Postfix und Stalwart

### Entscheidungsmatrix

| Szenario | Beschreibung | Empfehlung |
|:---------|:-------------|:-----------|
| **A** Nur dkimpy‑milter signiert | Status quo – Postfix signiert, Stalwart unsigniert | ⚠️ Stalwart-Mails (JMAP) unsigniert → DMARC‑Fail |
| **B** Nur Stalwart signiert | Stalwart built‑in DKIM, Postfix dkimpy‑milter deaktiviert | ⚠️ Postfix-Mails unsigniert |
| **C** Beide mit gleichem Key | Gleicher privater RSA‑Key in dkimpy‑milter + Stalwart | ⚠️ Key‑Management aufwändig |
| **D** Beide mit getrennten Selektoren | `s1._domainkey` (Postfix) + `s2._domainkey` (Stalwart) | ✅ Empfohlen |

- [ ] **2.1** Entscheidung treffen → **Empfehlung: Variante D**

### 2.2 dkimpy‑milter (Postfix) – bestehenden Key prüfen

- [ ] **2.2.1** Vorhandenen DKIM‑Selector ermitteln
  ```bash
  kubectl exec -n opendesk deploy/postfix -- postconf -n | grep milter
  kubectl get secret -n opendesk dkim-keys -o yaml 2>/dev/null
  ```

- [ ] **2.2.2** Falls kein Key existiert: neuen Key für Selector `s1` generieren
  ```bash
  mkdir -p /tmp/dkim-keys
  docker run --rm -v /tmp/dkim-keys:/keys \
    ghcr.io/opendesk/dkimpy-milter:latest \
    dkim-genkey -d uni-marburg.de -s s1 -D /keys
  
  # In Kubernetes Secret
  kubectl create secret generic dkim-keys -n opendesk \
    --from-file=s1.private=/tmp/dkim-keys/s1.private
  ```

- [ ] **2.2.3** DNS‑Eintrag publizieren (falls nicht vorhanden)
  ```
  s1._domainkey.uni-marburg.de.  TXT  "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb..."
  ```

### 2.3 Stalwart DKIM – neuen Key für Selector `s2`

- [ ] **2.3.1** Stalwart‑DKIM-Key generieren
  ```bash
  kubectl exec -n opendesk deploy/stalwart -- stalwart-cli domain key generate uni-marburg.de s2 2048
  ```

- [ ] **2.3.2** Public‑Key auslesen
  ```bash
  kubectl exec -n opendesk deploy/stalwart -- stalwart-cli domain key get uni-marburg.de s2
  ```

- [ ] **2.3.3** DNS‑Eintrag publizieren
  ```
  s2._domainkey.uni-marburg.de.  TXT  "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb..."
  ```

- [ ] **2.3.4** Stalwart‑Config für DKIM‑Signierung ergänzen
  ```yaml
  # helmfile/apps/edu/stalwart/values.yaml.gotmpl
  stalwart:
    # ... existing config ...
    # DKIM-Konfiguration via extraConfigMap
    extraConfig:
      session.smtp.mail.sign: true
      session.smtp.mail.key: "s2"
      session.smtp.mail.domain: "uni-marburg.de"
  ```
  > **Hinweis:** Das Chart muss ggf. um `extraConfig` erweitert werden,  
  > oder Sie mounten eine eigene `config.toml` via ConfigMap.

- [ ] **2.3.5** Signatur testen
  ```bash
  kubectl exec -n opendesk deploy/stalwart -- sh -c \
    'echo "DKIM Test from Stalwart" | mail -s "DKIM Test" external-test@example.com'
  # Beim Empfänger Header prüfen: DKIM-Signature: ... s=s2; d=uni-marburg.de
  ```

### 2.4 Mail‑Routing klären

> **Ziel:** Jede ausgehende Mail wird **mindestens einmal** signiert.

- [ ] **2.4.1** Wenn Stalwart direkt an externe MX liefert → Stalwart signiert (s2)
- [ ] **2.4.2** Wenn Stalwart an Postfix‑OX/BASE relayt → Postfix signiert (s1)
- [ ] **2.4.3** Wenn Postfix an Stalwart relayt → beide signieren (zwei Signaturen = besser)
- [x] **2.4.4** Aktuelles Routing dokumentieren:
  ```
  SOGo / Thunderbird → Stalwart (IMAP/JMAP) → Postfix-OX → extern
  Apps → Postfix-Base → extern
  ```
  → **Fazit:** Postfix signiert aktuell mit dkimpy‑milter.  
  → Stalwart muss zusätzlich signieren für den Fall, dass Mails direkt rausgehen.

---

## Phase 3: DMARC – bestehende Policy optimieren

- [ ] **3.1** Aktuellen DMARC‑Record analysieren
  ```
  Aktuell: v=DMARC1; p=quarantine; rua=mailto:dmarc-report@hrz.uni-marburg.de; sp=quarantine; ri=86400
  ```
  ✅ `p=quarantine` – gut  
  ✅ `sp=quarantine` – Subdomain‑Policy aktiv  
  ✅ `rua=` – Berichtsadresse vorhanden  
  ⚠️ `ri=86400` – Standard (alle 24h), in Ordnung  
  ❌ `ruf=` fehlt – forensische Berichte nicht aktiviert  
  ❌ `fo=` fehlt – Standardverhalten (nur bei Totalausfall)

- [ ] **3.2** DMARC‑Record optimieren
  ```
  _dmarc.uni-marburg.de.  TXT  "v=DMARC1; p=quarantine; sp=quarantine; pct=100;
                                 rua=mailto:dmarc-report@hrz.uni-marburg.de;
                                 ruf=mailto:dmarc-ruf@hrz.uni-marburg.de;
                                 fo=1; ri=3600"
  ```
  **Änderungen:**
  - `pct=100` explizit (war implizit)
  - `ruf=...` Adresse für forensische Berichte hinzugefügt
  - `fo=1` – Bericht bei DKIM‑ **oder** SPF‑Fail (nicht nur bei beiden)
  - `ri=3600` – Stündliche Berichte statt täglich (feinere Auflösung)

- [ ] **3.3** Forensische Berichte empfangen können
  ```bash
  # Mailbox für ruf einrichten (z. B. dmarc-ruf@hrz.uni-marburg.de)
  # Oder per Alias an bestehende Mailbox
  kubectl exec -n opendesk deploy/postfix -- \
    postconf -e "virtual_alias_maps=hash:/etc/postfix/virtual"
  echo "dmarc-ruf@hrz.uni-marburg.de dmarc-team@hrz.uni-marburg.de" >> /tmp/virtual
  ```

- [ ] **3.4** Prüfen, ob DMARC‑Reports aktuell ankommen und ausgewertet werden
  ```bash
  # Aktuelle Report-Dateien im Postfix-Spool
  kubectl exec -n opendesk deploy/postfix -- find /var/spool -name "*dmarc*" 2>/dev/null
  kubectl exec -n opendesk deploy/stalwart -- find /opt/stalwart -name "*.xml" 2>/dev/null
  ```

---

## Phase 4: DMARC‑Report‑Auswertung aufsetzen

- [ ] **4.1** Report‑Parser installieren (parsedmarc)
  ```bash
  # Option A: Als Sidecar im Cluster
  kubectl apply -f - <<EOF
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: dmarc-parser
    namespace: opendesk
  spec:
    replicas: 1
    selector:
      matchLabels:
        app: dmarc-parser
    template:
      metadata:
        labels:
          app: dmarc-parser
      spec:
        containers:
        - name: parsedmarc
          image: ghcr.io/domainaware/parsedmarc:latest
          env:
          - name: PARSEDMARC_SMTP_HOST
            value: postfix.opendesk.svc.cluster.local
          - name: PARSEDMARC_SMTP_PORT
            value: "25"
          - name: PARSEDMARC_SMTP_USER
            value: dmarc-parser
          - name: PARSEDMARC_SMTP_PASSWORD
            valueFrom:
              secretKeyRef:
                name: dmarc-parser-credentials
                key: password
          - name: PARSEDMARC_SMTP_TIMEOUT
            value: "30"
          - name: PARSEDMARC_GEOIP_ENABLED
            value: "true"
          volumeMounts:
          - name: config
            mountPath: /etc/parsedmarc
        volumes:
        - name: config
          configMap:
            name: parsedmarc-config
  EOF
  ```

- [ ] **4.2** parsedmarc‑Konfiguration
  ```yaml
  # parsedmarc-config.yaml
  [general]
  save_aggregate = True
  save_forensic = True
  
  [elasticsearch]
  hosts = elasticsearch-master.opendesk.svc.cluster.local:9200
  
  [smtp]
  host = postfix.opendesk.svc.cluster.local
  port = 25
  
  [imap]
  host = stalwart.opendesk.svc.cluster.local
  port = 143
  user = dmarc-parser@uni-marburg.de
  password = ...
  ```

- [ ] **4.3** Grafana‑Dashboard für DMARC‑Metriken
  ```bash
  # parsedmarc liefert Metriken via Prometheus
  # Dashboard-ID 12666 (DMARC Dashboard) oder eigenes bauen
  ```

- [ ] **4.4** Report‑Verifikation: Ersten aggregierten Report manuell triggern
  ```bash
  # Von einer externen Domain einen DMARC-Report anfordern
  # z. B. über dmarcian.com oder Google Postmaster Tools
  ```

---

## Phase 5: DMARC‑Verifikation in Stalwart aktivieren (optional)

> Nur nötig, wenn Stalwart direkt Mails von extern empfängt.

- [ ] **5.1** DMARC‑Prüfung in Stalwart aktivieren
  ```yaml
  # helmfile/apps/edu/stalwart/values.yaml.gotmpl
  stalwart:
    extraConfig:
      session.smtp.rcpt.reject-dmarc: true
      session.smtp.rcpt.reject-spf: true
      session.smtp.rcpt.reject-dkim: true
  ```

- [ ] **5.2** Stalwart‑Konfiguration neu laden
  ```bash
  # Stalwart Config Reload (via HTTP API)
  curl -X POST https://mail.opendesk.hrz.uni-marburg.de/api/admin/config/reload \
    -H "Authorization: Bearer $ADMIN_TOKEN"
  ```

- [ ] **5.3** Test: Externe Mail ohne DKIM/SPF senden → sollte rejected werden
  ```bash
  # Von einem nicht-authorisierten Server
  swaks --to testuser@uni-marburg.de --server mail.opendesk.hrz.uni-marburg.de \
    --header "Subject: DMARC Test" --body "Test"
  ```

---

## Phase 6: DFN‑AAI‑Föderation – DMARC‑Aspekte

- [ ] **6.1** DFN‑AAI SPF‑Include prüfen (falls Mails über DFN‑Infrastruktur laufen)
  ```
  # Gibt es SPF-Einträge für DFN?
  dig TXT _spf.dfn.de +short
  dig TXT dfn.de +short | grep "v=spf1"
  ```

- [ ] **6.2** Falls Föderations‑MTA Mails relayt: ARC aktivieren
  ```toml
  [session.smtp.arc]
  add-seal = true
  verify = true
  ```

- [ ] **6.3** DFN‑AAI‑Registrierung: DMARC‑Konfiguration dokumentieren (siehe `docs/dfn-aai-registrierung-übergabe.md`)

---

## Phase 7: Monitoring & Alerting

- [ ] **7.1** Prometheus‑Metriken aus parsedmarc abgreifen
  ```yaml
  # ServiceMonitor für parsedmarc
  apiVersion: monitoring.coreos.com/v1
  kind: ServiceMonitor
  metadata:
    name: dmarc-parser
    namespace: opendesk
  spec:
    endpoints:
    - port: metrics
      interval: 30s
    selector:
      matchLabels:
        app: dmarc-parser
  ```

- [ ] **7.2** Alert‑Rules definieren
  ```yaml
  - alert: DMARCFailRate
    expr: |
      rate(dmarc_fail_total{domain="uni-marburg.de"}[1h]) > 0.05
    for: 2h
    labels:
      severity: warning
    annotations:
      summary: ">5% DMARC-Fail-Rate auf uni-marburg.de"
  ```

- [ ] **7.3** Wöchentlichen DMARC‑Report‑Check als Task in der Doku

---

## Phase 8: Langfristig – Upgrade auf `p=reject`

- [ ] **8.1** Nach 3 Monaten `p=quarantine` Bilanz ziehen
- [ ] **8.2** False‑Positive‑Rate dokumentieren
- [ ] **8.3** SPF‑Abdeckung auf 100% bringen (alle Sendequellen)
- [ ] **8.4** DKIM‑Signatur für 100% aller ausgehenden Mails sicherstellen
- [ ] **8.5** DMARC auf `p=reject` umstellen
  ```
  _dmarc.uni-marburg.de.  TXT  "v=DMARC1; p=reject; sp=reject; pct=100;
                                 rua=mailto:dmarc-report@hrz.uni-marburg.de;
                                 ruf=mailto:dmarc-ruf@hrz.uni-marburg.de;
                                 fo=1"
  ```

---

## Phase 9: Dokumentation

- [ ] **9.1** DMARC‑Architektur im Repo dokumentieren
  ```markdown
  # docs/dmarc.md
  ## DMARC-Architektur uni-marburg.de
  
  | Komponente | Rolle | DKIM-Selector | SPF-Include |
  |:-----------|:------|:--------------|:------------|
  | Postfix-Base | System-MTA | s1 | _spf.uni-marburg.de |
  | Postfix-OX | Groupware-MTA | s1 | _spf.uni-marburg.de |
  | Stalwart | IMAP/SMTP/JMAP | s2 | _spf.opendesk |
  
  ## Helmfile-Override
  technical.postfix.checkSpf: true
  ...
  ```

- [ ] **9.2** Runbook für DMARC‑Incidents
  ```markdown
  # docs/runbook/dmarc-incident.md
  ## DMARC-Incident
  
  1. Prüfen: Welcher SPF/DKIM-Mechanismus schlug fehl?
  2. Logs: `kubectl logs -n opendesk deploy/postfix | grep spf`
  3. ...
  ```

---

## Zusammenfassung Prioritäten

| Prio | Aufgabe | Phase | Aufwand |
|:----:|:--------|:------|:--------|
| 🔴 | SPF‑Record um Cluster‑CIDR ergänzen | 1 | 1h |
| 🔴 | DKIM‑Selektoren harmonisieren (s1 + s2) | 2 | 3h |
| 🔴 | DMARC‑Record optimieren (`ruf`+`fo`+`ri`) | 3 | 0.5h |
| 🟡 | `checkSpf: true` + Proxy‑Protocol aktivieren | 1 | 2h |
| 🟡 | DMARC‑Report‑Auswertung (parsedmarc) | 4 | 4h |
| 🟡 | Forensische Berichte empfangen (ruf‑Mailbox) | 3 | 1h |
| 🟢 | Stalwart‑DMARC‑Verifikation aktivieren | 5 | 1h |
| 🟢 | DFN‑AAI‑ARC prüfen | 6 | 2h |
| 🟢 | Grafana‑Dashboard + Alerts | 7 | 3h |
| 🟢 | Dokumentation + Runbook | 9 | 2h |
| 🔵 | `p=reject` nach 3 Monaten Monitoring | 8 | 0.5h |
