---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

![width:900](media/readme-lead-image.svg)

# 🏛️ openDesk: Confortable et Souverain ?

🎓 openDesk Edu — Souveraineté Numérique dans les Universités

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg

---

# Souveraineté Numérique — Les Quatre Piliers

- **Souveraineté Infrastructurelle** 🖥️
  Exploitation autonome de serveurs et réseaux
- **Souveraineté des Données** 💾
  Contrôle du stockage et des accès aux données
- **Souveraineté Logicielle** 💻
  Logiciels open source sans dépendances propriétaires
- **Souveraineté Opérationnelle** 🔧
  Contrôle total des mises à jour et de la maintenance

---

# Qu'est-ce qu'openDesk ?

- **Alternative open source** à M365 et Google Workspace 🐧
- **Par le gouvernement pour le gouvernement** (BMI / ZenDiS) 🏛️
- **Certifié BSI** (souveraineté allemande) 📜
- **Cloud-Native :** Espace de travail basé sur Kubernetes ☁️
- **Composants Modulaires :**
  - Chat, Fichiers, Wiki, Gestion de projet
  - E-mail, Diagrammes, Suite bureautique web, Vidéo
- **Auto-hébergé** ou **SaaS** 🖥️

---

# Vue d'ensemble des composants

| Composant | Logiciel |
|------------|----------|
| Chat 💬 | Element / Synapse |
| Fichiers ☁️ | Nextcloud |
| Wiki 📖 | XWiki |
| Projet ✅ | OpenProject |
| E-mail ✉️ | OX App Suite |
| Diagrammes 📊 | CryptPad |
| Suite bureautique web 📄 | Collabora |
| Vidéo 📹 | Jitsi |

---

# Statistiques du projet openDesk

**Développement** 🔀              | **Communauté** 👥
--------------------------------|---------------------------
Début : Juillet 2023                | Contributeurs : ~ 70
Durée : ~ 3 ans           | Organisations : ~ 27
Commits : ~ 1 500                |
Versions : ~ 150                 |

**OpenCode.de** 🛡️              | **Chaîne d'approvisionnement** 🔒
Plateforme financée par le BMI        | Images conteneurs signées
Infrastructure cloud souveraine   | SBOM pour tous les composants

---

# Vue d'ensemble de l'infrastructure

| Métrique | Valeur |
|--------|------|
| **Nœuds** | 9 (3 Control-Plane + 6 Worker) |
| **Distribution** | K3s v1.32.3 |
| **OS** | Debian 12 |
| **CPU (Minimum)** | 16 cœurs |
| **RAM (Minimum)** | 64 Go |
| **Stockage** | 4+ To Ceph |

---

# Virtualisation avec Proxmox

![height:500px](media/proxmox.png)

---

# Helmfile & Environnement HRZ

```bash
# Déploiement avec Helmfile
helmfile apply -e hrz
```

- **Orchestration Helmfile** ⚓
  - Configuration déclarative dans `helmfile_generic.yaml.gotmpl`
  - Surcharges spécifiques à l'environnement dans `environments/hrz/`
  - Sauvegarde automatique des dépendances
- **Environnement HRZ créé** 🖥️
  - Copie de `staging` avec adaptations
  - Configuration spécifique à l'Université de Marburg
  - Système de test pour le pilotage

---

# Développement local de Charts

```bash
# Cloner/récupérer les Charts localement
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **Développement et test locaux de Charts** 💻
- **Clone/récupération dans charts-<branch>/** ⬇️
- **Références Helmfile vers les chemins locaux** 📄
- **Sauvegarde et restauration avec --revert** ↩️

---

# Import d'utilisateurs : Provisionnement

- **API REST UDM** — Import CSV/ODS, groupes LDAP 👤
- **Liaison de comptes** — Liaison d'identité SAML 🔗
- **Mode démo** — Comptes de test, photos de profil 🖼️

---

# Import d'utilisateurs : Déprovisionnement

**Workflow de déprovisionnement en deux phases :**

- **Phase 1 : Désactiver l'utilisateur**
  - API IAM → UCS Disable → Horodatage dans la description
  - Keycloak : Supprimer SAML + dissoudre les groupes
- **Phase 2 : Supprimer l'utilisateur**
  - Délai de grâce (6 mois) → Suppression définitive
  - Sortie : `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — Vue d'ensemble

- **Extension d'openDesk CE** pour les universités 🏫
- **Nouveaux composants :**
  - Plates-formes d'apprentissage (ILIAS, Moodle)
  - Visioconférence pour l'enseignement (BigBlueButton)
  - Synchronisation de fichiers alternative (OpenCloud)
- **Tous intégrés avec Keycloak SSO** 🔐
- **Tout déployer avec `helmfile apply`** ⚡

**GitHub :** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu)

---

# 📚 Composants éducatifs

| Composant | Statut | Description |
|------------|--------|--------------|
| 📖 ILIAS | ✅ Stable | LMS avec SAML SSO — Cours, SCORM, Tests |
| 📖 Moodle | 🔄 Beta | LMS avec Shibboleth — Plugins, Carnet de notes |
| 🎥 BigBlueButton | 🔄 Beta | Visioconférence pour l'enseignement — Enregistrement, Tableau blanc |
| ☁️ OpenCloud | 🔄 Beta | Synchronisation de fichiers basée sur CS3 — Alternative à Nextcloud |

