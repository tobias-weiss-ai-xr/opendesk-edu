---
title: "扩展 Intercom 服务：呼吁 ZenDiS 与社区就共同开发模式达成共识"
date: "2026-06-27"
description: "我们如何扩展 openDesk 的 intercom 服务以支持 OpenCloud、SOGo 和 ILIAS，以及为什么我们强烈敦促 ZenDiS 和社区就共同开发模式建立正式共识。"
categories: ["工程", "社区", "开源"]
tags: ["intercom-service", "zendis", "opendesk", "扩展", "社区", "治理"]
author: "Tobias Weiß 和 openDesk Edu 贡献者"
---

# 扩展 Intercom 服务：呼吁 ZenDiS 与社区就共同开发模式达成共识

## 引言

**intercom 服务** (ICS) 是 openDesk 生态系统中一个小但关键的基础设施组件。它充当中间件，支持基于浏览器的跨应用程序通信——文件选择器、视频会议集成、应用程序间单点登录，以及门户导航。

当我们着手构建 **openDesk Edu** 时，我们发现上游 intercom 服务（由 Univention 维护，由 ZenDiS 部署）主要为 **openDesk CE**（社区版）设计，专注于 **Nextcloud、OX App Suite 和 Matrix** 作为主要集成。

对于 **openDesk Edu**，我们需要 **OpenCloud、SOGo 和 ILIAS** 的额外集成。这是我们扩展 intercom 服务的故事——以及我们就共同开发模式向 **ZenDiS 和社区** 发出正式共识呼吁。

## Intercom 服务：它的功能

intercom 服务是一个轻量级的代理/代理程序，在浏览器上下文中运行。它使应用程序能够：

- **文件选择器**：在其他应用程序中从 Nextcloud/OpenCloud 打开文件
- **静默登录**：在应用程序之间传递 OIDC 令牌，无需用户交互
- **门户导航**：从 Univention 门户获取中央导航菜单
- **视频会议集成**：从其他应用程序创建 BBB/Jitsi 会议室
- **反向通道注销**：协调 OIDC 会话终止

## 我们的扩展

在 openDesk Edu 分支中，我们添加了：

1. **OpenCloud 支持** (`/oc/` 路由)
2. **SOGo Groupware 支持** (`/sogo/` 路由)
3. **ILIAS LMS 支持** (`/ilias/` 路由)
4. **标准 Node.js 基础镜像** (2GB → 150MB)
5. **`opendesk_username` 作为默认声明**
6. **健康检查端点** (`/health`)

## 问题：代码库分化

**我们的分支正在与上游分化。** 每次 ZenDiS 更新时，我们都面临不可能的选择：合并上游（失去我们的更改）或留在我们的分支上（积累技术债务）。

## 我们的呼吁：正式的 ZenDiS-社区共识

我们提出 **7 项具体措施**：

1. **贡献者许可协议（CLA）** - 轻量级法律基础
2. **通用、可插拔的架构** - 插件系统代替硬编码处理程序
3. **通用配置模式** - 统一的 YAML 语法
4. **多变体测试的 CI/CD** - 测试超出 CE
5. **定期社区通话** - 每月会议
6. **公开路线图** - 透明规划
7. **清晰的贡献路径** - 文档化流程

## 为什么这对数字主权很重要

openDesk 平台是德国联邦政府的一项 **战略举措**。分裂成不兼容的分支会损害：

- 政府机构之间的 **互操作性**
- 平台的 **可维护性**
- 公共管理员的 **采用**
- **成本**（每个分支都需要自己的团队）

**正式的共识对于 openDesk 作为主权平台的长期成功至关重要。**

## 我们在等待期间做什么

1. **开源我们的分支** 在 GitHub 上
2. **向上游提交 PR** 以获取有用的更改
3. **清楚地记录我们的更改** 在 README 中
4. **保持兼容性** 保留所有上游路由
5. **回馈改进** 如标准 Node.js 基础镜像

**我们想合并回去。但我们需要一个流程来使这成为可能。**

## 给 ZenDiS 的具体提案

**第一步：**
1. 打开 GitHub issue："RFC: Multi-variant intercom-service development"
2. 邀请维护者参加启动通话
3. 建立贡献指南工作组
4. 发布 CLA 模板
5. 使 intercom 服务更加模块化

**球在 ZenDiS 那边。**

---

**关于作者**：本文由 openDesk Edu 社区撰写。openDesk Edu 是为德国教育机构部署的 25 个集成开源服务的生产部署，总部位于 HRZ Marburg。请参阅 [opendesk-edu.org](https://opendesk-edu.org) 了解更多信息。

**许可证**：本文采用 Apache-2.0 许可证。
