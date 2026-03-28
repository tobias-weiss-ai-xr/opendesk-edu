---
marp: true
theme: default
paginate: true
---

<!-- _class: lead -->

# openDesk: 舒适与主权兼得？

🎓 openDesk Edu — 高校数字主权

Chemnitzer Linux-Tage 2026 · 28.03.2026

Tobias Weiß · HRZ Zentrale Systeme · Universität Marburg · [https://mastodon.social/@graphwiz_ai](https://mastodon.social/@graphwiz_ai)

---

# 数字主权 — 四大支柱

- **基础设施主权** 🖥️
  自主运营服务器和网络
- **数据主权** 💾
  掌控数据存储与访问
- **软件主权** 💻
  无供应商绑定的开源软件
- **运营主权** 🔧
  完全掌控更新与维护

---

# 什么是 openDesk？

- **M365 和 Google Workspace 的开源替代方案** 🐧
- **由政府机构为政府机构设计（BMI / ZenDiS）** 🏛️
- **BSI 认证（德国主权标准）** 📜
- **云原生：基于 Kubernetes 的工作空间** ☁️
- **模块化组件：**
  - 聊天、文件、Wiki、项目管理
  - 电子邮件、图表、网络办公、视频
- **自托管或 SaaS** 🖥️

---

# 组件概览

| 组件 | 软件 |
|------------|----------|
| 聊天 💬 | Element / Synapse |
| 文件 ☁️ | Nextcloud |
| Wiki 📖 | XWiki |
| 项目 ✅ | OpenProject |
| 电子邮件 ✉️ | OX App Suite |
| 图表 📊 | CryptPad |
| 网络办公 📄 | Collabora |
| 视频 📹 | Jitsi |

---

# openDesk 项目统计

**开发** 🔀              | **社区** 👥
-------------------------------|---------------------------
开始时间：2023年7月                | 贡献者：~ 70
运行时间：~ 3年           | 组织：~ 27
提交次数：~ 1.500                |
发布版本：~ 150                 |

**OpenCode.de** 🛡️              | **供应链** 🔒
BMI资助平台        | 签名容器镜像
主权云基础设施   | 所有组件的SBOM

---

# 基础设施概览

| 指标 | 值 |
|--------|------|
| **节点** | 9（3个控制平面 + 6个工作节点） |
| **发行版** | K3s v1.32.3 |
| **操作系统** | Debian 12 |
| **CPU（最低）** | 16核 |
| **内存（最低）** | 64 GB |
| **存储** | 4+ TB Ceph |

---

# 使用 Proxmox 虚拟化

![height:500px](media/proxmox.png)

---

# Helmfile & HRZ 环境

```bash
# 使用 Helmfile 部署
helmfile apply -e hrz
```

- **Helmfile 编排** ⚓
  - 声明式配置在 `helmfile_generic.yaml.gotmpl`
  - 环境特定覆盖在 `environments/hrz/`
  - 自动备份依赖项
- **HRZ 环境创建** 🖥️
  - 从 `staging` 复制并调整
  - 马堡大学特定配置
  - 试点运行测试系统

---

# 本地 Chart 开发

```bash
# 本地克隆/拉取 Charts
python3 dev/charts-local.py --match intercom
python3 dev/charts-local.py --revert
```

- **本地 Chart 开发与测试** 💻
- **克隆/拉取到 charts-<branch>/** ⬇️
- **Helmfile 引用本地路径** 📄
- **使用 --revert 备份与恢复** ↩️

---

# 用户导入：配置

- **UDM REST API** — CSV/ODS导入，LDAP组 👤
- **账户链接** — SAML身份验证链接 🔗
- **演示模式** — 测试账户，个人资料图片 🖼️

---

# 用户导入：注销

**两阶段注销工作流：**

- **阶段1：禁用用户**
  - IAM API → UCS 禁用 → 时间戳在描述中
  - Keycloak：删除 SAML 并解除组
- **阶段2：删除用户**
  - 宽限期（6个月） → 永久删除
  - 输出：`deprovisioned-*`, `deleted-*`

---

# 🎓 openDesk Edu — 概览

- **面向高校的 openDesk CE 扩展** 🏫
- **新组件：**
  - 学习管理系统（ILIAS、Moodle）
  - 教学视频会议（BigBlueButton）
  - 替代文件同步（OpenCloud）
- **全部集成 Keycloak SSO** 🔐
- **使用 `helmfile apply` 一键部署** ⚡

**GitHub:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu)

---

# 📚 教育组件

| 组件 | 状态 | 描述 |
|------------|--------|--------------|
| 📖 ILIAS | ✅ 稳定 | 带 SAML SSO 的 LMS — 课程、SCORM、测试 |
| 📖 Moodle | 🔄 Beta | 带 Shibboleth 的 LMS — 插件、成绩簿 |
| 🎥 BigBlueButton | 🔄 Beta | 教学视频会议 — 录制、白板 |
| ☁️ OpenCloud | 🔄 Beta | 基于 CS3 的文件同步 — Nextcloud 替代方案 |

---

# 🔐 ILIAS SSO — 架构

<table>
<tr>
<td width="50%">

![width:100%](media/opendesk-edu-ilias-integration.gif)

</td>
<td width="50%">

**6 步 SSO 流程：**

1. 🖥️ 门户 → ILIAS 图块
2. 🔄 ILIAS → Shibboleth SP
3. 🔑 Keycloak → 校园 IdP
4. 🎓 登录 (weblogin.uni-marburg.de)
5. 📨 返回 SAML 断言
6. ✅ ILIAS 仪表板

**技术栈:** Apache + Shibboleth SP + Keycloak Broker

</td>
</tr>
</table>

---

<div style="font-size: 0.85em;">

# 🔧 ILIAS 部署 — 经验教训

| 问题 | 解决方案 |
|---------|---------|
| `Wrong Login or Password` | attribute-map.xml 中缺少 SAML NameFormat |
| 属性名称错误 | 校园 IdP 发送 `givenname`/`surname` |
| `handlerSSL` → 404 | 内部 TLS：Apache SSL 在端口 8443（v5） |
| 账户被禁用 | `shib_activate_new = 0` |
| SAML 超时 | 60s → 300s |
| 健康检查 | CronJob：每小时 curl SSO 重定向 |

---

# 🚀 快速开始 — 3 步部署

```bash
# 1. 克隆仓库
git clone https://github.com/tobias-weiss-ai-xr/opendesk-edu.git
cd opendesk-edu

# 2. 配置环境
# 编辑 helmfile/environments/default/global.yaml.gotmpl
# 设置域名、邮件域和镜像仓库

# 3. 部署
helmfile -e default apply
```

📖 完整文档：[docs/getting-started.md](https://github.com/tobias-weiss-ai-xr/opendesk-edu/blob/main/docs/getting-started.md)

---

# 网络配置

- **Ingress 控制器:** haproxy-ingress
- **反向代理:** Traefik — HTTP/HTTPS 终止 🔄
- **负载均衡器:** MetalLB
- **所有 Ingress 已迁移至 haproxy** ✅

---

# Grafana 仪表板

![height:500px](media/grafana.png)

---

# 更新流程

```bash
# 拉取最新版本
git checkout -b myrelease upstream/tags/v1.12.2
git pull

# 检查变更
helmfile diff -e hrz

# 应用更新
helmfile apply -e hrz

# 必要时回滚
helmfile rollback -e hrz
```

- **通过 Helmfile 控制更新** 🔄
- **便捷回滚** ↩️

---

# HRZ 升级：Ingress 迁移

- **迁移:** nginx → haproxy-ingress 🔀
  - v1.11.2 → v1.13.x（uniapps 分支）
  - 所有 Ingress 已迁移至 haproxy ✅
- **Ingress 类：**
  - `ingressClassName: haproxy`
  - nginx 已完全弃用
- **配置：**
  - `replicaCount: 2`, LoadBalancer
  - `tune.bufsize: 65536`, `tune.http.maxhdr: 256`

---

# HRZ 升级：双重备份

- **目标:** 冗余备份存储 🗄️
- **策略:** S3 兼容，restic 后端 🔄
  - 主要：`s3.example.org:9000/backup-primary`
  - 辅助：`s3-backup.example.org:9000/backup-secondary`
- **计划:** 每天 00:42，每周检查，周日清理 ⏰
- **保留策略:** 14 天，保留最后 5 个 📦

---

# 制度性障碍

- **法律部门** ⚖️
  - GDPR、AVV 合同、许可证合规
- **人事委员会** 👥
  - 服务协议、IT 系统共同决定
- **管理部门** 🏢
  - Microsoft 偏好、格式兼容性
- **必需文件** 📄
  - DSFA、TCO 计算

---

# 下一步 & 建议

1. 启动试点运行 ▶️
2. 分阶段推广（10 → 100 → 1000 用户） 👥
3. 生产系统明确隔离 🔗
4. 评估：按主权要求分类用例 ✅
5. 规划运营团队预算（不仅仅是实施） 💰

---

# 🤝 参与贡献！

**帮助我们为高校构建 openDesk Edu！**

- ⭐ **收藏仓库:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu)
- 🧪 **本地测试:** 使用 Helmfile 部署并提供反馈
- 🐛 **报告问题:** 提交 bug 或功能请求
- 💻 **贡献代码:** 欢迎 PR — 详见 CONTRIBUTING.md

**共同构建主权高校软件！** 🎓

---

# 技术资源

- **openDesk:** [docs.opendesk.eu](https://docs.opendesk.eu) ·
  [部署指南](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/getting-started.md) ·
  [用户导入](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import)
- **openDesk Edu:** [github.com/tobias-weiss-ai-xr/opendesk-edu](https://github.com/tobias-weiss-ai-xr/opendesk-edu) · 面向高校的教育扩展
- **DFN-AAI:** [dfn.de/dienste/dfnaai/](https://www.dfn.de/dienste/dfnaai/)
- **K3s:** [docs.k3s.io](https://docs.k3s.io/)
- **Helmfile:** [helmfile.readthedocs.io](https://helmfile.readthedocs.io/)
- **集群自动化:** [Kubespray](https://github.com/kubernetes-sigs/kubespray) ·
  [k3s-ansible](https://github.com/timothystewart6/k3s-ansible)

---

# 组织资源

- **HBDI 推荐（M365 评估）：**
  [PDF](https://datenschutz.hessen.de/sites/datenschutz.hessen.de/files/2025-11/hbdi_bericht_m365_2025_11_15.pdf)
- **黑森州高校数字协议：**
  [PDF](https://wissenschaft.hessen.de/sites/wissenschaft.hessen.de/files/2025-12/hessischer_digitalpakt_hochschulen_2026-2031.pdf)
- **EVB-IT 开源（ZenDiS）：**
  [zendis.de](https://www.zendis.de/newsroom/presse/evb-it-open-source)
- **EVB-IT & BVB（digitale-verwaltung.de）：**
  [digitale-verwaltung.de](https://www.digitale-verwaltung.de/Webs/DV/DE/aktuelles-service/it-einkauf/evb-it-und-bvb/aktuelle_evb-it-node.html)
- **高校数字主权：**
  [PDF](https://tobias-weiss.org/downloads/digitale_souveraenitaet_an_hochschulen.pdf)
- **CoCreate 工作坊讨论：**
  [PDF](https://tobias-weiss.org/downloads/CoCreate-Werkstattgespraech-Digitale-Souveraenitaet_75dpi.pdf)