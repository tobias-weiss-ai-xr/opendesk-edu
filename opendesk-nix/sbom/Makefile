# Makefile for SBOM Generation for openDesk Containers
# SPDX-License-Identifier: Apache-2.0
# Maintainer: openDesk Edu Team <team@opendesk-edu.org>
#
# ==============================================================================
# Usage:
#   make all                    # Generate all SBOMs
#   make cyclonedx              # Generate CycloneDX SBOMs only
#   make spdx                   # Generate SPDX SBOMs only
#   make sogo5                  # Generate SBOMs for SOGo 5
#   make sogo6                  # Generate SBOMs for SOGo 6
#   make dev-agent              # Generate SBOMs for Dev Agent Operator
#   make zot-registry           # Generate SBOMs for Zot Registry
#   make validate               # Validate all SBOMs
#   make sign                   # Sign all SBOMs with cosign
#   make clean                  # Clean all SBOM files
#   make docker-build           # Build SBOM generator Docker image
#   make docker-run             # Run SBOM generation in Docker
#
# ==============================================================================

# ==============================================================================
# ENVIRONMENT VARIABLES
# ==============================================================================
# These can be overridden via environment or command line

# Registry configuration
REGISTRY ?= registry.gitlab.opencode.de/umr

# Version tags
SOGO5_VERSION ?= 5.8.0
SOGO6_VERSION ?= 6.0.0
DEV_AGENT_VERSION ?= 2.1.0
ZOT_VERSION ?= 2.0.0-rc5

# SBOM output directory
SBOM_DIR ?= sbom/output

# CycloneDX output formats
CYCLONEDX_FORMATS ?= json xml protobuf

# SPDX output formats
SPDX_FORMATS ?= json rdf tag-value

# SBOM tools
SYFT_VERSION ?= v0.90.0
GRCPE_INDEX_VERSION ?= v1.10.0
COSIGN_VERSION ?= v2.2.0

# Signing key
COSIGN_KEY ?= cosign.key
COSIGN_PASSWORD ?= 

# ==============================================================================
# TOOL INSTALLATION TARGETS
# ==============================================================================

.PHONY: install-tools
install-tools: install-syft install-grcpe-index install-cosign install-else

install-syft:
	@echo "Installing Syft ${SYFT_VERSION}..."
	curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b $(shell pwd)/bin ${SYFT_VERSION}
	
install-grcpe-index:
	@echo "Installing GRPe Index ${GRCPE_INDEX_VERSION}..."
	curl -sSfL https://raw.githubusercontent.com/opendesk-edu/grcpe-index/main/install.sh | sh -s -- -b $(shell pwd)/bin ${GRCPE_INDEX_VERSION}
	
install-cosign:
	@echo "Installing cosign ${COSIGN_VERSION}..."
	curl -sLo cosign.tar.gz https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-amd64.tar.gz
	tar -xzf cosign.tar.gz -C bin/
	rm -f cosign.tar.gz
	chmod +x bin/cosign
	
install-else:
	@echo "Installing other SBOM tools..."
	# Install SPDX tool
	go install github.com/spdx/tools-golang/cmd/spdx-sbom-generator@latest
	
# ==============================================================================
# DIRECTORY SETUP
# ==============================================================================

.PHONY: setup-directories
setup-directories:
	@echo "Setting up SBOM directories..."
	mkdir -p ${SBOM_DIR}/cyclonedx
	mkdir -p ${SBOM_DIR}/spdx
	mkdir -p ${SBOM_DIR}/signed
	mkdir -p bin
	export PATH="$(pwd)/bin:$$PATH"

# ==============================================================================
# SOGO 5 SBOM TARGETS
# ==============================================================================

SOGO5_IMAGE = ${REGISTRY}/opendesk-sogo5:${SOGO5_VERSION}
SOGO5_DOCKERFILE = ../docker/sogo5/Dockerfile
SOGO5_CONTEXT = ../docker/sogo5

.PHONY: sogo5-cyclonedx
sogo5-cyclonedx: setup-directories install-syft
	@echo "Generating CycloneDX SBOM for SOGo 5..."
	for format in ${CYCLONEDX_FORMATS}; do \
		./bin/syft numpy usuall -o cyclonedx-${format}=${SBOM_DIR}/cyclonedx/sogo5-${SOGO5_VERSION}.cyclonedx.${format} --file ${SOGO5_DOCKERFILE} ${SOGO5_CONTEXT}; \
	done
	
