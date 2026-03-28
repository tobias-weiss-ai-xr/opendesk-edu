---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

# openDesk: Confortável e Soberano?

🎓 openDesk Edu — Soberania Digital nas Universidades

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg · [https://mastodon.social/@graphwiz_ai](https://mastodon.social/@graphwiz_ai)

---

# Soberania Digital — Os Quatro Pilares

- **Soberania de Infraestrutura** 🖥️
  Operar servidores e redes de forma independente
- **Soberania de Dados** 💾
  Controlo sobre o armazenamento e acesso aos dados
- **Soberania de Software** 💻
  Software de código aberto sem dependências proprietárias
- **Soberania Operacional** 🔧
  Controlo completo sobre atualizações e manutenção

---

# O que é openDesk?

- **Alternativa de código aberto** a M365 e Google Workspace 🐧
- **Pelo Governo para o Governo** (BMI / ZenDiS) 🏛️
- **Certificado pelo BSI** (soberania alemã) 📜
- **Cloud-Native:** Ambiente de trabalho baseado em Kubernetes ☁️
- **Componentes Modulares:**
  - Chat, Ficheiros, Wiki, Gestão de projetos
  - Correio eletrónico, Diagramas, Escritório web, Vídeo
- **Self-Hosted** ou **SaaS** 🖥️

---

# Visão Geral de Componentes

| Componente | Software |
|------------|----------|
| Chat 💬 | Element / Synapse |
| Ficheiros ☁️ | Nextcloud |
| Wiki 📖 | XWiki |
| Projeto ✅ | OpenProject |
| Correio eletrónico ✉️ | OX App Suite |
| Diagramas 📊 | CryptPad |
| Escritório web 📄 | Collabora |
| Vídeo 📹 | Jitsi |

---

# Estatísticas do Projeto openDesk

**Desenvolvimento** 🔀              | **Comunidade** 👥
--------------------------------|---------------------------
Início: Julho 2023                | Contribuidores: ~ 70
Duração: ~ 3 anos           | Organizações: ~ 27
Commits: ~ 1,500                |
Releases: ~ 150                 |

**OpenCode.de** 🛡️              | **Cadeia de Suprimentos** 🔒
Plataforma financiada pelo BMI        | Imagens de contentor assinadas
Infraestrutura de nuvem soberana   | SBOM para todos os componentes

---

# Visão Geral da Infraestrutura

| Métrica | Valor |
|--------|------|
| **Nós** | 9 (3 Control-Plane + 6 Worker) |
| **Distribuição** | K3s v1.32.3 |
| **SO** | Debian 12 |
| **CPU (Mínimo)** | 16 núcleos |
| **RAM (Mínimo)** | 64 GB |
| **Armazenamento** | 4+ TB Ceph |

---

# Virtualização com Proxmox

![height:500px](media/proxmox.png)

---

# Helmfile e Ambiente HRZ

```bash
# Implantação com Helmfile
helmfile apply -e hrz
```

- **Orquestração com Helmfile** ⚓
  - Configuração declarativa em `helmfile_generic.yaml.gotmpl`
  - Sobrescritas específicas do ambiente em `environments/hrz/`
  - Cópia de segurança automática de dependências
- **Ambiente HRZ criado** 🖥️
  - Cópia de `staging` com ajustes
  - Configuração específica da Uni Marburg
  - Sistema de teste para a operação piloto

---

# Desenvolvimento Local de Charts

```bash
# Clonar/puxar charts localmente
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **Desenvolvimento e Teste Local de Charts** 💻
- **Clonar/puxar em charts-<branch>/** ⬇️
- **Referências de Helmfile para caminhos locais** 📄
- **Cópia de segurança e Reversão com --revert** ↩️

---

# Importação de Utilizadores: Provisionamento

- **UDM REST API** — Importação CSV/ODS, grupos LDAP 👤
- **Vinculação de Contas** — Vinculação de identidade SAML 🔗
- **Modo Demo** — Contas de teste, fotos de perfil 🖼️

---

# Importação de Utilizadores: Desprovisionamento

**Fluxo de Trabalho de Desprovisionamento em Duas Fases:**

- **Fase 1: Desativar Utilizador**
  - IAM API → UCS Disable → Carimbo de data/hora na Descrição
  - Keycloak: Remover SAML + dissolver grupos
- **Fase 2: Eliminar Utilizador**
  - Período de carência (6 meses) → Eliminação permanente
  - Saída: `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — Visão Geral

- **Extensão do openDesk CE** para universidades 🏫
- **Novos Componentes:**
  - Sistemas de Gestão da Aprendizagem (ILIAS, Moodle)
  - Videoconferência para o Ensino (BigBlueButton)
  - Sincronização de Ficheiros Alternativa (OpenCloud)
- **Tudo integrado com Keycloak SSO** 🔐
- **Implantar tudo com `helmfile apply`** ⚡

**GitHub:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu)

---

# 📚 Componentes Educacionais

| Componente | Estado | Descrição |
|------------|--------|--------------|
| 📖 ILIAS | ✅ Estável | LMS com SSO SAML — Cursos, SCORM, Testes |
| 📖 Moodle | 🔄 Beta | LMS com Shibboleth — Plugins, Caderno de notas |
| 🎥 BigBlueButton | 🔄 Beta | Videoconferência para o ensino — Gravação, Quadro branco |
| ☁️ OpenCloud | 🔄 Beta | Sincronização de ficheiros baseada em CS3 — Alternativa ao Nextcloud |

