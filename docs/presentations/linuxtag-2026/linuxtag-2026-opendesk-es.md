---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

![width:900](media/readme-lead-image.svg)




# 🏛️ openDesk: ¿Cómodo y Soberano?

🎓 openDesk Edu — Soberanía Digital en las Universidades

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg

---

# Soberanía Digital — Los Cuatro Pilares

- **Soberanía de Infraestructura** 🖥️
  Operar servidores y redes de forma independiente
- **Soberanía de Datos** 💾
  Control sobre el almacenamiento y acceso a los datos
- **Soberanía de Software** 💻
  Software de código abierto sin dependencias propietarias
- **Soberanía Operativa** 🔧
  Control completo sobre actualizaciones y mantenimiento

---

# ¿Qué es openDesk?

- **Alternativa de código abierto** a M365 y Google Workspace 🐧
- **Por el Gobierno para el Gobierno** (BMI / ZenDiS) 🏛️
- **Certificado por el BSI** (soberanía alemana) 📜
- **Cloud-Native:** Entorno de trabajo basado en Kubernetes ☁️
- **Componentes Modulares:**
  - Chat, Archivos, Wiki, Gestión de proyectos
  - Correo, Diagramas, Oficina web, Vídeo
- **Autoalojado** o **SaaS** 🖥️

---

# Visión General de Componentes

| Componente | Software |
|------------|----------|
| Chat 💬 | Element / Synapse |
| Archivos ☁️ | Nextcloud |
| Wiki 📖 | XWiki |
| Proyecto ✅ | OpenProject |
| Correo ✉️ | OX App Suite |
| Diagramas 📊 | CryptPad |
| Oficina web 📄 | Collabora |
| Vídeo 📹 | Jitsi |

---

# Estadísticas del Proyecto openDesk

**Desarrollo** 🔀              | **Comunidad** 👥
--------------------------------|---------------------------
Inicio: Julio 2023                | Colaboradores: ~ 70
Duración: ~ 3 años           | Organizaciones: ~ 27
Commits: ~ 1,500                |
Releases: ~ 150                 |

**OpenCode.de** 🛡️              | **Cadena de Suministro** 🔒
Plataforma financiada por el BMI        | Imágenes de contenedor firmadas
Infraestructura de nube soberana   | SBOM para todos los componentes

---

# Visión General de la Infraestructura

| Métrica | Valor |
|--------|------|
| **Nodos** | 9 (3 Control-Plane + 6 Worker) |
| **Distribución** | K3s v1.32.3 |
| **SO** | Debian 12 |
| **CPU (Mínimo)** | 16 núcleos |
| **RAM (Mínimo)** | 64 GB |
| **Almacenamiento** | 4+ TB Ceph |

---

# Virtualización con Proxmox

![height:500px](media/proxmox.png)

---

# Helmfile y Entorno HRZ

```bash
# Despliegue con Helmfile
helmfile apply -e hrz
```

- **Orquestación con Helmfile** ⚓
  - Configuración declarativa en `helmfile_generic.yaml.gotmpl`
  - Anulaciones específicas del entorno en `environments/hrz/`
  - Copia de seguridad automática de dependencias
- **Entorno HRZ creado** 🖥️
  - Copia de `staging` con ajustes
  - Configuración específica de la Uni Marburg
  - Sistema de prueba para la operación piloto

---

# Desarrollo Local de Charts

```bash
# Clonar/actualizar charts localmente
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **Desarrollo y Prueba Local de Charts** 💻
- **Clonar/actualizar en charts-<branch>/** ⬇️
- **Referencias de Helmfile a rutas locales** 📄
- **Copia de seguridad y Reversión con --revert** ↩️

---

# Importación de Usuarios: Aprovisionamiento

- **UDM REST API** — Importación CSV/ODS, grupos LDAP 👤
- **Vinculación de Cuentas** — Vinculación de identidad SAML 🔗
- **Modo Demo** — Cuentas de prueba, fotos de perfil 🖼️

---

# Importación de Usuarios: Desaprovisionamiento

**Flujo de Trabajo de Desaprovisionamiento en Dos Fases:**

- **Fase 1: Deshabilitar Usuario**
  - IAM API → UCS Disable → Marca de tiempo en la Descripción
  - Keycloak: Eliminar SAML + disolver grupos
- **Fase 2: Eliminar Usuario**
  - Período de gracia (6 meses) → Eliminación permanente
  - Salida: `deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — Visión General

- **Extensión de openDesk CE** para universidades 🏫
- **Nuevos Componentes:**
  - Sistemas de Gestión del Aprendizaje (ILIAS, Moodle)
  - Videoconferencia para la Enseñanza (BigBlueButton)
  - Sincronización de Archivos Alternativa (OpenCloud)
- **Todo integrado con Keycloak SSO** 🔐
- **Desplegar todo con `helmfile apply`** ⚡

**GitHub:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment)

---

# 📚 Componentes Educativos

| Componente | Estado | Descripción |
|------------|--------|--------------|
| 📖 ILIAS | ✅ Estable | LMS con SSO SAML — Cursos, SCORM, Exámenes |
| 📖 Moodle | 🔄 Beta | LMS con Shibboleth — Plugins, Libro de calificaciones |
| 🎥 BigBlueButton | 🔄 Beta | Videoconferencia para la enseñanza — Grabación, Pizarra |
| ☁️ OpenCloud | 🔄 Beta | Sincronización de archivos basada en CS3 — Alternativa a Nextcloud |

