# openDesk Edu — Development Makefile
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: AGPL-3.0-or-later

SHELL := /bin/bash

# All edu Helm charts
CHARTS := $(sort $(patsubst %/Chart.yaml,%,$(wildcard helmfile/charts/*/Chart.yaml)))

.PHONY: help lint test template unittest spellcheck update-check clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

lint: ## Run helm lint on all charts
	@echo "==> Linting all charts..."
	@for chart in $(CHARTS); do \
		echo "  $$chart"; \
		helm lint $$chart || exit 1; \
	done
	@echo "==> All charts passed lint."

template: ## Render all charts with default values
	@echo "==> Rendering all charts..."
	@for chart in $(CHARTS); do \
		echo "  $$chart"; \
		helm template test $$chart > /dev/null || exit 1; \
	done
	@echo "==> All charts rendered successfully."

unittest: ## Run helm-unittest on all charts
	@echo "==> Running unit tests..."
	@if ! helm plugin list 2>/dev/null | grep -q unittest; then \
		echo "Installing helm-unittest plugin..."; \
		helm plugin install https://github.com/helm-unittest/helm-unittest.git --version v0.7.2; \
	fi
	@for chart in $(CHARTS); do \
		if [ -d "$$chart/tests" ]; then \
			echo "  $$chart"; \
			helm unittest $$chart || exit 1; \
		fi; \
	done
	@echo "==> All unit tests passed."

test: lint template unittest ## Run all tests (lint + template + unittest)

spellcheck: ## Run cspell on documentation
	@cspell --config cspell.json \
		"README.md" "ROADMAP.md" "CONTRIBUTING.md" \
		"docs/university-apps-concept.md" "docs/external-services.md" \
		"docs/getting-started.md" \
		".github/" \
		--no-progress

yamllint: ## Run yamllint on YAML files
	@yamllint -c .yamllint \
		helmfile/charts/ \
		docs/ \
		.github/ \
		publiccode.yml

update-check: ## Check for upstream version updates (requires network)
	@echo "==> Checking upstream openDesk version..."
	@CURRENT=$$(grep "softwareVersion:" publiccode.yml | sed 's/.*: "//;s/".*//' | sed 's/-edu.*//'); \
	echo "Current fork version: $${CURRENT}"
	@echo ""
	@echo "Upstream releases: https://github.com/Bundesdruckerei/opendesk/releases"

clean: ## Remove vendored chart dependencies
	@find helmfile/charts -mindepth 2 -maxdepth 2 -type d \
		! -name 'templates' ! -name 'tests' ! -name 'ci' \
		-exec rm -rf {} + 2>/dev/null || true
	@find helmfile/charts -mindepth 1 -maxdepth 2 -name 'Chart.lock' -delete 2>/dev/null || true
	@echo "==> Cleaned vendored dependencies."
