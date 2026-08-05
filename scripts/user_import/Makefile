# openDesk Edu User Provisioning Makefile
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0

.PHONY: help deps install lint test clean backup restore

help: ## Show this help
	@echo "openDesk Edu User Provisioning - Available Commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

deps: ## Check if Python dependencies are installed
	@echo "Checking Python dependencies..."
	@pip show ldap3 python-keycloak requests > /dev/null 2>&1 || ( \
		echo "Dependencies not found. Run 'make install' first."; \
		exit 1 \
	)
	@echo "All dependencies installed ✓"

install: ## Install Python dependencies
	@echo "Installing Python dependencies..."
	@pip install -r requirements.txt
	@echo "Dependencies installed ✓"

lint: ## Run Python linting
	@echo "Running Python linters..."
	@if command -v pylint > /dev/null 2>&1; then \
		pylint sync_users.py deprovision_user.py archive_service_user.py || exit 1; \
	else \
		echo "pylint not found, skipping..."; \
	fi
	@if command -v flake8 > /dev/null 2>&1; then \
		flake8 sync_users.py deprovision_user.py archive_service_user.py --max-line-length=120 || exit 1; \
	else \
		echo "flake8 not found, skipping..."; \
	fi
	@if command -v black > /dev/null 2>&1; then \
		black --check sync_users.py deprovision_user.py archive_service_user.py || echo "Run 'make format' to fix formatting"; \
	else \
		echo "black not found, skipping..."; \
	fi
	@echo "Linting complete ✓"

format: ## Format Python code with black
	@echo "Formatting Python code..."
	@if command -v black > /dev/null 2>&1; then \
		black sync_users.py deprovision_user.py archive_service_user.py; \
	else \
		echo "black not found. Install with: pip install black"; \
		exit 1; \
	fi
	@echo "Formatting complete ✓"

test: ## Run Python unit tests
	@echo "Running Python unit tests..."
	@if command -v pytest > /dev/null 2>&1; then \
		pytest tests/ -v || exit 1; \
	else \
		echo "pytest not found. Install with: pip install pytest"; \
		exit 1; \
	fi
	@echo "Tests passed ✓"

backup: ## Backup provisioning data
	@echo "Backing up provisioning data..."
	@BACKUP_DIR=/var/lib/opendesk-backups \
	TIMESTAMP=$$(date +%Y%m%d_%H%M%S) && \
	mkdir -p $$BACKUP_DIR && \
	tar -czf $$BACKUP_DIR/provisioning_$$TIMESTAMP.tar.gz \
		--exclude='*.pyc' \
		--exclude='__pycache__' \
		--exclude='*.log' \
		. 2>/dev/null || echo "Backup failed"
	@echo "Backup complete ✓"

backup-all: ## Backup provisioning data and archives
	@echo "Backing up provisioning data and archives..."
	@BACKUP_DIR=/var/lib/opendesk-backups \
	TIMESTAMP=$$(date +%Y%m%d_%H%M%S) && \
	mkdir -p $$BACKUP_DIR && \
	tar -czf $$BACKUP_DIR/provisioning_complete_$$TIMESTAMP.tar.gz \
		/opt/opendesk-edu/scripts/user_import/ \
		/var/lib/opendesk-archives/ 2>/dev/null || echo "Backup failed"
	@echo "Complete backup complete ✓"

restore: ## Restore from backup (use FILE=backup.tar.gz)
	@if [ -z "$(FILE)" ]; then \
		echo "Error: FILE parameter required"; \
		echo "Usage: make restore FILE=/path/to/backup.tar.gz"; \
		exit 1; \
	fi
	@echo "Restoring from $(FILE)..."
	@tar -xzf $(FILE) 2>/dev/null || echo "Restore failed"
	@echo "Restore complete ✓"

sync: ## Sync users from LDAP to Keycloak (use DRY_RUN=true for dry-run)
	@echo "Syncing users from LDAP to Keycloak..."
	@python sync_users.py \
		--source ldap \
		--auto-sync \
		--auto-assign-roles \
		$$(if [ "$$DRY_RUN" = "true" ]; then echo "--dry-run"; fi)

