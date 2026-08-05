---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

![width:900](media/readme-lead-image.svg)

# 🏛️ openDesk: Άνετα και Κυρίαρχο

🎓 openDesk Edu — Ψηφιακή Κυριαρχία στα Πανεπιστήμια

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg

---

# Ψηφιακή Κυριαρχία — Οι Τέσσερις Πυλώνες

- **Κυριαρχία Υποδομής** 🖥️
  Ανεξάρτητη λειτουργία διακομιστών και δικτύων
- **Κυριαρχία Δεδομένων** 💾
  Έλεγχος αποθήκευσης και πρόσβασης δεδομένων
- **Κυριαρχία Λογισμικού** 💻
  Λογισμικό ανοιχτού κώδικα χωρίς ιδιόκτητες εξαρτήσεις
- **Κυριαρχία Λειτουργίας** 🔧
  Πλήρης έλεγχος ενημερώσεων και συντήρησης

---

# Τι είναι το openDesk

- **Εναλλακτική ανοιχτού κώδικα** στο M365 & Google Workspace 🐧
- **Από την Κυβέρνηση για την Κυβέρνηση** (BMI / ZenDiS) 🏛️
- **Πιστοποιημένο από το BSI** (Γερμανική κυριαρχία) 📜
- **Cloud-Native:** Χώρος εργασίας βασισμένος σε Kubernetes ☁️
- **Διαμορφώσιμα Συστατικά:**
  - Chat, Αρχεία, Wiki, Διαχείριση έργων
  - Email, Διαγράμματα, Γραφείο Web, Βίντεο
- **Self-Hosted** ή **SaaS** 🖥️

---

# Επισκόπηση Συστατικών

| Συστατικό | Λογισμικό |
|------------|----------|
| Chat 💬 | Element / Synapse |
| Αρχεία ☁️ | Nextcloud |
| Wiki 📖 | XWiki |
| Έργα ✅ | OpenProject |
| Email ✉️ | OX App Suite |
| Διαγράμματα 📊 | CryptPad |
| Γραφείο Web 📄 | Collabora |
| Βίντεο 📹 | Jitsi |

---

# Στατιστικά Έργου openDesk

**Ανάπτυξη** 🔀              | **Κοινότητα** 👥
--------------------------------|---------------------------
Έναρξη: Ιούλιος 2023             | Συνεισφέροντες: ~ 70
Διάρκεια: ~ 3 χρόνια          | Οργανισμοί: ~ 27
Commits: ~ 1.500                |
Εκδόσεις: ~ 150                 |

**OpenCode.de** 🛡️              | **Αλυσίδα Εφοδιασμού** 🔒
Πλατφόρμα με χρηματοδότηση BMI  | Υπογεγραμμένα εικόνες εμπορευματοκιβωτίων
Κυρίαρχη υποδομή cloud            | SBOM για όλα τα συστατικά

---

# Επισκόπηση Υποδομής

| Μέτρο | Τιμή |
|--------|------|
| **Κόμβοι** | 9 (3 Control-Plane + 6 Worker) |
| **Διανομή** | K3s v1.32.3 |
| **ΛΣ** | Debian 12 |
| **CPU (Ελάχιστο)** | 16 πυρήνες |
| **RAM (Ελάχιστο)** | 64 GB |
| **Αποθήκευση** | 4+ TB Ceph |

---

# Εικονικοποίηση με Proxmox

![height:500px](media/proxmox.png)

---

# Helmfile & Περιβάλλον HRZ

```bash
# Ανάπτυξη με Helmfile
helmfile apply -e hrz
```

- **Ορχήστρωση Helmfile** ⚓
  - Δηλωτική διαμόρφωση σε `helmfile_generic.yaml.gotmpl`
  - Παρακαμπτήριες ανά περιβάλλον σε `environments/hrz/`
  - Αυτόματο αντίγραφο ασφαλείας εξαρτήσεων
- **Δημιουργήθηκε περιβάλλον HRZ** 🖥️
  - Αντίγραφο του `staging` με προσαρμογές
  - Διαμόρφωση ειδική για Πανεπιστήμιο Marburg
  - Σύστημα δοκιμών για πιλοτική λειτουργία

---

# Τοπική Ανάπτυξη Chart

