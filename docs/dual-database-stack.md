<!--
SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# Dual Database Stack Architecture / Duale Datenbank-Stack-Architektur

[English](#english) | [Deutsch](#deutsch)

---

<a name="english"></a>

## English

### Executive Summary

openDesk Edu uses a **dual database stack** architecture to support both PostgreSQL-based services (SOGo, most applications) and MariaDB-based services (Grommunio). This document explains the architecture, rationale, resource implications, and operational considerations.

---

### Why Dual Database Stack?

**TL;DR:** Different groupware solutions require different databases, and we want to give users choice without being locked into a single ecosystem.

#### Database Requirements by Service

| Service | Database | Rationale |
|---------|----------|-----------|
| **SOGo** | PostgreSQL | Native PostgreSQL support, mature ecosystem |
| **OX App Suite** | PostgreSQL/MariaDB | Enterprise PostgreSQL support |
| **Nextcloud** | PostgreSQL | Native and recommended |
| **Keycloak** | PostgreSQL | Supported and recommended |
| **ILIAS** | PostgreSQL | Supported and recommended |
| **Moodle** | PostgreSQL/MariaDB | Both supported |
| **Grommunio** | MariaDB/MySQL ONLY | **No PostgreSQL support** |

#### Why Not MariaDB-Only?

1. **SOGo**: No official MariaDB support
2. **Keycloak**: PostgreSQL is the recommended and battle-tested choice
3. **Nextcloud**: PostgreSQL offers better performance
4. **Ecosystem**: Most openDesk Edu tools prefer PostgreSQL

#### Why Not PostgreSQL-Only?

1. **Grommunio**: Hard requirement for MariaDB/MySQL - no PostgreSQL port exists
2. **ActiveSync**: Grommunio's excellent ActiveSync support requires MariaDB backend
3. **Mobile Priority**: Grommunio offers superior mobile sync capabilities

---

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                   openDesk Edu Kubernetes Cluster               │
│                                                                  │
│  ┌──────────────────────────────────────────────────────┐      │
│  │   Applications Layer                                   │      │
│  │                                                       │      │
│  │   ┌──────────┐  ┌──────────┐  ┌──────────┐         │      │
│  │   │ SOGo     │  │ Grommunio│  │ OX App   │         │      │
│  │   │ (PGSQL)  │  │ (MariaDB)│  │ (PGSQL)  │         │      │
│  │   └──────────┘  └──────────┘  └──────────┘         │      │
│  │                                                       │      │
│  │   ┌──────────┐  ┌──────────┐  ┌──────────┐         │      │
│  │   │ Keycloak │  │Nextcloud │  │ ILIAS    │         │      │
│  │   │ (PGSQL)  │  │ (PGSQL)  │  │ (PGSQL)  │         │      │
│  │   └──────────┘  └──────────┘  └──────────┘         │      │
│  └──────────────────────────────────────────────────────┘      │
│                            │                            │     │
│                            ▼                            │     │
│  ┌──────────────────────────────────────────────────────┐      │
│  │   Database Layer (Dual Stack)                        │      │
│  │                                                       │      │
│  │  ┌─────────────────────┐    ┌─────────────────────┐  │      │
│  │  │   PostgreSQL         │    │   MariaDB            │  │      │
│  │  │   (Primary Stack)    │    │   (Grommunio Stack)  │  │      │
│  │  │                     │    │                     │  │      │
│  │  │  - SOGo users        │    │  - Grommunio users  │  │      │
│  │  │  - Keycloak         │    │  - Email messages   │  │      │
│  │  │  - Nextcloud         │    │  - Calendar data    │  │      │
│  │  │  - ILIAS/Moodle     │    │  - Contacts         │  │      │
│  │  └─────────────────────┘    └─────────────────────┘  │      │
│  └──────────────────────────────────────────────────────┘      │
│                            │                            │     │
│                            ▼                            │     │
│  ┌──────────────────────────────────────────────────────┐      │
│  │   Shared Storage layer                                │      │
│  │                                                       │      │
│  │  ┌─────────────────────┐    ┌─────────────────────┐  │      │
│  │  │   Nextcloud Files    │    │   Redis Cluster      │  │      │
│  │  │   (Object Storage)   │    │   (Cache layer)      │  │      │
│  │  └─────────────────────┘    └─────────────────────┘  │      │
│  └──────────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────────┘
```

---

### Database Technologies

#### PostgreSQL (Primary Stack)

**Version:** 14+ (recommended: 14 or 15)

**Strengths:**

- Mature, battle-tested ecosystem
- Excellent for relational data and complex queries
- Strong ACID compliance
- Native JSON support
- Excellent performance for OLTP workloads
- Wide range of extensions (PostGIS, pg_trgm, etc.)

**Used by:**

- SOGo (webmail, calendar, contacts)
- Keycloak (identity management, SSO)
- Nextcloud (file storage metadata)
- ILIAS (learning management system)
- Moodle (learning management system)
- OX App Suite (groupware)
- Most openDesk Edu applications

#### MariaDB (Grommunio Stack)

**Version:** 10.11+ (recommended: 10.11 or 11.x)

**Strengths:**

- MySQL compatible and proven
- Designed for high-scale web applications
- Faster reads than PostgreSQL for simple queries
- Excellent replication capabilities
- Native support for JSON
- Popular in hosted email systems

**Used by:**

- Grommunio (groupware, email, calendar, contacts)
- User information and authentication
- Per-user email messages (SQLite databases)
- Message index (SQLite databases)

**Critical Note:** Grommunio stores per-user email messages and indexes in **separate SQLite databases** (not MariaDB tables). MariaDB is only used for user metadata and authentication.

---

### Resource Requirements

#### Memory Allocation

**Production Estimates (per 1000 users):**

| Database | Base Memory | Per 1000 Users | Total | Notes |
|----------|-------------|----------------|-------|-------|
| PostgreSQL | 2 GiB | +2 GiB | 4-8 GiB | 16-32 GiB for 5000+ users |
| MariaDB | 1 GiB | +1 GiB | 2-4 GiB | 8-16 GiB for 5000+ users |
| **Total** | **3 GiB** | **+3 GiB** | **6-12 GiB** | **24-48 GiB for 5000+ users** |

#### Storage Allocation

**Production Estimates (per 1000 users):**

| Database | Base Storage | Per 1000 Users | Per User | Retention |
|----------|--------------|----------------|----------|-----------|
| PostgreSQL | 50 GiB | +100 GiB | 100 MB | Indefinite |
| MariaDB | 10 GiB | +20 GiB | 20 MB | Indefinite |
| Grommunio SQLite (per user) | - | 100 GiB | 100 MB | 1 year |
| **Total** | **60 GiB** | **+220 GiB** | **220 MB** | **Varying** |

**Notes:**

- Grommunio stores email messages in per-user SQLite databases
- Archival policies can reduce storage over time
- Storage can be tiered (NVMe for hot data, HDD for archives)

---

### Operational Considerations

#### Backup Strategy

**PostgreSQL:**

```yaml
# Recommended backup tools
- pg_dump: Logical backups (small, portable)
- pgBackRest: Physical backups (fast, point-in-time recovery)
- k8up: Kubernetes-native restic integration
```

**MariaDB:**

```yaml
# Recommended backup tools
- mysqldump: Logical backups (compatible with MariaDB)
- Percona XtraBackup: Physical backups (fast, consistent)
- k8up: Kubernetes-native restic integration
```

**Grommunio SQLite:**

```yaml
# Per-user SQLite databases
- Location: /var/lib/grommunio/users/{username}/sqlite/
- Backup method: Rsync to backup storage + restic snapshots
- Frequency: Daily (or more frequent for active users)
- Retention: Configurable (default: 1 year)
```

#### High Availability

**PostgreSQL:**

- Patroni (recommended) or repmgr
- Quorum-based automatic failover
- Streaming replication with synchronous commits
- Load balancer: pgBouncer or HAProxy

**MariaDB:**

- Galera Cluster (recommended) or Master-Slave replication
- Synchronous replication for data consistency
- Automatic failover (MaxScale or ProxySQL)
- Load balancer: HAProxy or ProxySQL

#### Monitoring

**Metrics to Track:**

- Database connections per service
- Query latency (p50, p95, p99)
- Replication lag (for HA setups)
- Disk I/O and storage capacity
- Memory usage and cache hit ratios

**Tools:**

- Prometheus Operator (postgres-exporter, mysqld-exporter)
- Grafana dashboards
- Alertmanager alerts for replication lag, connection limits

---

### Security Considerations

#### Network Isolation

**Recommended Network Policies:**

```yaml
# PostgreSQL network
- Ingress: Keycloak, Nextcloud, SOGo, ILIAS, Moodle, OX
- Egress: Backups, monitoring
- Exposed to: Internal cluster only (never to internet)

# MariaDB network
- Ingress: Grommunio only (isolate segment)
- Egress: Backups, monitoring
- Exposed to: Internal cluster only (never to internet)

# Database-to-database: NO direct connections
```

#### Authentication

**PostgreSQL:**

- Use md5 or scram-sha-256 passwords
- SSL/TLS required for connections
- Separate database users for each service
- Least privilege principle

**MariaDB:**

- Use caching_sha2_password authentication
- SSL/TLS required for connections
- Separate database user for Grommunio
- No superuser access for applications

---

### Performance Optimization

#### PostgreSQL Optimization

**Query Performance:**

```sql
-- Recommended settings for production
shared_buffers = 25% of RAM
effective_cache_size = 50% of RAM
work_mem = 4MB (per connection)
maintenance_work_mem = 128MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
```

**Connection Pooling:**

- Use pgBouncer for connection pooling
- Pool size: 10-20 connections per service
- Transaction mode mode vs Session mode based on workload

#### MariaDB Optimization

**Query Performance:**

```sql
-- Recommended settings for production
innodb_buffer_pool_size = 50-70% of RAM
innodb_log_file_size = 256MB
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT
query_cache_size = 0 (disabled in MariaDB 10+)
```

**Connection Pooling:**

- Use ProxySQL or MaxScale for connection pooling
- Pool size: 10-15 connections per service
- Smart routing based on query type

---

### Migration Path

#### Existing Deployments (PostgreSQL-only)

**Scenario:** You're currently running SOGo with PostgreSQL and want to add Grommunio as an alternative.

**Steps:**

1. Deploy MariaDB alongside existing PostgreSQL
2. Install Grommunio Helm chart with MariaDB dependency
3. Configure Grommunio for OIDC authentication with existing Keycloak
4. Set up LDAP sync for user provisioning
5. Test with pilot users before full rollout
6. Gradually migrate users to Grommunio if they prefer it
7. Both 스택s run in parallel - no forced migration

**Advantages:**

- No downtime for PostgreSQL services
- Users can choose between SOGo and Grommunio
- Gradual migration approach
- Can rollback easily

#### Future: MariaDB-only Stack

**Scenario:** Future Grommunio improvements might encourage full MariaDB migration.

**Considerations:**

- SOGo doesn't support MariaDB effectively
- Would require alternative groupware (only Grommunio or OX)
- Reduces choice and flexibility
- Not recommended at this time

**Conclusion:** Dual stack is the practical choice for user choice.

---

### Troubleshooting

#### Common Issues

**Issue 1: High Memory Usage**

- **Symptom:** Node memory pressure, pod evictions
- **Cause:** PostgreSQL/MariaDB misconfigured for available RAM
- **Solution:** Adjust shared_buffers/effective_cache_size for PG, innodb_buffer_pool_size for MariaDB

**Issue 2: Slow Query Performance**

- **Symptom:** Grommunio or SOGo slow to load
- **Cause:** Missing indexes, connection pool exhausted
- **Solution:** Add indexes, increase pool size, check query plans

**Issue 3: Replication Lag**

- **Symptom:** Stale data on replicas
- **Cause:** Network bandwidth, high write volume
- **Solution:** Optimize queries, increase network, check commit consistency settings

**Issue 4: Storage Exhaustion**

- **Symptom:** Disk full, pod crashes
- **Cause:** Grommunio SQLite databases growing too large
- **Solution:** Implement archival policy, increase storage, add monitoring alerts

#### Debug Commands

**Check PostgreSQL Connections:**

```sql
SELECT count(*), state FROM pg_stat_activity GROUP BY state;
```

**Check MariaDB Connections:**

```sql
SHOW STATUS LIKE 'Threads_connected';
SHOW PROCESSLIST;
```

**Check Grommunio SQLite Size:**

```bash
du -sh /var/lib/grommunio/users/*/sqlite/
```

---

### Cost Analysis

**Additional Infrastructure Costs (vs PostgreSQL-only):**

| Infrastructure | PostgreSQL-only | Dual Stack | Additional |
|---------------|------------------|-----------|------------|
| RAM (per 1000 users) | 4-8 GiB | 6-12 GiB | +2-4 GiB (50%) |
| Storage (per 1000 users) | 150-250 GiB | 270-470 GiB | +120-220 GiB (80%) |
| CPU | 2-4 cores | 4-6 cores | +2 cores (50%) |
| Complexity | Low | Medium | HA setup, monitoring |

**Annual Cost Increase:**

- Cloud: +40-60% infrastructure cost
- Self-managed: +30-50% hardware cost
- Staff: +10-20% operational overhead (monitoring two stacks)

**ROI Justification:**

- User choice and flexibility = higher adoption
- Grommunio's ActiveSync support = mobile-first users
- Competitive advantage vs single-stack solutions
- Future-proof against vendor lock-in

---

### Best Practices

#### DO ✓

1. Deploy PostgreSQL and MariaDB on separate nodes if possible
2. Use dedicated storage classes for each database
3. Monitor both stacks with unified dashboards
4. Implement cross-stack monitoring alerts
5. Regular backups with validation
6. Test failover procedures quarterly

#### DON'T ✗

1. Don't run both databases on the same node in production
2. Don't share storage volumes between databases
3. Don't use root credentials for applications
4. Don't disable SSL/TLS for database connections
5. Don't forget to backup Grommunio SQLite databases
6. Don't ignore replication lag monitoring

---

### References

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [MariaDB Documentation](https://mariadb.com/kb/en/documentation/)
- [Grommunio Database Requirements](https://docs.grommunio.com/database/)
- [PostgreSQL Performance Tuning](https://wiki.postgresql.org/wiki/Performance_Optimization)
- [MariaDB Performance Tuning](https://mariadb.com/kb/en/optimization-and-tuning/)

---

<a name="deutsch"></a>

## Deutsch

### Zusammenfassung

openDesk Edu verwendet eine **Architektur mit zwei Datenbank-Stacks**, um sowohl PostgreSQL-basierte Services (SOGo, die meisten Anwendungen) als auch MariaDB-basierte Services (Grommunio) zu unterstützen. Dieses Dokument erklärt die Architektur, die Begründung, die Auswirkungen auf die Ressourcen und die betrieblichen Überlegungen.

---

### Warum zwei Datenbank-Stacks?

**Kurz gesagt:** Verschiedene Groupware-Lösungen benötigen verschiedene Datenbanken, und wir wollen Benutzern die Wahl ermöglichen, ohne in ein einziges Ökosystem gesperrt zu sein.

#### Datenbankanforderungen nach Service

| Service | Datenbank | Begründung |
|---------|----------|-----------|
| **SOGo** | PostgreSQL | Native PostgreSQL-Unterstützung, ausgereiftes Ökosystem |
| **OX App Suite** | PostgreSQL/MariaDB | Enterprise-PostgreSQL-Unterstützung |
| **Nextcloud** | PostgreSQL | Native und empfohlen |
| **Keycloak** | PostgreSQL | Unterstützt und empfohlen |
| **ILIAS** | PostgreSQL | Unterstützt und empfohlen |
| **Moodle** | PostgreSQL/MariaDB | Beide unterstützt |
| **Grommunio** | MariaDB/MySQL NUR | **Keine PostgreSQL-Unterstützung** |

#### Warum nicht nur MariaDB?

1. **SOGo:** Keine offizielle MariaDB-Unterstützung
2. **Keycloak:** PostgreSQL ist die empfohlene und bewährte Wahl
3. **Nextcloud:** PostgreSQL bietet bessere Leistung
4. **Ökosystem**: Die meisten openDesk Edu Tools bevorzugen PostgreSQL

#### Warum nicht nur PostgreSQL?

1. **Grommunio**: Harte Anforderung für MariaDB/MySQL - keine PostgreSQL-Portierung existiert
2. **ActiveSync**: Grommunios hervorragende ActiveSync-Unterstützung benötigt MariaDB-Backend
3. **Mobile-first-Priorität**: Grommunio bietet überlegene Mobile-Sync-Funktionen

---

### Architekturübersicht

[Beschreibung der Dual-Datenbank-Architektur wie im Englischen Teil]

---

### Legacy-Fragen

#### Häufige Probleme

**Problem 1: Hoher Speicherverbrauch**

- **Symptom:** Speicherdruck auf Knoten, Pod-Evictionen
- **Ursache:** Fehlkonfiguration von PostgreSQL/MariaDB für verfügbaren RAM
- **Lösung:** shared_buffers/effective_cache_size für PG, innodb_buffer_pool_size für MariaDB anpassen

**Problem 2: Langsame Abfrageleistung**

- **Symptom:** Grommunio oder SOGo laden langsam
- **Ursache:** Fehlende Indizes, Verbindungspool erschöpft
- **Lösung:** Indizes hinzufügen, Pool-Größe erhöhen, Abfragepläne prüfen

**Problem 3: Replikationsverzögerung**

- **Symptom:** Veraltete Daten auf Replikas
- **Ursache:** Netzwerkbandbreite, hohes Schreibvolumen
- **Lösung:** Abfragen optimieren, Netzwerk erweitern, Commit-Consistency-Einstellungen prüfen

**Problem 4: Speichererschöpfung**

- **Symptom:** Festplatte voll, Pods stürzen ab
- **Ursache:** Grommunio-SQLite-Datenbanken werden zu groß
- **Lösung:** Archivierungsrichtlinie implementieren, Speicher erweitern, Monitoring-Warnungen hinzufügen

---

*Letzte Aktualisierung: 2026-04-03*
