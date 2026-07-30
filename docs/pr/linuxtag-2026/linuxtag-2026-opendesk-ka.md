---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

![width:900](media/readme-lead-image.svg)

# 🏛️ openDesk: მომფორტული და სუვერენულობა?

🎓 openDesk Edu — ციხოვნული სუვერენულობა უნივერსიტეტებში

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg

---

# ციფრული სუვერენულობა — ოთხი სვეტი

- **ინფრასტრუქტურული სუვერენულობა** 🖥️
  სერვერებისა და ქსელების დამოუკიდებლად მართვა
- **მონაცემების სუვერენულობა** 💾
  მონაცემების შენახვისა და წვდომის კონტროლი
- **პროგრამული უზრუნველყოფის სუვერენულობა** 💻
  ღია კოდის პროგრამული უზრუნველყოფა კერძო დამოკიდებულებების გარეშე
- **ექსპლუატაციული სუვერენულობა** 🔧
  სრული კონტროლი განახლებებსა და მხარდაჭერაზე

---

# რა არის openDesk?

- **ღია კოდის ალტერნატივა** M365-სა და Google Workspace-სათვის 🐧
- **მთავარის მიერ მთავრისთვის** (BMI / ZenDiS) 🏛️
- **BSI-სერტიფიცირებული** (გერმანული სუვერენულობა) 📜
- **მონაცულის ნატიური:** Kubernetes-ზე დაფუძნებული სამუშაო ადგილი ☁️
- **მოდულური კომპონენტები:**
  - ჩატი, ფაილები, ვიკი, პროექტის მართვა
  - ელ. ფოსტა, დიაგრამები, ვებ-ოფისი, ვიდეო
- **საკუთარი ჰოსტინგი** ან **SaaS** 🖥️

---

# კომპონენტების მიმოხილვა

| კომპონენტი | პროგრამული უზრუნველყოფა |
|------------|----------|
| ჩატი 💬 | Element / Synapse |
| ფაილები ☁️ | Nextcloud |
| ვიკი 📖 | XWiki |
| პროექტი ✅ | OpenProject |
| ელ. ფოსტა ✉️ | OX App Suite |
| დიაგრამები 📊 | CryptPad |
| ვებ-ოფისი 📄 | Collabora |
| ვიდეო 📹 | Jitsi |

---

# openDesk პროექტის სტატისტიკა

**განვითარება** 🔀              | **საზოგადოება** 👥
--------------------------------|---------------------------
დაწყება: 2023 წლის ივლისი    | წვლილშემმატებლები: ~ 70
ხანგრძლივობა: ~ 3 წელი      | ორგანიზაციები: ~ 27
Commit-ები: ~ 1,500             |
რელიზები: ~ 150                |

**OpenCode.de** 🛡️              | **მიწოდების ჯაჭვი** 🔒
BMI-ის მიერ დაფინანსებული პლატფორმა | ხელმოწერილი კონტეინერის ანასახულები
სუვერენული მონაცულის ინფრასტრუქტურა | SBOM ყველა კომპონენტისთვის

---

# ინფრასტრუქტურის მიმოხილვა

| მაჩვენებელი | მნიშვნელობა |
|--------|------|
| **კვანძები** | 9 (3 საკონტროლო პლანე + 6 სამუშაო) |
| **დისტრიბუცია** | K3s v1.32.3 |
| **ოსი** | Debian 12 |
| **CPU (მინიმუმ)** | 16 ბირთვი |
| **RAM (მინიმუმ)** | 64 გბ |
| **საცავი** | 4+ ტბ Ceph |

---

# ვირტუალიზაცია Proxmox-ით

![height:500px](media/proxmox.png)

---

# Helmfile და HRZ-გარემო

```bash
# განთავსება Helmfile-ით
helmfile apply -e hrz
```

- **Helmfile ორკესტრაცია** ⚓
  - დეკლარატიული კონფიგურაცია `helmfile_generic.yaml.gotmpl`
  - გარემოს სპეციფიკური გადაწყვეტები `environments/hrz/`
  - ავტომატური დამოკიდებულებების სარეზერვო კოპირება
- **HRZ-გარემო შექმნილია** 🖥️
  - `staging`-ის კოპირა მორგებებით
  - მარბურგის უნივერსიტეტის სპეციფიკური კონფიგურაცია
  - სატესტო სისტემა პილოტურ ოპერაციაზე

---

# ლოკალური Chart-ის განვითარება