sync-students: ## Sync only students
	@python sync_users.py \
		--source ldap \
		--filter "(eduPersonAffiliation=student)" \
		--auto-assign-roles

sync-faculty: ## Sync only faculty
	@python sync_users.py \
		--source ldap \
		--filter "(eduPersonAffiliation=faculty)" \
		--auto-assign-roles

disable: ## Disable user (use USER=username)
	@if [ -z "$(USER)" ]; then \
		echo "Error: USER parameter required"; \
		echo "Usage: make disable USER=john.doe"; \
		exit 1; \
	fi
	@python deprovision_user.py \
		$(USER) \
		--phase disable \
		--reason "Manual disable"

delete: ## Delete user permanently (use USER=username)
	@if [ -z "$(USER)" ]; then \
		echo "Error: USER parameter required"; \
		echo "Usage: make delete USER=john.doe"; \
		exit 1; \
	fi
	@echo "⚠️  This will PERMANENTLY DELETE user $(USER)"
	@echo "Type 'yes' to confirm: " && read response && \
	if [ "$$response" != "yes" ]; then \
		echo "Cancelled"; \
		exit 0; \
	fi
	@python deprovision_user.py \
		$(USER) \
		--phase delete

archive: ## Archive user data from services (use USER=username)
	@if [ -z "$(USER)" ]; then \
		echo "Error: USER parameter required"; \
		echo "Usage: make archive USER=john.doe"; \
		exit 1; \
	fi
	@python archive_service_user.py $(USER) --all

archive-batch: ## Archive users from CSV file (use FILE=users.csv)
	@if [ -z "$(FILE)" ]; then \
		echo "Error: FILE parameter required"; \
		echo "Usage: make archive-batch FILE=users.csv"; \
		exit 1; \
	fi
	@while IFS= read -r username; do \
		echo "Archiving $$username..."; \
		python archive_service_user.py $$username --all; \
	done < $(FILE)

clean: ## Clean temporary files and archives
	@echo "Cleaning temporary files..."
	@find . -name '*.pyc' -delete
	@find . -name '__pycache__' -type d -exec rm -rf {} + 2>/dev/null || true
	@find . -name '*.log' -mtime +30 -delete 2>/dev/null || true
	@echo "Cleanup complete ✓"

clean-archives: ## Clean old archives (older than 90 days)
	@echo "Cleaning old archives..."
	@find /var/lib/opendesk-archives/ -mtime +90 -delete 2>/dev/null || true
	@echo "Old archives cleaned ✓"

monitor: ## Show provisioning statistics
	@echo "User Provisioning Statistics"
	@echo "=========================="
	@echo ""
	@echo "Active Users:"
	@python sync_users.py --source ldap --dry-run 2>&1 | grep "Found.*users" || echo "  Check LDAP connection"
	@echo ""
	@echo "Recent Provisioning Activity:"
	@tail -20 /var/log/opendesk-user-sync.log 2>/dev/null || echo "  No recent activity"
	@echo ""
	@echo "Archived Users:"
	@find /var/lib/opendesk-archives/ -maxdepth 1 -type d | wc -l

status: ## Show status of all components
	@echo "Provisioning System Status"
	@echo "========================="
	@echo ""
	@echo "Keycloak Connection:"
	@python -c "from sync_users import KeycloakAdminClient; kc = KeycloakAdminClient(); print('  Connected ✓' if kc.connect() else '  Failed ✗')"
	@echo ""
	@echo "LDAP Connection:"
	@python -c "from sync_users import LDAPClient; ldap = LDAPClient(); print('  Connected ✓' if ldap.connect() else '  Failed ✗')"
	@echo ""
	@echo "Disk Usage:"
	@du -sh /var/lib/opendesk-archives/ 2>/dev/null || echo "  Archives: N/A"
	@du -sh /var/log/opendesk-*.log 2>/dev/null || echo "  Logs: N/A"