```bash
# Κλωνοποίηση/λήψη chart τοπικά
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **Τοπική ανάπτυξη & δοκιμή chart** 💻
- **Κλωνοποίηση/λήψη σε charts-<branch>/** ⬇️
- **Αναφορές Helmfile σε τοπικές διαδρομές** 📄
- **Αντίγραφο ασφαλείας & επαναφορά με --revert** ↩️

---

# Εισαγωγή Χρηστών: Παροχή

- **UDM REST API** — Εισαγωγή CSV/ODS, ομάδες LDAP 👤
- **Σύνδεση Λογαριασμών** — Σύνδεση ταυτότητας SAML 🔗
- **Λειτουργία Demo** — Δοκιμαστικοί λογαριασμοί, εικόνα προφίλ 🖼️

---

# Εισαγωγή Χρηστών: Ανατροπή Παροχής

**Ροή Εργασίας Ανατροπής Παροχής σε Δύο Φάσεις:**

- **Φάση 1: Απενεργοποίηση Χρήστη**
  - IAM API → UCS Απενεργοποίηση → Χρονική σήμανση στη Περιγραφή
  - Keycloak: Αφαίρεση SAML + διάλυση ομάδων
- **Φάση 2: Διαγραφή Χρήστη**
  - Περίοδος χάριτος (6 μήνες) → Μόνιμη διαγραφή
  - Έξοδος: `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — Επισκόπηση

- **Επέκταση του openDesk CE** για πανεπιστήμια 🏫
- **Νέα Συστατικά:**
  - Συστήματα Διαχείρισης Μάθησης (ILIAS, Moodle)
  - Βιντεοδιάσκεψη για Διδασκαλία (BigBlueButton)
  - Εναλλακτικός Συγχρονισμός Αρχείων (OpenCloud)
- **Όλα ενσωματωμένα με Keycloak SSO** 🔐
- **Ανάπτυξη όλων με `helmfile apply`** ⚡

**GitHub:** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu)

---

# 📚 Εκπαιδευτικά Συστατικά

| Συστατικό | Κατάσταση | Περιγραφή |
|------------|--------|--------------|
| 📖 ILIAS | ✅ Σταθερό | LMS με SAML SSO — Μαθήματα, SCORM, Δοκιμασίες |
| 📖 Moodle | 🔄 Beta | LMS με Shibboleth — Πρόσθετα, Βαθμολόγιο |
| 🎥 BigBlueButton | 🔄 Beta | Βιντεοδιάσκεψη για διδασκαλία — Εγγραφή, Λευκός πίνακας |
| ☁️ OpenCloud | 🔄 Beta | Συγχρονισμός αρχείων βάσει CS3 — Εναλλακτική στο Nextcloud |

---

# 🔐 ILIAS SSO — Αρχιτεκτονική

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**Ροή SSO 6 Βημάτων:**

1. 🖥️ Portal → ILIAS tile
2. 🔄 ILIAS → Shibboleth SP
3. 🔑 Keycloak → Uni-IdP
4. 🎓 Login (weblogin.uni-marburg.de)
5. 📨 SAML Assertion back
6. ✅ ILIAS Dashboard

**Stack:** Apache + Shibboleth SP + Keycloak Broker

</td>
</tr>
</table>

---

<div style="font-size: 0.65em;">

# 🔧 Ανάπτυξη ILIAS — Μαθήματα

| Πρόβλημα | Λύση |
|---------|---------|
| `Wrong Login or Password` | SAML NameFormat λείπει από το attribute-map.xml |
| Λανθασμένα ονόματα χαρακτηριστικών | Uni-IdP στέλνει `givenname`/`surname` |
| `handlerSSL` → 404 | Εσωτερικό TLS: Apache SSL στη θύρα 8443 (v5) |
| Λογαριασμοί απενεργοποιημένοι | `shib_activate_new = 0` |
| SAML Timeout | 60s → 300s |
| Health Check | CronJob: curl SSO-Redirect (ωριαία) |

---

# 🚀 Γρήγορη Εκκίνηση - Ανάπτυξη σε 3 Βήματα

```bash
# 1. Κλωνοποιήστε το αποθετήριο
git clone https://github.com/opendesk-edu/opendesk-edu.git
cd opendesk-edu

# 2. Διαμορφώστε το περιβάλλον σας
# Επεξεργαστείτε helmfile/environments/default/global.yaml.gotmpl
# Ορίστε τον τομέα σας, τον τομέα mail και το μητρώο εικόνων

# 3. Αναπτύξτε
helmfile -e default apply
```