```bash
# Chart-ების ლოკალური კლონირება/pull
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **ლოკალური Chart-ის განვითარება და ტესტირება** 💻
- **კლონირება/pull charts-<branch>/** ⬇️
- **Helmfile-ის ბმულები ლოკალურ ბილიკებზე** 📄
- **სარეზერვო და დაბრუნება --revert-ით** ↩️

---

# მომხმარებლების იმპორტი: პროვიჟირება

- **UDM REST API** — CSV/ODS იმპორტი, LDAP ჯგუფები 👤
- **ანგარიშის მიბმა** — SAML იდენტიფიკაციის მიბმა 🔗
- **დემო რეჟიმი** — სატესტო ანგარიშები, პროფილის ფოტოები 🖼️

---

# მომხმარებლების იმპორტი: დეპროვიჟირება

**ორ ეტაპიანი დეპროვიჟირების პროცესი:**

- **1 ეტაპი: მომხმარებლის გამორთვა**
  - IAM API → UCS გამორთვა → დროის შტამპი აღწერაში
  - Keycloak: SAML-ის წაშლა + ჯგუფების დაშლა
- **2 ეტაპი: მომხმარებლის წაშლა**
  - საგრძნობელი პერიოდი (6 თვე) — სამუდამოდ წაშლა
  - შედეგი: `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — მიმოხილვა

- **openDesk CE-ის გაფართოება** უნივერსიტეტებისთვის 🏫
- **ახალი კომპონენტები:**
  - სასწავლო მართვის სისტემები (ILIAS, Moodle)
  - სასწავლო ვიდეოკონფერენციები (BigBlueButton)
  - ალტერნატიული ფაილების სინქრონიზაცია (OpenCloud)
- **ყველა ინტეგრირებულია Keycloak SSO-სთან** 🔐
- **ყველაფერის განთავსება `helmfile apply`-ით** ⚡

**GitHub:** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu)

---

# 📚 საგანმანათლებლო კომპონენტები

| კომპონენტი | სტატუსი | აღწერა |
|------------|--------|--------------|
| 📖 ILIAS | ✅ სტაბილური | LMS SAML SSO-თან — კურსები, SCORM, ტესტები |
| 📖 Moodle | 🔄 ბეტა | LMS Shibboleth-ით — მოდულები, ქულათა ჟურნალი |
| 🎥 BigBlueButton | 🔄 ბეტა | სასწავლო ვიდეოკონფერენცია — ჩაწერა, თეთრი დაფა |
| ☁️ OpenCloud | 🔄 ბეტა | CS3-ზე დაფუძნებული ფაილების სინქრონიზაცია — ალტერნატივა Nextcloud-სთვის |

---

# 🔐 ILIAS SSO — არქიტექტურა

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**6 ნაბიჯიანი SSO პროცესი:**

1. 🖥️ პორტალი → ILIAS ფილა
2. 🔄 ILIAS → Shibboleth SP
3. 🔑 Keycloak → Uni-IdP
4. 🎓 ავტორიზაცია (weblogin.uni-marburg.de)
5. 📨 SAML ასერტული უკან
6. ✅ ILIAS დაშბორდი

**Stack:** Apache + Shibboleth SP + Keycloak Broker

</td>
</tr>
</table>

---

<div style="font-size: 0.65em;">

# 🔧 ILIAS განთავსება — ნახვები გაკვეთილები

| პრობლემა | გადაწყვეტა |
|---------|---------|
| `Wrong Login or Password` | SAML NameFormat აკლია attribute-map.xml-ში |
| ატრიბუტების სახელები არასწორია | Uni-IdP გაგზავნის `givenname`/`surname` |
| `handlerSSL` → 404 | შიდა TLS: Apache SSL პორტზე 8443 (v5) |
| ანგარიშები გამორთულია | `shib_activate_new = 0` |
| SAML ტაიმაუტი | 60წმ → 300წმ |
| ჯანმრთელობის შემოწმება | CronJob: curl SSO-რედირექტი (ყოველ საათს) |

---

# 🚀 სწრაფი დაწყება - განთავსება 3 ნაბიჯით

```bash
# 1. რეპოზიტორიის კლონირება
git clone https://github.com/opendesk-edu/opendesk-edu.git
cd opendesk-edu

# 2. თქვენი გარემოს კონფიგურაცია
# რედაქტირება helmfile/environments/default/global.yaml.gotmpl
# თქვენი დომენის, ფოსტის დომენისა და ანასახულების რეგისტრის დაყენება

# 3. განთავსება
helmfile -e default apply
```