---

# 🔐 SSO do ILIAS — Arquitetura

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**Fluxo SSO em 6 Passos:**

1. 🖥️ Portal → Mosaico do ILIAS
2. 🔄 ILIAS → Shibboleth SP
3. 🔑 Keycloak → Uni-IdP
4. 🎓 Início de sessão (weblogin.uni-marburg.de)
5. 📨 Asserção SAML de volta
6. ✅ Painel do ILIAS

**Stack:** Apache + Shibboleth SP + Keycloak Broker

</td>
</tr>
</table>

---

<div style="font-size: 0.85em;">

# 🔧 Implantação do ILIAS — Lições Aprendidas

| Problema | Solução |
|---------|---------|
| `Wrong Login or Password` | NameFormat SAML em falta em attribute-map.xml |
| Nomes de atributos incorretos | Uni-IdP envia `givenname`/`surname` |
| `handlerSSL` → 404 | TLS interno: Apache SSL na porta 8443 (v5) |
| Contas desativadas | `shib_activate_new = 0` |
| SAML Timeout | 60s → 300s |
| Verificação de Estado | CronJob: curl SSO-Redirect (de hora em hora) |

---

# 🚀 Início Rápido - Implantar em 3 Passos

```bash
# 1. Clonar o repositório
git clone https://github.com/tobias-weiss-ai-xr/opendesk-edu.git
cd opendesk-edu

# 2. Configure o seu ambiente
# Edite helmfile/environments/default/global.yaml.gotmpl
# Defina o seu domínio, domínio de correio e registro de imagens

# 3. Implantar
helmfile -e default apply
```

📖 Documentação completa: [docs/getting-started.md](https://github.com/tobias-weiss-ai-xr/opendesk-edu/blob/main/docs/getting-started.md)

---

# Configuração de Rede

- **Ingress Controller:** haproxy-ingress
- **Proxy Reverso:** Traefik — Terminação HTTP/HTTPS 🔄
- **LoadBalancer:** MetalLB
- **Todos os Ingress migrados para haproxy** ✅

---

# Painel do Grafana

![height:500px](media/grafana.png)

---

# Processo de Atualização

```bash
# Carregar as últimas versões
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# Revisar alterações
helmfile diff -e hrz

# Aplicar atualizações
helmfile apply -e hrz

# Reverter se necessário
helmfile rollback -e hrz
```

- **Atualizações controladas via Helmfile** 🔄
- **Capacidade de reversão fácil** ↩️

---

# Atualização HRZ: Migração de Ingress

- **Migração:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (ramo uniapps)
  - Todos os Ingress migrados para haproxy ✅
- **Classes de Ingress:**
  - `ingressClassName: haproxy`
  - nginx totalmente descontinuado
- **Configuração:**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# Atualização HRZ: Cópia de Segurança Dual

- **Objetivos:** Armazenamento de Cópia de Segurança Redundante 🗄️
- **Estratégia:** Compatível com S3 com backend restic 🔄
  - Primário: `s3.example.org:9000/backup-primary`
  - Secundário: `s3-backup.example.org:9000/backup-secondary`
- **Programação:** Diariamente às 00:42, Verificação semanal, Poda aos domingos ⏰
- **Retenção:** 14 Diários, Manter os últimos 5 📦

---

# Obstáculos Institucionais

- **Departamento Jurídico** ⚖️
  - RGPD, contratos AVV, Conformidade de licenças
- **Conselho de Pessoal** 👥
  - Acordo de serviço, Co-determinação para sistemas de TI
- **Administração** 🏢
  - Preferências pela Microsoft, Compatibilidade de formatos
- **Documentos Necessários** 📄
  - DSFA, Cálculo de TCO

---

# Próximos Passos e Recomendações

1. Iniciar a operação piloto ▶️
2. Implantação escalonada (10 → 100 → 1000 utilizadores) 👥
3. Separação clara dos sistemas de produção 🔗
4. Avaliação: Categorizar os casos de uso por requisitos de soberania ✅
5. Orçamento para a equipa de operações (não apenas a implementação) 💰

---

# 🤝 Participe!

**Ajude-nos a construir o openDesk Edu para as universidades!**

- ⭐ **Dê uma estrela ao repositório:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu)
- 🧪 **Teste localmente:** Implante com Helmfile e forneça feedback
- 🐛 **Reporte problemas:** Issues para bugs ou pedidos de funcionalidades
- 💻 **Contribua:** PRs bem-vindos — consulte CONTRIBUTING.md

**Vamos construir software universitário soberano juntos!** 🎓

---

# Recursos Técnicos

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [Guia de Implantação](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [Importação de Utilizadores](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu) · Extensão educacional para universidades
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s:** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **Automação de Clusters:** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# Recursos Organizacionais

- **Recomendação HBDI (Avaliação M365):**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **Hessischer Digitalpakt Hochschulen:**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT Open Source (ZenDiS):**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB (digitale-verwaltung.de):**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it-node.html)
- **Soberania Digital nas Universidades:**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate-Werkstattgespräch:**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)
