# openDesk Docker Compose Deployment

Production-ready Docker Compose setup for openDesk with custom components as an alternative to Kubernetes deployment.

## Components

This deployment includes:

- **Infrastructure Services:**
  - Traefik (reverse proxy with Let'\''s Encrypt SSL)
  - PostgreSQL (consolidated database for all components)

- **Application Services:**
  - Nubus/Keycloak (IAM/Portal)
  - OpenCloud (file management)
  - Element/Synapse (chat)
  - Notes/CryptPad (collaborative notes)
  - MOX (email server)
  - SOGo (webmail)

## Prerequisites

- Docker Engine 24.0+
- Docker Compose 3.9+
- Linux or macOS host
- 8GB+ RAM minimum (32GB recommended)
- 2+ CPU cores recommended
- Domain name with DNS control

## Quick Start

1. Copy environment template:
   \`\`\`bash
   cp .env.example .env.production
   \`\`\`

2. Edit configuration:
   \`\`\`nano .env.production
   \`\`\`

   Set these required variables:
   - DOMAIN (your primary domain)
   - EMAIL_DOMAIN (for email services)
   - POSTGRES_PASSWORD (PostgreSQL admin password)
   - KEYCLOAK_ADMIN_PASSWORD (Keycloak admin)
   - Service-specific passwords and secrets

3. Start services:
   \`\`\`docker-compose up -d
   \`\`\`

4. Monitor startup:
   \`\`\`docker-compose ps
   \`\`\`

5. Configure DNS records (see below)
   \`\`\`

## Service URLs

After deployment with domain \`yourdomain.com\`:

| Service       | URL                              | Purpose |
|---------------|----------------------------------|---------|
| Portal        | https://keycloak.yourdomain.com/auth/  | Keycloak admin console |
| OpenCloud     | https://opencloud.yourdomain.com/     | File management |
| Element       | https://element.yourdomain.com/    | Matrix chat |
| Notes         | https://notes.yourdomain.com/     | Collaborative notes |
| Webmail       | https://webmail.yourdomain.com/   | Email client |
| Email (SMTP)  | mail.yourdomain.com:25             | SMTP endpoint |

## DNS Configuration

### Required DNS Records

#### A Records (point to your server IP)
\`\`\`bash
keycloak          -> <YOUR_SERVER_IP>
opencloud         -> <YOUR_SERVER_IP>
element           -> <YOUR_SERVER_IP>
matrix            -> <YOUR_SERVER_IP>
notes             -> <YOUR_SERVER_IP>
webmail           -> <YOUR_SERVER_IP>
mail              -> <YOUR_SERVER_IP>
\`\`\`

#### MX Record (mail delivery)
\`\`\`bash
@                 -> mail.yourdomain.com
\`\`\`

#### TXT Records

**ACME Challenge (Let'\''s Encrypt):**
\`\`\`bash
_acme-challenge    -> "Let'\''s Encrypt validation string"
\`\`\`

**SPF Record (email delivery):**
\`\`\`bash
@                 TXT  "v=spf1 include:mx:mail.yourdomain.com -all"
\`\`\`

**DKIM Record (email signing):**
\`\`\`bash
default._domainkey   CNAME  default._domainkey.mail.yourdomain.com
\`\`\`

**DMARC Record (email policy):**
\`\`\`bash
_dmarc            TXT  "v=DMARC1; p=none; rua=mailto:dmarc@yourdomain.com"
\`\`\`

## Firewall Requirements

Allow these ports through your firewall:

| Port | Protocol | Service              | Purpose          |
|-------|-----------|-------------------|------------------|
| 80    | TCP       | HTTP (Let'\''s Encrypt)     | ACME challenges |
| 443   | TCP       | HTTPS (Traefik)         | Main web traffic  |
| 25    | TCP       | SMTP (MOX)            | Email delivery  |
| 587   | TCP       | SMTP submission (MOX)     | Email submission  |
| 465   | TCP       | SMTPS (MOX)            | Secure email     |
| 143   | TCP       | IMAP (MOX)             | Email retrieval   |
| 993   | TCP       | IMAPS (MOX)            | Secure email     |
| 110   | TCP       | POP3 (MOX)             | Email retrieval   |
| 995   | TCP       | POP3S (MOX)            | Secure email     |

**IMPORTANT:** Many cloud providers block port 25 (SMTP). If your provider blocks port 25:
- Request port 25 unblocking from your cloud provider
- Use an external SMTP relay service for email delivery
- Configure MOX to relay through the relay service instead

## Backup and Restore

### Backup Script

Automated backup of all service volumes:

\`\`\`bash
./scripts/backup.sh                    # Full backup
./scripts/backup.sh --dry-run          # Preview what would be backed up
./scripts/backup.sh --services <list>    # Backup specific services
\`\`\`

**Backup Features:**
- Consistent backup (stops services temporarily)
- Timestamped backup files (YYYYMMDD-HHMMSS.tar.gz)
- Automatic cleanup of old backups (7-day retention)
- Backup logging to \`backups/backup.log\`

### Restore Script

Restore service volumes from backup:

\`\`\`bash
./scripts/restore.sh <backup-file.tar.gz>   # Restore specific backup
./scripts/restore.sh --dry-run             # Validate backup file
\`\`\`

**Restore Features:**
- Confirmation prompt before overwriting data
- Validation of backup file format
- Automatic service restart after restore
- Restore logging to \`backups/restore.log\`

**IMPORTANT:** Restore operation OVERWRITES all existing data. Use with caution!

## Environment Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| DOMAIN | Primary domain for all services | \`yourdomain.com\` |
| EMAIL_DOMAIN | Email domain (for MOX) | \`mail.yourdomain.com\` |
| POSTGRES_PASSWORD | PostgreSQL admin password | \`secure-password\` |
| KEYCLOAK_ADMIN | Keycloak admin username | \`admin\` |
| KEYCLOAK_ADMIN_PASSWORD | Keycloak admin password | \`secure-password\` |
| OPENCLOUD_ADMIN_USER | OpenCloud admin user | \`admin\` |
| OPENCLOUD_ADMIN_PASSWORD | OpenCloud admin password | \`secure-password\` |
| CRYPTPAD_ADMIN_EMAIL | CryptPad admin email | \`admin@yourdomain.com\` |
| CRYPTPAD_ADMIN_PASSWORD | CryptPad admin password | \`secure-password\` |
| MOX_ADMIN_EMAIL | MOX admin email | \`postmaster@yourdomain.com\` |
| MOX_ADMIN_PASSWORD | MOX admin password | \`secure-password\` |
| SOGO_ADMIN_USER | SOGo admin user | \`admin\` |
| SOGO_ADMIN_PASSWORD | SOGo admin password | \`secure-password\` |

### Optional Variables (Database Passwords)

| Variable | Description | Default |
|----------|-------------|---------|
| KEYCLOAK_DB_PASSWORD | Keycloak database password | \`changeme\` |
| SYNAPSE_DB_PASSWORD | Synapse database password | \`changeme\` |
| OPENCLOUD_DB_PASSWORD | OpenCloud database password | \`changeme\` |
| NOTES_DB_PASSWORD | Notes database password | \`changeme\` |
| MOX_DB_PASSWORD | MOX database password | \`changeme\` |
| SOGO_DB_PASSWORD | SOGo database password | \`changeme\` |

### Email Variable (for Let'\''s Encrypt)

| Variable | Description | Default |
|----------|-------------|---------|
| ACME_EMAIL | Email for Let'\''s Encrypt certificates | \`admin@${DOMAIN:-example.com}\` |

## Directory Structure

\`\`\`bash
opendesk-compose/
├── docker-compose.yml       # Main orchestration file
├── .env.example           # Environment variable template
├── .env.production         # Your actual secrets (create from .env.example)
├── traefik/
│   └── traefik.yml      # Traefik configuration
├── scripts/
│   ├── backup.sh         # Backup automation
│   ├── init-db.sh       # Database initialization
│   └── restore.sh       # Restore automation
└── backups/                # Backup storage location
\`\`\`

## Common Operations

### Start Services
\`\`\`bash
docker-compose up -d
\`\`\`

### Stop Services
\`\`\`bash
docker-compose down
\`\`\`

### View Logs
\`\`\`bash
docker-compose logs -f <service>
\`\`\`

### Check Service Status
\`\`\`bash
docker-compose ps
\`\`\`

## Troubleshooting

### Services Not Starting

1. Check environment variables:
   \`\`\`docker-compose config
   \`\`\`
   Ensure all required variables in .env.production are set

2. Check service health:
   \`\`\`docker-compose ps
   \`\`\`
   All services should show "healthy" or "running"

3. View service logs:
   \`\`\`docker-compose logs <service>
   \`\`\`
   Check for error messages or configuration issues

4. Check DNS configuration:
   \`\`\`dig keycloak.yourdomain.com
   \`\`\`
   Verify DNS records are correctly pointing to your server

### Port 25 Blocked

If MOX cannot send email on port 25:

1. Test port 25 connectivity:
   \`\`\`bash
   telnet mail.yourdomain.com 25
   \`\`\`

2. If blocked, request unblocking from cloud provider

3. Alternative: Configure external SMTP relay

### SSL Certificate Issues

If Let'\''s Encrypt certificates fail:

1. Check Traefik logs:
   \`\`\`docker-compose logs traefik | grep -i "acme"
   \`\`\`

2. Check ACME challenge:
   \`\`\`dig _acme-challenge.yourdomain.com TXT
   \`\`\`

3. Verify port 80 is accessible:
   \`\`\`curl http://yourdomain.com
   \`\`\`

### Backup Issues

1. Ensure sufficient disk space for backups
2. Check \`backups/\` directory permissions
3. Review \`backups/backup.log\` for errors

### Memory Issues

1. Monitor container memory usage:
   \`\`\`docker stats
   \`\`\`

2. Check for OOM kills:
   \`\`\`docker-compose logs <service> | grep -i "out of memory"
   \`\`\`

## Security Notes

1. Never commit .env.production to version control
2. Rotate all passwords regularly
3. Keep Docker and host system updated
4. Review Traefik logs for security events
5. Configure firewall to restrict access to only required ports

## Support

For issues or questions:
- OpenDesk documentation: https://docs.opencloud.eu/docs/
- Keycloak documentation: https://www.keycloak.org/docs/
- Traefik documentation: https://doc.traefik.io/traefik/

## License

See component licenses in their respective documentation.