---

# 🔐 ILIAS SSO — Architecture

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**Flux SSO en 6 étapes :**

1. 🖥️ Portail → Tuile ILIAS
2. 🔄 ILIAS → Shibboleth SP
3. 🔑 Keycloak → Uni-IdP
4. 🎓 Connexion (weblogin.uni-marburg.de)
5. 📨 Assertion SAML retour
6. ✅ Tableau de bord ILIAS

**Stack :** Apache + Shibboleth SP + Keycloak Broker

</td>
</tr>
</table>

---

<div style="font-size: 0.65em;">

# 🔐 Déploiement ILIAS — Leçons apprises

| Problème | Solution |
|---------|---------|
| `Wrong Login or Password` | SAML NameFormat manquant dans attribute-map.xml |
| Noms d'attributs incorrects | Uni-IdP envoie `givenname`/`surname` |
| `handlerSSL` → 404 | TLS interne : Apache SSL sur le port 8443 (v5) |
| Comptes désactivés | `shib_activate_new = 0` |
| Délai d'attente SAML | 60 s → 300 s |
| Contrôle de santé | CronJob : curl SSO-Redirect (horaire) |

---

# 🚀 Démarrage rapide — Déploiement en 3 étapes

```bash
# 1. Cloner le dépôt
git clone https://github.com/opendesk-edu/opendesk-edu.git
cd opendesk-edu

# 2. Configurer votre environnement
# Modifier helmfile/environments/default/global.yaml.gotmpl
# Définir votre domaine, domaine de messagerie et registre d'images

# 3. Déployer
helmfile -e default apply
```

📖 Documentation complète : [docs/getting-started.md](https://github.com/opendesk-edu/opendesk-edu/blob/main/docs/getting-started.md)

---

# Configuration réseau

- **Contrôleur d'Ingress :** haproxy-ingress
- **Proxy inverse :** Traefik — Terminaison HTTP/HTTPS 🔄
- **Répartiteur de charge :** MetalLB
- **Tous les Ingress** migrés vers haproxy ✅

---

# Tableau de bord Grafana

![height:500px](media/grafana.png)

---

# Processus de mise à jour

```bash
# Charger les dernières versions
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# Vérifier les modifications
helmfile diff -e hrz

# Appliquer les mises à jour
helmfile apply -e hrz

# Retour en arrière si nécessaire
helmfile rollback -e hrz
```

- **Mises à jour contrôlées via Helmfile** 🔄
- **Possibilité de retour en arrière simple** ↩️

---

# HRZ-Upgrade : Migration Ingress

- **Migration :** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (branche uniapps)
  - Tous les Ingress migrés vers haproxy ✅
- **Classes Ingress :**
  - `ingressClassName: haproxy`
  - nginx entièrement déprécié
- **Configuration :**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# HRZ-Upgrade : Sauvegarde duale

- **Objectifs :** Stockage de sauvegarde redondant 🗄️
- **Stratégie :** Compatible S3 avec backend restic 🔄
  - Primaire : `s3.example.org:9000/backup-primary`
  - Secondaire : `s3-backup.example.org:9000/backup-secondary`
- **Planification :** Quotidien à 00 h 42, Vérification hebdomadaire, Purge le dimanche ⏰
- **Rétention :** 14 quotidiens, Conserver les 5 derniers 📦

---

# Obstacles institutionnels

- **Service juridique** ⚖️
  - RGPD, contrats AVV, Conformité des licences
- **Comité du personnel** 👥
  - Convention de service, Codétermination pour les systèmes IT
- **Administration** 🏢
  - Préférences Microsoft, Compatibilité des formats
- **Documents requis** 📄
  - DSFA, Calcul TCO

---

# Prochaines étapes & Recommandations

1. Lancer le pilotage ▶️
2. Déploiement progressif (10 → 100 → 1 000 utilisateurs) 👥
3. Séparation nette des systèmes de production 🔗
4. Évaluation : Catégoriser les cas d'usage selon les exigences de souveraineté ✅
5. Budgétiser une équipe d'exploitation (pas seulement l'implémentation) 💰

---

# 🤝 Participez

**Aidez-nous à construire openDesk Edu pour les universités !**

- ⭐ **Étoiler le dépôt :** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu)
- 🧪 **Tester localement :** Déployer avec Helmfile et fournir des retours
- 🐛 **Signaler des problèmes :** Issues pour les bugs ou demandes de fonctionnalités
- 💻 **Contribuer :** PRs bienvenus — voir CONTRIBUTING.md

**Construisons ensemble un logiciel souverain pour les universités !** 🎓

---

# Ressources techniques

- **openDesk :** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [Guide de déploiement](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [Import d'utilisateurs](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu :** [github.com/opendesk-edu/opendesk-edu](https://github.com/opendesk-edu/opendesk-edu) · Extension éducative pour les universités
- **DFN-AAI :** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s :** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile :** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **Automatisation de cluster :** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# Ressources organisationnelles

- **Recommandation HBDI (Évaluation M365) :**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **Pacte numérique hessois pour l'enseignement supérieur :**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT Open Source (ZenDiS) :**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB (digitale-verwaltung.de) :**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it-node.html)
- **Souveraineté numérique dans les universités :**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate-Werkstattgespräch :**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)