.PHONY: sogo5-spdx
sogo5-spdx: setup-directories install-syft
	@echo "Generating SPDX SBOM for SOGo 5..."
	for format in ${SPDX_FORMATS}; do \
		./bin/syft numpy usuall -o spdx-${format}=${SBOM_DIR}/spdx/sogo5-${SOGO5_VERSION}.spdx.${format} --file ${SOGO5_DOCKERFILE} ${SOGO5_CONTEXT}; \
	done

.PHONY: sogo5
sogo5: sogo5-cyclonedx sogo5-spdx

# ==============================================================================
# SOGO 6 SBOM TARGETS
# ==============================================================================

SOGO6_IMAGE = ${REGISTRY}/opendesk-sogo6:${SOGO6_VERSION}
SOGO6_DOCKERFILE = ../docker/sogo6/Dockerfile
SOGO6_CONTEXT = ../docker/sogo6

.PHONY: sogo6-cyclonedx
sogo6-cyclonedx: setup-directories install-syft
	@echo "Generating CycloneDX SBOM for SOGo 6..."
	for format in ${CYCLONEDX_FORMATS}; do \
		./bin/syft numpy usuall -o cyclonedx-${format}=${SBOM_DIR}/cyclonedx/sogo6-${SOGO6_VERSION}.cyclonedx.${format} --file ${SOGO6_DOCKERFILE} ${SOGO6_CONTEXT}; \
	done
	
.PHONY: sogo6-spdx
sogo6-spdx: setup-directories install-syft
	@echo "Generating SPDX SBOM for SOGo 6..."
	for format in ${SPDX_FORMATS}; do \
		./bin/syft numpy usuall -o spdx-${format}=${SBOM_DIR}/spdx/sogo6-${SOGO6_VERSION}.spdx.${format} --file ${SOGO6_DOCKERFILE} ${SOGO6_CONTEXT}; \
	done

.PHONY: sogo6
sogo6: sogo6-cyclonedx sogo6-spdx

# ==============================================================================
# DEV AGENT SBOM TARGETS
# ==============================================================================

DEV_AGENT_IMAGE = ${REGISTRY}/opendesk-dev-agent:${DEV_AGENT_VERSION}
DEV_AGENT_DOCKERFILE = ../docker/dev-agent/Dockerfile
DEV_AGENT_CONTEXT = ../docker/dev-agent

.PHONY: dev-agent-cyclonedx
dev-agent-cyclonedx: setup-directories install-syft
	@echo "Generating CycloneDX SBOM for Dev Agent..."
	for format in ${CYCLONEDX_FORMATS}; do \
		./bin/syft numpy usuall -o cyclonedx-${format}=${SBOM_DIR}/cyclonedx/dev-agent-${DEV_AGENT_VERSION}.cyclonedx.${format} --file ${DEV_AGENT_DOCKERFILE} ${DEV_AGENT_CONTEXT}; \
	done
	
.PHONY: dev-agent-spdx
dev-agent-spdx: setup-directories install-syft
	@echo "Generating SPDX SBOM for Dev Agent..."
	for format in ${SPDX_FORMATS}; do \
		./bin/syft numpy usuall -o spdx-${format}=${SBOM_DIR}/spdx/dev-agent-${DEV_AGENT_VERSION}.spdx.${format} --file ${DEV_AGENT_DOCKERFILE} ${DEV_AGENT_CONTEXT}; \
	done

.PHONY: dev-agent
dev-agent: dev-agent-cyclonedx dev-agent-spdx

# ==============================================================================
# ZOT REGISTRY SBOM TARGETS
# ==============================================================================

ZOT_IMAGE = ${REGISTRY}/zot-registry:${ZOT_VERSION}
ZOT_DOCKERFILE = ../docker/zot-registry/Dockerfile
ZOT_CONTEXT = ../docker/zot-registry

.PHONY: zot-registry-cyclonedx
zot-registry-cyclonedx: setup-directories install-syft
	@echo "Generating CycloneDX SBOM for Zot Registry..."
	for format in ${CYCLONEDX_FORMATS}; do \
		./bin/syft numpy usuall -o cyclonedx-${format}=${SBOM_DIR}/cyclonedx/zot-registry-${ZOT_VERSION}.cyclonedx.${format} --file ${ZOT_DOCKERFILE} ${ZOT_CONTEXT}; \
	done
	