📖 სრული დოკუმენტაცია: [docs/getting-started.md](https://github.com/opendesk-edu/opendesk-edu/blob/main/docs/getting-started.md)

---

# ქსელის კონფიგურაცია

- **Ingress კონტროლერი:** haproxy-ingress
- **Reverse Proxy:** Traefik — HTTP/HTTPS ტერმინაცია 🔄
- **LoadBalancer:** MetalLB
- **ყველა Ingress** მიგრაცირებულია haproxy-ზე ✅

---

# Grafana დაშბორდი

![height:500px](media/grafana.png)

---

# განახლების პროცესი

```bash
# უახლესი რელიზების ჩატვირთვა
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# ცვლილებების გადახედვა
helmfile diff -e hrz

# განახლებების გაცემა
helmfile apply -e hrz

# დაბრუნება თუ საჭიროა
helmfile rollback -e hrz
```

- **კონტროლირებული განახლებები Helmfile-ით** 🔄
- **მარტივი დაბრუნების შესაძლებლობა** ↩️

---

# HRZ-განახლება: Ingress მიგრაცია

- **მიგრაცია:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (uniapps ბრენჩი)
  - ყველა Ingress მიგრაცირებულია haproxy-ზე ✅
- **Ingress კლასები:**
  - `ingressClassName: haproxy`
  - nginx სრულიად მოძველებულია
- **კონფიგურაცია:**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# HRZ-განახლება: ორმაგი სარეზერვო კოპირება

- **მიზნები:** რედუნდანტული სარეზერვო საცავი 🗄️
- **სტრატეგია:** S3-სთან თავსებადი restic backend-ით 🔄
  - პირველადი: `s3.example.org:9000/backup-primary`
  - მეორეული: `s3-backup.example.org:9000/backup-secondary`
- **გრაფიკი:** ყოველდღე 00:42, შემოწმება ყოველ კვირას, წაშლა კვირას ორშაბათს ⏰
- **შენახვა:** 14 დღე, ბოლო 5-ის შენახვა 📦

---

# ინსტიტუციური წინააღმდეგობები

- **იურიდიული განყოფილება** ⚖️
  - GDPR, AVV ხელშეკრულებები, ლიცენზიების შესაბამისობა
- **თანამშრომლების საბჭო** 👥
  - მომსახურების ხელშეკრულება, IT სისტემებზე თანასწორი მონაწილეობა
- **ადმინისტრაცია** 🏢
  - Microsoft-ის პრეფერენციები, ფორმატების თავსებადობა
- **აუცილებელი დოკუმენტები** 📄
  - DSFA, TCO გამოთვლა

---

# შემდეგი ნაბიჯები და რეკომენდაციები

1. პილოტური ოპერაციის დაწყება ▶️
2. ეტაპობრივი გაშვება (10 → 100 → 1000 მომხმარებელი) 👥
3. წარმოების სისტემებისგან წმინდა გამყოფი 🔗
4. შეფასება: სარგახის შემთხვევების კატეგორიზაცია სუვერენულობის მოთხოვებების მიხედვით ✅
5. ოპერაციული გუნდის ბიუჯეტი (არა მხოლოდ განხორციელებაზე) 💰

---

# 🤝 ჩაერთეთ

**დაგვეხმარეთ openDesk Edu-ის შექმნაში უნივერსიტეტებისთვის!**

- ⭐ **რეპოს ვარსკვლავი:** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu)
- 🧪 **ლოკალურად ტესტირება:** განათავსება Helmfile-ით და უკუპარი გამოხმარება
- 🐛 **პრობლემების რეპორტირება:** Issues შეცდომებისთვის ან ფუნქციების მოთხოვებისთვის
- 💻 **წვლილის შეტანა:** PR-ები მოსასლოდნელია — იხილეთ CONTRIBUTING.md

**ერთად შევქმნით სუვერენულ უნივერსიტეტულ პროგრამებს!** 🎓

---

# ტექნიკური რესურსები

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [Deployment-Guide](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [User-Import](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu:** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu) · საგანმანათლებლო გაფართოება უნივერსიტეტებისთვის
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s:** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **Cluster-ავტომატიზაცია:** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# ორგანიზაციური რესურსები

- **HBDI რეკომენდაცია (M365 შეფასება):**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **Hessischer Digitalpakt Hochschulen:**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT Open Source (ZenDiS):**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB (digitale-verwaltung.de):**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it_node.html)
- **ციფრული სუვერენულობა უნივერსიტეტებში:**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate-Werkstattgespräch:**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)
