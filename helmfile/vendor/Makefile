# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0

# Makefile for managing vendored Helm charts
# Use: make vendor-update CHART=ollama

SHELL := /bin/bash
VENDOR_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# Chart registry/repo definitions
CHARTS := code-server dask jupyterhub ollama open-webui

# Chart sources (repo URL, chart name, OCI flag)
chart-source = $(eval \
  $1_REPO := $(word 100,$(call get-source,$1)) \
)

define CHART_SOURCES
  code-server:https://helm.coder.com/coder-v2:coder/coder
  dask:https://helm.dask.org:dask/dask-gateway
  jupyterhub:https://hub.jupyter.org/helm-chart:jupyterhub/jupyterhub
  ollama:https://ollama.github.io/helm-chart:ollama/ollama
  open-webui:https://helm.openwebui.com:open-webui/open-webui
  overleaf:oci://ghcr.io/sharelatex/overleaf-helm-chart/overleaf:overleaf
  kasmvnc:oci://registry.kasmweb.com/kasmweb/charts/kasmvnc:kasmvnc
endef

.PHONY: vendor-list vendor-update vendor-status

## List all vendored charts with versions
vendor-list:
	@echo "Vendored charts:"; \
	for chart in $(CHARTS) overleaf kasmvnc; do \
		if [ -f "$(VENDOR_DIR)charts/$$chart/Chart.yaml" ]; then \
			version=$$(grep "^version:" "$(VENDOR_DIR)charts/$$chart/Chart.yaml" 2>/dev/null | awk '{print $$2}'); \
			echo "  ✅ $$chart v$$version"; \
		else \
			echo "  ⚠️  $$chart (not vendored)"; \
		fi; \
	done

## Update a specific chart from upstream
# Usage: make vendor-update CHART=ollama
vendor-update:
	@if [ -z "$(CHART)" ]; then \
		echo "Usage: make vendor-update CHART=<chart-name>"; \
		echo "Available: $(CHARTS)"; \
		exit 1; \
	fi; \
	chart=$$(echo "$(CHART)" | tr '[:upper:]' '[:lower:]'); \
	url=$$(echo -e "$(CHART_SOURCES)" | grep "^$$chart:" | cut -d: -f2); \
	helm_chart=$$(echo -e "$(CHART_SOURCES)" | grep "^$$chart:" | cut -d: -f3); \
	oci_chart=$$(echo -e "$(CHART_SOURCES)" | grep "^$$chart:" | cut -d: -f4); \
	if [ -z "$$url" ]; then \
		echo "Unknown chart: $$chart"; \
		echo "Available: $(CHARTS)"; \
		exit 1; \
	fi; \
	version=$$(grep "^version:" "$(VENDOR_DIR)charts/$$chart/Chart.yaml" 2>/dev/null | awk '{print $$2}' || echo "latest"); \
	if echo "$$url" | grep -q "^oci://"; then \
		echo "Downloading OCI chart $$helm_chart..."; \
		helm pull "oci://$$helm_chart" --untar --untardir="/tmp/vendor-$$chart" 2>/dev/null && \
		rm -rf "$(VENDOR_DIR)charts/$$chart" && \
		mv "/tmp/vendor-$$chart/$$chart" "$(VENDOR_DIR)charts/$$chart" && \
		rm -rf "/tmp/vendor-$$chart" && \
		new_version=$$(grep "^version:" "$(VENDOR_DIR)charts/$$chart/Chart.yaml" | awk '{print $$2}') && \
		echo "✅ $$chart updated to v$$new_version"; \
	else \
		echo "Downloading $$helm_chart from $$url..."; \
		helm repo add "vendor-$$chart" "$$url" 2>/dev/null; \
		helm pull "$$helm_chart" --untar --untardir="/tmp/vendor-$$chart" 2>/dev/null && \
		chart_dir=$$(find "/tmp/vendor-$$chart" -name "Chart.yaml" -exec dirname {} \; 2>/dev/null | head -1); \
		rm -rf "$(VENDOR_DIR)charts/$$chart" && \
		mv "$$chart_dir" "$(VENDOR_DIR)charts/$$chart" && \
		rm -rf "/tmp/vendor-$$chart" && \
		new_version=$$(grep "^version:" "$(VENDOR_DIR)charts/$$chart/Chart.yaml" | awk '{print $$2}') && \
		echo "✅ $$chart updated to v$$new_version"; \
	fi

## Show git diff for modified charts (to review patches)
vendor-status:
	@cd "$(VENDOR_DIR)" && git diff --stat vendor/charts/ 2>/dev/null || echo "No changes"

## Init: first-time vendor setup for all charts
vendor-init:
	@echo "Initializing all vendor charts..."; \
	for chart in $(CHARTS); do \
		$(MAKE) vendor-update CHART=$$chart; \
	done; \
	echo ""; \
	echo "OCI charts (download manually):"; \
	echo "  overleaf: helm pull oci://ghcr.io/sharelatex/overleaf-helm-chart/overleaf ..."; \
	echo "  kasmvnc: helm pull oci://registry.kasmweb.com/kasmweb/charts/kasmvnc ..."