📖 Πλήρης τεκμηρίωση: [docs/getting-started.md](https://github.com/opendesk-edu/opendesk-edu/blob/main/docs/getting-started.md)

---

# Διαμόρφωση Δικτύου

- **Ingress Controller:** haproxy-ingress
- **Reverse Proxy:** Traefik — HTTP/HTTPS τερματισμός 🔄
- **LoadBalancer:** MetalLB
- **Όλα τα Ingress** μεταφέρθηκαν στο haproxy ✅

---

# Grafana Dashboard

![height:500px](media/grafana.png)

---

# Διαδικασία Ενημέρωσης

```bash
# Φόρτωση τελευταίων εκδόσεων
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# Έλεγχος αλλαγών
helmfile diff -e hrz

# Εφαρμογή ενημερώσεων
helmfile apply -e hrz

# Επαναφορά αν χρειαστεί
helmfile rollback -e hrz
```

- **Ελεγχόμενες ενημερώσεις μέσω Helmfile** 🔄
- **Εύκολη δυνατότητα επαναφοράς** ↩️

---

# HRZ-Αναβάθμιση: Μετάβαση Ingress

- **Μετάβαση:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (κλάδος uniapps)
  - Όλα τα Ingress μεταφέρθηκαν στο haproxy ✅
- **Κλάσεις Ingress:**
  - `ingressClassName: haproxy`
  - nginx πλήρως κατηργημένο
- **Διαμόρφωση:**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# HRZ-Αναβάθμιση: Διπλό Αντίγραφο Ασφαλείας

- **Στόχοι:** Πλεονασμός Αποθήκευσης Αντιγράφων Ασφαλείας 🗄️
- **Στρατηγική:** S3-συμβατό με restic backend 🔄
  - Πρωτεύον: `s3.example.org:9000/backup-primary`
  - Δευτερεύον: `s3-backup.example.org:9000/backup-secondary`
- **Πρόγραμμα:** Καθημερινά στις 00:42, Έλεγχος εβδομαδιαία, Καθαρισμός Κυριακές ⏰
- **Διατήρηση:** 14 Ημερήσια, Διατήρηση των 5 Τελευταίων 📦

---

# Θεσμικά Εμπόδια

- **Νομικό Τμήμα** ⚖️
  - GDPR, συμβόλαια AVV, Συμμόρφωση αδειών
- **Συμβούλιο Προσωπικού** 👥
  - Συμφωνία παροχής υπηρεσιών, Συμμετοχή για συστήματα IT
- **Διοίκηση** 🏢
  - Προτιμήσεις Microsoft, Συμβατότητα μορφών
- **Απαιτούμενα Έγγραφα** 📄
  - DSFA, Υπολογισμός TCO

---

# Επόμενα Βήματα & Συστάσεις

1. Εκκίνηση πιλοτικής λειτουργίας ▶️
2. Σταδιακή ανάπτυξη (10 → 100 → 1000 χρήστες) 👥
3. Σαφής διαχωρισμός από παραγωγικά συστήματα 🔗
4. Αξιολόγηση: Κατηγοριοποίηση περιπτώσεων χρήσης ανάλογα με απαιτήσεις κυριαρχίας ✅
5. Προϋπολογισμός για ομάδα λειτουργίας (όχι μόνο για υλοποίηση) 💰

---

# 🤝 Συμμετέχετε

**Βοηθήστε μας να χτίσουμε το openDesk Edu για τα πανεπιστήμια!**

- ⭐ **Κάντε Star το αποθετήριο:** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu)
- 🧪 **Δοκιμάστε τοπικά:** Αναπτύξτε με Helmfile και δώστε ανατροφοδότηση
- 🐛 **Αναφέρετε ζητήματα:** Issues για σφάλματα ή αιτήματα χαρακτηριστικών
- 💻 **Συνεισφέρετε:** PRs ευπρόσδεκτα — δείτε CONTRIBUTING.md

**Ας χτίσουμε μαζί κυρίαρχο λογισμικό πανεπιστημίων!** 🎓

---

# Τεχνικοί Πόροι

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [Deployment-Guide](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [User-Import](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu:** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu) · Εκπαιδευτική επέκταση για πανεπιστήμια
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s:** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **Cluster-Automation:** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# Οργανωτικοί Πόροι

- **Σύσταση HBDI (Αξιολόγηση M365):**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **Hessischer Digitalpakt Hochschulen:**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT Open Source (ZenDiS):**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB (digitale-verwaltung.de):**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it-node.html)
- **Ψηφιακή Κυριαρχία στα Πανεπιστήμια:**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate-Werkstattgespräch:**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)