---

# 🔐 SSO de ILIAS — Arquitectura

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**Flujo SSO en 6 Pasos:**

1. 🖥️ Portal → Icono de ILIAS
2. 🔄 ILIAS → Shibboleth SP
3. 🔑 Keycloak → Uni-IdP
4. 🎓 Inicio de sesión (weblogin.uni-marburg.de)
5. 📨 Aserción SAML de vuelta
6. ✅ Panel de ILIAS

**Stack:** Apache + Shibboleth SP + Keycloak Broker

</td>
</tr>
</table>

---

<div style="font-size: 0.65em;">

# 🔧 Despliegue de ILIAS — Lecciones Aprendidas

| Problema | Solución |
|---------|---------|
| `Wrong Login or Password` | NameFormat SAML ausente en attribute-map.xml |
| Nombres de atributos incorrectos | Uni-IdP envía `givenname`/`surname` |
| `handlerSSL` → 404 | TLS interno: Apache SSL en el puerto 8443 (v5) |
| Cuentas deshabilitadas | `shib_activate_new = 0` |
| SAML Timeout | 60s → 300s |
| Comprobación de Estado | CronJob: curl SSO-Redirect (cada hora) |

---

# 🚀 Inicio Rápido - Desplegar en 3 Pasos

```bash
# 1. Clonar el repositorio
git clone https://github.com/opendesk-edu/deployment.git
cd opendesk-edu

# 2. Configura tu entorno
# Edita helmfile/environments/default/global.yaml.gotmpl
# Establece tu dominio, dominio de correo y registro de imágenes

# 3. Desplegar
helmfile -e default apply
```

📖 Documentación completa: [docs/getting-started.md](https://github.com/opendesk-edu/deployment/blob/main/docs/getting-started.md)

---

# Configuración de Red

- **Ingress Controller:** haproxy-ingress
- **Proxy Inverso:** Traefik — Finalización HTTP/HTTPS 🔄
- **LoadBalancer:** MetalLB
- **Todos los Ingress migrados a haproxy** ✅

---

# Panel de Grafana

![height:500px](media/grafana.png)

---

# Proceso de Actualización

```bash
# Cargar las últimas versiones
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# Revisar cambios
helmfile diff -e hrz

# Aplicar actualizaciones
helmfile apply -e hrz

# Revertir si es necesario
helmfile rollback -e hrz
```

- **Actualizaciones controladas mediante Helmfile** 🔄
- **Capacidad de reversión sencilla** ↩️

---

# Actualización HRZ: Migración de Ingress

- **Migración:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x (rama uniapps)
  - Todos los Ingress migrados a haproxy ✅
- **Clases de Ingress:**
  - `ingressClassName: haproxy`
  - nginx completamente deprecado
- **Configuración:**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# Actualización HRZ: Copia de Seguridad Dual

- **Objetivos:** Almacenamiento de Copia de Seguridad Redundante 🗄️
- **Estrategia:** Compatible con S3 con backend restic 🔄
  - Primario: `s3.example.org:9000/backup-primary`
  - Secundario: `s3-backup.example.org:9000/backup-secondary`
- **Programación:** Diario a las 00:42, Revisión semanal, Limpieza los domingos ⏰
- **Retención:** 14 Diarios, Mantener los últimos 5 📦

---

# Obstáculos Institucionales

- **Departamento Jurídico** ⚖️
  - RGPD, contratos AVV, Cumplimiento de licencias
- **Consejo de Personal** 👥
  - Acuerdo de servicio, Co-determinación para sistemas TI
- **Administración** 🏢
  - Preferencias por Microsoft, Compatibilidad de formatos
- **Documentos Requeridos** 📄
  - DSFA, Cálculo de TCO

---

# Próximos Pasos y Recomendaciones

1. Iniciar la operación piloto ▶️
2. Despliegue escalonado (10 → 100 → 1000 usuarios) 👥
3. Separación clara de los sistemas de producción 🔗
4. Evaluación: Categorizar los casos de uso según los requisitos de soberanía ✅
5. Presupuesto para el equipo de operaciones (no solo la implementación) 💰

---

# 🤝 ¡Participa!

**¡Ayúdanos a construir openDesk Edu para las universidades!**

- ⭐ **Dale una estrella al repo:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment)
- 🧪 **Prueba localmente:** Despliega con Helmfile y proporciona retroalimentación
- 🐛 **Reporta problemas:** Issues para errores o solicitudes de funcionalidades
- 💻 **Contribuye:** PRs bienvenidos — consulta CONTRIBUTING.md

**¡Construyamos software universitario soberano juntos!** 🎓

---

# Recursos Técnicos

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [Guía de Despliegue](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [Importación de Usuarios](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu:** [github.com/opendesk-edu/deployment](https://github.com/opendesk-edu/deployment) · Extensión educativa para universidades
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s:** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **Automatización de Clústeres:** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# Recursos Organizativos

- **Recomendación HBDI (Evaluación M365):**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **Hessischer Digitalpakt Hochschulen:**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT Open Source (ZenDiS):**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB (digitale-verwaltung.de):**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it-node.html)
- **Soberanía Digital en las Universidades:**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate-Werkstattgespräch:**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)