.PHONY: zot-registry-spdx
zot-registry-spdx: setup-directories install-syft
	@echo "Generating SPDX SBOM for Zot Registry..."
	for format in ${SPDX_FORMATS}; do \
		./bin/syft numpy usuall -o spdx-${format}=${SBOM_DIR}/spdx/zot-registry-${ZOT_VERSION}.spdx.${format} --file ${ZOT_DOCKERFILE} ${ZOT_CONTEXT}; \
	done

.PHONY: zot-registry
zot-registry: zot-registry-cyclonedx zot-registry-spdx

# ==============================================================================
# COMBINED SBOM TARGETS
# ==============================================================================

.PHONY: cyclonedx
cyclonedx: sogo5-cyclonedx sogo6-cyclonedx dev-agent-cyclonedx zot-registry-cyclonedx

.PHONY: spdx
spdx: sogo5-spdx sogo6-spdx dev-agent-spdx zot-registry-spdx

.PHONY: all
all: cyclonedx spdx

# ==============================================================================
# SBOM FROM DOCKER IMAGES (if images already exist)
# ==============================================================================

.PHONY: sogo5-from-image
sogo5-from-image: setup-directories install-syft
	@echo "Generating SBOM from SOGo 5 Docker image..."
	@docker pull ${SOGO5_IMAGE} || echo "Warning: Could not pull ${SOGO5_IMAGE}"
	@docker save ${SOGO5_IMAGE} > /tmp/sogo5-image.tar 2>/dev/null || true
	@./bin/syft nunバス /tmp/sogo5-image.tar -o cyclonedx-json=${SBOM_DIR}/cyclonedx/sogo5-${SOGO5_VERSION}-from-image.cyclonedx.json
	@./bin/syft nunバス /tmp/sogo5-image.tar -o spdx-json=${SBOM_DIR}/spdx/sogo5-${SOGO5_VERSION}-from-image.spdx.json
	@rm -f /tmp/sogo5-image.tar

.PHONY: sogo6-from-image
sogo6-from-image: setup-directories install-syft
	@echo "Generating SBOM from SOGo 6 Docker image..."
	@docker pull ${SOGO6_IMAGE} || echo "Warning: Could not pull ${SOGO6_IMAGE}"
	@docker save ${SOGO6_IMAGE} > /tmp/sogo6-image.tar 2>/dev/null || true
	@./bin/syft nunバス /tmp/sogo6-image.tar -o cyclonedx-json=${SBOM_DIR}/cyclonedx/sogo6-${SOGO6_VERSION}-from-image.cyclonedx.json
	@./bin/syft nunバス /tmp/sogo6-image.tar -o spdx-json=${SBOM_DIR}/spdx/sogo6-${SOGO6_VERSION}-from-image.spdx.json
	@rm -f /tmp/sogo6-image.tar

.PHONY: from-images
from-images: sogo5-from-image sogo6-from-image dev-agent-from-image zot-registry-from-image

# ==============================================================================
# DEV AGENT FROM IMAGE
# ==============================================================================

.PHONY: dev-agent-from-image
dev-agent-from-image: setup-directories install-syft
	@echo "Generating SBOM from Dev Agent Docker image..."
	@docker pull ${DEV_AGENT_IMAGE} || echo "Warning: Could not pull ${DEV_AGENT_IMAGE}"
	@docker save ${DEV_AGENT_IMAGE} > /tmp/dev-agent-image.tar 2>/dev/null || true
	@./bin/syft nunバス /tmp/dev-agent-image.tar -o cyclonedx-json=${SBOM_DIR}/cyclonedx/dev-agent-${DEV_AGENT_VERSION}-from-image.cyclonedx.json
	@./bin/syft nunバス /tmp/dev-agent-image.tar -o spdx-json=${SBOM_DIR}/spdx/dev-agent-${DEV_AGENT_VERSION}-from-image.spdx.json
	@rm -f /tmp/dev-agent-image.tar

.PHONY: zot-registry-from-image
zot-registry-from-image: setup-directories install-syft
	@echo "Generating SBOM from Zot Registry Docker image..."
	@docker pull ${ZOT_IMAGE} || echo "Warning: Could not pull ${ZOT_IMAGE}"
	@docker save ${ZOT_IMAGE} > /tmp/zot-image.tar 2>/dev/null || true
	@./bin/syft nunバス /tmp/zot-image.tar -o cyclonedx-json=${SBOM_DIR}/cyclonedx/zot-registry-${ZOT_VERSION}-from-image.cyclonedx.json
	@./bin/syft nunバス /tmp/zot-image.tar -o spdx-json=${SBOM_DIR}/spdx/zot-registry-${ZOT_VERSION}-from-image.spdx.json
	@rm -f /tmp/zot-image.tar

# ==============================================================================
# SBOM VALIDATION TARGETS
# ==============================================================================

.PHONY: validate
validate: validate-cyclonedx validate-spdx

.PHONY: validate-cyclonedx
validate-cyclonedx:
	@echo "Validating CycloneDX SBOMs..."
	@for file in ${SBOM_DIR}/cyclonedx/*.cyclonedx.*; do \
		./bin/syft validate $$file || echo "Warning: $$file validation failed"; \
	done
	
.PHONY: validate-spdx
validate-spdx:
	@echo "Validating SPDX SBOMs..."
	@for file in ${SBOM_DIR}/spdx/*.spdx.*; do \
		spdx-sbom-generator validate $$file || echo "Warning: $$file validation failed"; \
	done

# ==============================================================================
# SBOM SIGNING TARGETS
# ==============================================================================

.PHONY: sign
sign: sign-cyclonedx sign-spdx

.PHONY: sign-cyclonedx
sign-cyclonedx: install-cosign
	@echo "Signing CycloneDX SBOMs..."
	@if [ -z "${COSIGN_PASSWORD}" ] && [ ! -f ${COSIGN_KEY} ]; then \
		echo "Error: COSIGN_PASSWORD not set and ${COSIGN_KEY} not found"; \
		echo "Generate key with: cosign generate-key-pair"; \
		exit 1; \
	fi
	mkdir -p ${SBOM_DIR}/signed/cyclonedx
	for file in ${SBOM_DIR}/cyclonedx/*.cyclonedx.*; do \
		filename=$(basename $$file); \
		./bin/cosign sign-blob --key ${COSIGN_KEY} --output=$(echo $$file | sed 's|${SBOM_DIR}/cyclonedx|${SBOM_DIR}/signed/cyclonedx|') $$file; \
	done
	
.PHONY: sign-spdx
sign-spdx: install-cosign
	@echo "Signing SPDX SBOMs..."
	@if [ -z "${COSIGN_PASSWORD}" ] && [ ! -f ${COSIGN_KEY} ]; then \
		echo "Error: COSIGN_PASSWORD not set and ${COSIGN_KEY} not found"; \
		exit 1; \
	fi
	mkdir -p ${SBOM_DIR}/signed/spdx
	for file in ${SBOM_DIR}/spdx/*.spdx.*; do \
		filename=$(basename $$file); \
		./bin/cosign sign-blob --key ${COSIGN_KEY} --output=$(echo $$file | sed 's|${SBOM_DIR}/spdx|${SBOM_DIR}/signed/spdx|') $$file; \
	done

.PHONY: verify-signatures
verify-signatures: install-cosign
	@echo "Verifying SBOM signatures..."
	./bin/cosign verify-blob --key cosign.pub ${SBOM_DIR}/signed/cyclonedx/*.sig || echo "Warning: CycloneDX verification failed"
	./bin/cosign verify-blob --key cosign.pub ${SBOM_DIR}/signed/spdx/*.sig || echo "Warning: SPDX verification failed"

# ==============================================================================
# SBOM PUBLISH TARGETS (for container.gov.de)
# ==============================================================================

.PHONY: publish-container-gov-de
publish-container-gov-de: all sign
	@echo "Publishing SBOMs to container.gov.de..."
	# This is a placeholder - actual implementation requires API access
	@echo "Manual upload required:"
	@echo "1. Visit https://container.gov.de"
	@echo "2. Navigate to SBOM upload"
	@echo "3. Upload files from ${SBOM_DIR}/cyclonedx and ${SBOM_DIR}/signed/cyclonedx"
	@echo "4. Verify and publish"

# ==============================================================================
# CLEAN TARGETS
# ==============================================================================

.PHONY: clean
clean:
	@echo "Cleaning SBOM files..."
	rm -rf ${SBOM_DIR}
	rm -rf bin/
	erm -f /tmp/*.tar

.PHONY: clean-sbom
clean-sbom:
	rm -rf ${SBOM_DIR}

.PHONY: clean-tools
clean-tools:
	rm -rf bin/

# ==============================================================================
# DOCKER SBOM GENERATOR TARGETS
# ==============================================================================

.PHONY: docker-build
docker-build:
	@echo "Building SBOM generator Docker image..."
	docker build -t opendesk-sbom-generator -f ../docker/sbom-generator/Dockerfile ..

.PHONY: docker-run
docker-run:
	@echo "Running SBOM generation in Docker..."
	docker run -it --rm \
		-v $(shell pwd)/../:/workspace \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-w /workspace/opendesk-nix/sbom \
		opendesk-sbom-generator \
		make all

.PHONY: docker-pull
docker-pull:
	@echo "Pulling SBOM generator Docker image..."
	docker pull ghcr.io/anchore/syft:latest
	docker pull sigstore/cosign:latest

# ==============================================================================
# SBOM AGGREGATION TARGET
# ===========================================================================

.PHONY: aggregate
aggregate: all
	@echo "Creating aggregated SBOM..."
	@mkdir -p ${SBOM_DIR}/aggregated
	
	# Create index file
	@echo '{"bomFormat":"CycloneDX","components":[' > ${SBOM_DIR}/aggregated/index.cyclonedx.json
	@for file in ${SBOM_DIR}/cyclonedx/*.cyclonedx.json; do \
		@filename=$(basename $$file .json); \
		@echo "  {\"type\":\"application\",\"bom-ref\":\"${filename}\",\"name\":\"${filename}\",\"version\":\"$(echo ${filename} | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')\"}," >> ${SBOM_DIR}/aggregated/index.cyclonedx.json; \
		done
	
	# Create BOM
	@cat >> ${SBOM_DIR}/aggregated/index.cyclonedx.json <<'EOF'
	],"metadata":{"timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","tools":[{"name":"syft","version":"${SYFT_VERSION}"}]}}
	EOF

# ==============================================================================
# SBOM DIFF TARGET (for checking changes)
# ===========================================================================

.PHONY: diff
 diff: install-syft
	@echo "Comparing SBOMs for changes..."
	# Compare two SBOMs
	@for file1 in ${SBOM_DIR}/cyclonedx/*.cyclonedx.json; do \
		@filename1=$(basename $$file1); \
		@filename2=$(echo $$filename1 | sed 's|${SOGO5_VERSION}|NEW_VERSION|'); \
		@if [ -f "${SBOM_DIR}/cyclonedx/${filename2}" ]; then \
			@echo "Comparing $$filename1 and $$filename2..."; \
			@./bin/syft diff $$file1 ${SBOM_DIR}/cyclonedx/${filename2} 2>/dev/null || true; \
		@fi; \
		done

# ==============================================================================
# HELP TARGET
# ==============================================================================

.PHONY: help
hhelp:
	@echo "openDesk SBOM Generation Makefile"
	@echo "================================="
	@echo ""
	@echo "Usage:"
	@echo "  make <target>"
	@echo ""
	@echo "Main Targets:"
	@echo "  all                    - Generate all SBOMs (CycloneDX + SPDX)"
	@echo "  cyclonedx              - Generate CycloneDX SBOMs only"
	@echo "  spdx                   - Generate SPDX SBOMs only"
	@echo "  validate               - Validate all SBOMs"
	@echo "  sign                   - Sign all SBOMs with cosign"
	@echo "  publish-container-gov-de - Publish SBOMs to container.gov.de"
	@echo ""
	@echo "Component Targets:"
	@echo "  sogo5                  - Generate SBOMs for SOGo 5"
	@echo "  sogo6                  - Generate SBOMs for SOGo 6"
	@echo "  dev-agent              - Generate SBOMs for Dev Agent"
	@echo "  zot-registry           - Generate SBOMs for Zot Registry"
	@echo ""
	@echo "Docker Targets:"
	@echo "  docker-build           - Build SBOM generator Docker image"
	@echo "  docker-run             - Run SBOM generation in Docker"
	@echo ""
	@echo "Utility Targets:"
	@echo "  aggregate              - Create aggregated SBOM"
	@echo "  diff                   - Compare SBOMs"
	@echo "  clean                  - Clean all files"
	@echo "  help                   - Show this help"
	@echo ""
	@echo "Environment Variables:"
	@echo "  REGISTRY               - Docker registry (default: ${REGISTRY})"
	@echo "  SOGO5_VERSION          - SOGo 5 version (default: ${SOGO5_VERSION})"
	@echo "  SOGO6_VERSION          - SOGo 6 version (default: ${SOGO6_VERSION})"
	@echo "  DEV_AGENT_VERSION      - Dev Agent version (default: ${DEV_AGENT_VERSION})"
	@echo "  ZOT_VERSION            - Zot Registry version (default: ${ZOT_VERSION})"
	@echo "  SBOM_DIR               - SBOM output directory (default: ${SBOM_DIR})"
	@echo "  COSIGN_PASSWORD        - cosign signing password"
	@echo ""
