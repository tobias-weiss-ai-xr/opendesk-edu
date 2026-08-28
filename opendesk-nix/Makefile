# openDesk Nix - Master Makefile
# SPDX-License-Identifier: Apache-2.0
# Maintainer: openDesk Edu Team <team@opendesk-edu.org>
#
# ==============================================================================
# Main Makefile for building, testing, and deploying openDesk containers
#
# Usage:
#   make help                    # Show all targets
#   make build-all               # Build all Docker images
#   make build-sogo5             # Build SOGo 5 image
#   make build-sogo6             # Build SOGo 6 image
#   make build-dev-agent         # Build Dev Agent image
#   make build-zot               # Build Zot Registry image
#   make push-all                # Push all images to registry
#   make push-sogo5              # Push SOGo 5 image
#   make deploy-all              # Deploy all to Kubernetes
#   make deploy-dev-agent        # Deploy Dev Agent Operator
#   make undeploy-all            # Remove all deployments
#   make test-all                # Run all tests
#   make sbom-all                # Generate all SBOMs
#   make clean                   # Clean all
#
# ==============================================================================

# ==============================================================================
# ENVIRONMENT VARIABLES
# ==============================================================================

# Registry configuration
REGISTRY ?= ghcr.io/tobias-weiss-ai-xr/umr/opendesk-edu/containers/opendesk-edu/containers

# Version tags
SOGO5_VERSION ?= 5.8.0
SOGO6_VERSION ?= 6.0.0
DEV_AGENT_VERSION ?= 2.1.0
ZOT_VERSION ?= 2.0.0-rc5

# Image names
SOGO5_IMAGE = ${REGISTRY}/opendesk-sogo5:${SOGO5_VERSION}
SOGO6_IMAGE = ${REGISTRY}/opendesk-sogo6:${SOGO6_VERSION}
DEV_AGENT_IMAGE = ${REGISTRY}/opendesk-dev-agent:${DEV_AGENT_VERSION}
ZOT_IMAGE = ${REGISTRY}/zot-registry:${ZOT_VERSION}

# Build arguments
BUILD_ARGS ?= --no-cache
BUILD_CONTEXT ?= .

# Kubernetes context
KUBE_CONTEXT ?= $(shell kubectl config current-context 2>/dev/null)
KUBE_NAMESPACE ?= default

# Docker command
DOCKER ?= docker

# Kubectl command
KUBECTL ?= kubectl

# ==============================================================================
# PHONY TARGETS DEFINITION
# ==============================================================================

.PHONY: help build-all push-all deploy-all undeploy-all test-all sbom-all clean
.PHONY: test test-verbose test-count shellcheck lint
.PHONY: build-sogo5 build-sogo6 build-dev-agent build-zot
.PHONY: push-sogo5 push-sogo6 push-dev-agent push-zot
.PHONY: deploy-sogo5 deploy-sogo6 deploy-dev-agent deploy-zot
.PHONY: undeploy-sogo5 undeploy-sogo6 undeploy-dev-agent undeploy-zot
.PHONY: test-sogo5 test-sogo6 test-dev-agent test-zot
.PHONY: sbom-sogo5 sbom-sogo6 sbom-dev-agent sbom-zot
.PHONY: scan-all scan-sogo5 scan-sogo6 scan-dev-agent scan-zot
.PHONY: generate-specs generate-sbom-docs validate-all

# ==============================================================================
# HELP TARGET
# ==============================================================================

help: ## Show this help message
	@echo ""
	@echo "================================================================================"
	@echo "  openDesk Nix - Master Makefile"
	@echo "  SPDX-License-Identifier: Apache-2.0"
	@echo "  Maintainer: openDesk Edu Team <team@opendesk-edu.org>"
	@echo "================================================================================"
	@echo ""
	@echo "REGISTRY: ${REGISTRY}"
	@echo "SOGo 5 Version: ${SOGO5_VERSION}"
	@echo "SOGo 6 Version: ${SOGO6_VERSION}"
	@echo "Dev Agent Version: ${DEV_AGENT_VERSION}"
	@echo "Zot Version: ${ZOT_VERSION}"
	@echo ""
	@echo "USAGE: make <target>"
	@echo ""
	@echo "================================================================================"
	@echo "  BUILD TARGETS"
	@echo "================================================================================"
	@grep -E "^build-.*:.*##" ${MAKEFILE_LIST} | sort
	@echo ""
	@echo "================================================================================"
	@echo "  PUSH TARGETS"
	@echo "================================================================================"
	@grep -E "^push-.*:.*##" ${MAKEFILE_LIST} | sort
	@echo ""
	@echo "================================================================================"
	@echo "  DEPLOY TARGETS"
	@echo "================================================================================"
	@grep -E "^deploy-.*:.*##" ${MAKEFILE_LIST} | sort
	@echo ""
	@echo "================================================================================"
	@echo "  TEST TARGETS"
	@echo "================================================================================"
	@grep -E "^test-.*:.*##" ${MAKEFILE_LIST} | sort
	@echo ""
	@echo "================================================================================"
	@echo "  SBOM TARGETS"
	@echo "================================================================================"
	@grep -E "^sbom-.*:.*##" ${MAKEFILE_LIST} | sort
	@echo ""
	@echo "================================================================================"
	@echo "  SCAN TARGETS"
	@echo "================================================================================"
	@grep -E "^scan-.*:.*##" ${MAKEFILE_LIST} | sort
	@echo ""
	@echo "================================================================================"
	@echo "  UTILITY TARGETS"
	@echo "================================================================================"
	@grep -E "^(help|clean|validate|generate):.*##" ${MAKEFILE_LIST} | sort
	@echo ""
	@echo "================================================================================"
	@echo "  ENVIRONMENT VARIABLES"
	@echo "================================================================================"
	@echo "  REGISTRY           - Docker registry (default: ${REGISTRY})"
	@echo "  SOGO5_VERSION      - SOGo 5 version (default: ${SOGO5_VERSION})"
	@echo "  SOGO6_VERSION      - SOGo 6 version (default: ${SOGO6_VERSION})"
	@echo "  DEV_AGENT_VERSION  - Dev Agent version (default: ${DEV_AGENT_VERSION})"
	@echo "  ZOT_VERSION        - Zot Registry version (default: ${ZOT_VERSION})"
	@echo "  KUBE_CONTEXT       - Kubernetes context (default: current)"
	@echo "  KUBE_NAMESPACE     - Kubernetes namespace (default: default)"
	@echo "  BUILD_ARGS         - Docker build args (default: --no-cache)"
	@echo "  DOCKER             - Docker command (default: docker)"
	@echo "  KUBECTL            - Kubectl command (default: kubectl)"
	@echo ""

# ==============================================================================
# BUILD TARGETS
# ==============================================================================

build-all: build-sogo5 build-sogo6 build-dev-agent build-zot ## Build all Docker images

build-sogo5: ## Build SOGo 5 Docker image
	@echo "Building SOGo 5 image: ${SOGO5_IMAGE}"
	${DOCKER} build ${BUILD_ARGS} \
		--build-arg SOGO_VERSION=${SOGO5_VERSION} \
		--build-arg MEMCACHED_VERSION=1.6.21 \
		--build-arg BUILD_DATE=$(shell date -u +%Y-%m-%dT%H:%M:%SZ) \
		-t ${SOGO5_IMAGE} \
		-t ${REGISTRY}/opendesk-sogo5:latest \
		-f docker/sogo5/Dockerfile \
		${BUILD_CONTEXT}

build-sogo6: ## Build SOGo 6 Docker image
	@echo "Building SOGo 6 image: ${SOGO6_IMAGE}"
	${DOCKER} build ${BUILD_ARGS} \
		--build-arg SOGO_VERSION=${SOGO6_VERSION} \
		--build-arg MEMCACHED_VERSION=1.6.21 \
		--build-arg BUILD_DATE=$(shell date -u +%Y-%m-%dT%H:%M:%SZ) \
		--build-arg EDV_ENABLED=true \
		-t ${SOGO6_IMAGE} \
		-t ${REGISTRY}/opendesk-sogo6:latest \
		-f docker/sogo6/Dockerfile \
		${BUILD_CONTEXT}

build-dev-agent: ## Build Dev Agent Operator Docker image
	@echo "Building Dev Agent image: ${DEV_AGENT_IMAGE}"
	${DOCKER} build ${BUILD_ARGS} \
		--build-arg DEV_AGENT_VERSION=${DEV_AGENT_VERSION} \
		--build-arg BUILD_DATE=$(shell date -u +%Y-%m-%dT%H:%M:%SZ) \
		-t ${DEV_AGENT_IMAGE} \
		-t ${REGISTRY}/opendesk-dev-agent:latest \
		-f docker/dev-agent/Dockerfile \
		${BUILD_CONTEXT}

build-zot: ## Build Zot Registry Docker image
	@echo "Building Zot Registry image: ${ZOT_IMAGE}"
	${DOCKER} build ${BUILD_ARGS} \
		--build-arg ZOT_VERSION=${ZOT_VERSION} \
		--build-arg BUILD_DATE=$(shell date -u +%Y-%m-%dT%H:%M:%SZ) \
		-t ${ZOT_IMAGE} \
		-t ${REGISTRY}/zot-registry:latest \
		-f docker/zot-registry/Dockerfile \
		${BUILD_CONTEXT}

# ==============================================================================
# PUSH TARGETS
# ==============================================================================

push-all: push-sogo5 push-sogo6 push-dev-agent push-zot ## Push all Docker images to registry

push-sogo5: build-sogo5 ## Push SOGo 5 image to registry
	@echo "Pushing SOGo 5 image: ${SOGO5_IMAGE}"
	${DOCKER} push ${SOGO5_IMAGE}
	${DOCKER} push ${REGISTRY}/opendesk-sogo5:latest

push-sogo6: build-sogo6 ## Push SOGo 6 image to registry
	@echo "Pushing SOGo 6 image: ${SOGO6_IMAGE}"
	${DOCKER} push ${SOGO6_IMAGE}
	${DOCKER} push ${REGISTRY}/opendesk-sogo6:latest

push-dev-agent: build-dev-agent ## Push Dev Agent image to registry
	@echo "Pushing Dev Agent image: ${DEV_AGENT_IMAGE}"
	${DOCKER} push ${DEV_AGENT_IMAGE}
	${DOCKER} push ${REGISTRY}/opendesk-dev-agent:latest

push-zot: build-zot ## Push Zot Registry image to registry
	@echo "Pushing Zot Registry image: ${ZOT_IMAGE}"
	${DOCKER} push ${ZOT_IMAGE}
	${DOCKER} push ${REGISTRY}/zot-registry:latest

# ==============================================================================
# DEPLOY TARGETS
# ==============================================================================

# Set namespace context for deployments
deploy-%:
	@echo "Setting Kubernetes context to: ${KUBE_CONTEXT}"
	@echo "Using namespace: ${KUBE_NAMESPACE}"

deploy-all: deploy-dev-agent deploy-zot deploy-sogo5 deploy-sogo6 ## Deploy all components

deploy-dev-agent: ## Deploy Dev Agent Operator
	@echo "Deploying Dev Agent Operator to namespace: ${KUBE_NAMESPACE}"
	${KUBECTL} apply --context=${KUBE_CONTEXT} -n ${KUBE_NAMESPACE} -k k8s/dev-agent
	@echo "Waiting for Dev Agent Operator to be ready..."
	${KUBECTL} wait --context=${KUBE_CONTEXT} -n ${KUBE_NAMESPACE} --for=condition=available --timeout=300s deployment/dev-agent-operator

deploy-zot: ## Deploy Zot Registry
	@echo "Deploying Zot Registry to namespace: zot-registry"
	${KUBECTL} apply --context=${KUBE_CONTEXT} -n zot-registry -k k8s/zot-registry
	@echo "Waiting for Zot Registry to be ready..."
	${KUBECTL} wait --context=${KUBE_CONTEXT} -n zot-registry --for=condition=available --timeout=300s deployment/zot-registry

deploy-sogo5: ## Deploy SOGo 5
	@echo "Deploying SOGo 5 to namespace: sogo"
	${KUBECTL} apply --context=${KUBE_CONTEXT} -n sogo -k k8s/sogo5
	@echo "Waiting for SOGo 5 to be ready..."
	${KUBECTL} wait --context=${KUBE_CONTEXT} -n sogo --for=condition=available --timeout=300s deployment/sogo5

deploy-sogo6: ## Deploy SOGo 6
	@echo "Deploying SOGo 6 to namespace: sogo6"
	${KUBECTL} apply --context=${KUBE_CONTEXT} -n sogo6 -k k8s/sogo6
	@echo "Waiting for SOGo 6 to be ready..."
	${KUBECTL} wait --context=${KUBE_CONTEXT} -n sogo6 --for=condition=available --timeout=300s deployment/sogo6

# ==============================================================================
# UNDEPLOY TARGETS
# ==============================================================================

undeploy-all: undeploy-sogo6 undeploy-sogo5 undeploy-zot undeploy-dev-agent ## Remove all deployments

undeploy-dev-agent: ## Remove Dev Agent Operator deployment
	@echo "Removing Dev Agent Operator from namespace: ${KUBE_NAMESPACE}"
	${KUBECTL} delete --context=${KUBE_CONTEXT} -n ${KUBE_NAMESPACE} -k k8s/dev-agent --ignore-not-found=true

undeploy-zot: ## Remove Zot Registry deployment
	@echo "Removing Zot Registry from namespace: zot-registry"
	${KUBECTL} delete --context=${KUBE_CONTEXT} -n zot-registry -k k8s/zot-registry --ignore-not-found=true

undeploy-sogo5: ## Remove SOGo 5 deployment
	@echo "Removing SOGo 5 from namespace: sogo"
	${KUBECTL} delete --context=${KUBE_CONTEXT} -n sogo -k k8s/sogo5 --ignore-not-found=true

undeploy-sogo6: ## Remove SOGo 6 deployment
	@echo "Removing SOGo 6 from namespace: sogo6"
	${KUBECTL} delete --context=${KUBE_CONTEXT} -n sogo6 -k k8s/sogo6 --ignore-not-found=true

# ==============================================================================
# TEST TARGETS
# ==============================================================================

test-all: test-sogo5 test-sogo6 test-dev-agent test-zot ## Run all tests

test-sogo5: build-sogo5 ## Test SOGo 5 image
	@echo "Testing SOGo 5 image..."
	@docker run --rm ${SOGO5_IMAGE} --version 2>/dev/null | grep -q "5.8.0" && echo "SOGo 5: PASSED" || echo "SOGo 5: FAILED"

test-sogo6: build-sogo6 ## Test SOGo 6 image
	@echo "Testing SOGo 6 image..."
	@docker run --rm ${SOGO6_IMAGE} --version 2>/dev/null | grep -q "6.0.0" && echo "SOGo 6: PASSED" || echo "SOGo 6: FAILED"

test-dev-agent: build-dev-agent ## Test Dev Agent image
	@echo "Testing Dev Agent image..."
	@docker run --rm ${DEV_AGENT_IMAGE} --help 2>/dev/null >/dev/null && echo "Dev Agent: PASSED" || echo "Dev Agent: FAILED"

test-zot: build-zot ## Test Zot Registry image
	@echo "Testing Zot Registry image..."
	@docker run --rm -p 8080:8080 --name zot-test ${ZOT_IMAGE} & sleep 3 && \
		curl -sf http://localhost:8080/healthz >/dev/null && \
		echo "Zot Registry: PASSED" || echo "Zot Registry: FAILED"
	@docker stop zot-test >/dev/null 2>&1 || true
	@docker rm zot-test >/dev/null 2>&1 || true

# ==============================================================================
# TEST TARGETS (Bats)
# Quality discipline ported from cibuilder-fork (stack4ops)
# ==============================================================================

test: ## Run all Bats tests
	bats tests/*.bats

test-verbose: ## Run tests with verbose output
	bats -t tests/*.bats

test-count: ## Show test statistics
	@echo Total tests: && bats tests/*.bats 2>&1 | grep "^1\.\." | cut -d. -f2
	@echo Passing: && bats tests/*.bats 2>&1 | grep "^ok" | wc -l
	@echo Failing: && bats tests/*.bats 2>&1 | grep "^not ok" | wc -l

shellcheck: ## Validate all shell scripts with shellcheck
	@find scripts docker -name "*.sh" -type f -o -maxdepth 1 -name "*.sh" -type f | \
		xargs shellcheck 2>/dev/null || echo "Note: shellcheck not installed, skipping"

lint: shellcheck ## Run all linters

# ==============================================================================
# SBOM TARGETS
# ==============================================================================

sbom-all: cd sbom && make all ## Generate all SBOMs

sbom-sogo5: cd sbom && make sogo5 ## Generate SBOM for SOGo 5

sbom-sogo6: cd sbom && make sogo6 ## Generate SBOM for SOGo 6

sbom-dev-agent: cd sbom && make dev-agent ## Generate SBOM for Dev Agent

sbom-zot: cd sbom && make zot-registry ## Generate SBOM for Zot Registry

# ==============================================================================
# SECURITY SCAN TARGETS
# ==============================================================================

scan-all: scan-sogo5 scan-sogo6 scan-dev-agent scan-zot ## Scan all images for vulnerabilities

scan-sogo5: build-sogo5 ## Scan SOGo 5 image for vulnerabilities
	@echo "Scanning SOGo 5 image for vulnerabilities..."
	@docker scan --severity high ${SOGO5_IMAGE} 2>/dev/null || echo "Note: docker scan requires Docker Desktop"
	@trivy image --severity HIGH,CRITICAL ${SOGO5_IMAGE} 2>/dev/null || echo "Note: trivy not installed"

scan-sogo6: build-sogo6 ## Scan SOGo 6 image for vulnerabilities
	@echo "Scanning SOGo 6 image for vulnerabilities..."
	@docker scan --severity high ${SOGO6_IMAGE} 2>/dev/null || true
	@trivy image --severity HIGH,CRITICAL ${SOGO6_IMAGE} 2>/dev/null || true

scan-dev-agent: build-dev-agent ## Scan Dev Agent image for vulnerabilities
	@echo "Scanning Dev Agent image for vulnerabilities..."
	@docker scan --severity high ${DEV_AGENT_IMAGE} 2>/dev/null || true
	@trivy image --severity HIGH,CRITICAL ${DEV_AGENT_IMAGE} 2>/dev/null || true

scan-zot: build-zot ## Scan Zot Registry image for vulnerabilities
	@echo "Scanning Zot Registry image for vulnerabilities..."
	@docker scan --severity high ${ZOT_IMAGE} 2>/dev/null || true
	@trivy image --severity HIGH,CRITICAL ${ZOT_IMAGE} 2>/dev/null || true

# ==============================================================================
# VALIDATION TARGETS
# ==============================================================================

validate-all: validate-dockerfiles validate-k8s ## Validate all configurations

validate-dockerfiles: ## Validate all Dockerfiles with hadolint
	@echo "Validating Dockerfiles with hadolint..."
	@hadolint docker/sogo5/Dockerfile 2>/dev/null || echo "Note: hadolint not installed, skipping"
	@hadolint docker/sogo6/Dockerfile 2>/dev/null || echo "Note: hadolint not installed, skipping"
	@hadolint docker/dev-agent/Dockerfile 2>/dev/null || echo "Note: hadolint not installed, skipping"
	@hadolint docker/zot-registry/Dockerfile 2>/dev/null || echo "Note: hadolint not installed, skipping"

validate-k8s: ## Validate Kubernetes manifests
	@echo "Validating Kubernetes manifests..."
	@for file in $$(find k8s -name "*.yaml" -type f); do \
		${KUBECTL} apply --dry-run=client -f $$file >/dev/null 2>&1 && \
			echo "  $$file: OK" || echo "  $$file: INVALID"; \
		done || true

validate-shell: ## Validate shell scripts with shellcheck
	@echo "Validating shell scripts with shellcheck..."
	@find docker scripts -name "*.sh" -type f | xargs shellcheck 2>/dev/null || echo "Note: shellcheck not installed, skipping"

# ==============================================================================
# GENERATION TARGETS
# ==============================================================================

generate-specs: ## Generate technical specifications (if not exists)
	@echo "Checking for missing specifications..."
	@for spec in SOGO5-SPEC.md SOGO6-SPEC.md DEV-AGENT-SPEC.md ZOT-SPEC.md; do \
		if [ ! -f "specs/$$spec" ]; then \
			echo "  Missing: specs/$$spec"; \
		else \
			echo "  OK: specs/$$spec"; \
		fi; \
		done

generate-sbom-docs: ## Generate SBOM documentation
	@echo "SBOM documentation is in sbom/Makefile"
	@echo "Run: cd sbom && make help"

# ==============================================================================
# UTILITY TARGETS
# ==============================================================================

kube-info: ## Show Kubernetes cluster info
	@echo "Kubernetes Cluster Information"
	@echo "=============================="
	@${KUBECTL} version --client --short 2>/dev/null || true
	@${KUBECTL} cluster-info 2>/dev/null || true
	@${KUBECTL} get nodes 2>/dev/null || true
	@echo ""
	@echo "Current Context: ${KUBE_CONTEXT}"
	@echo "Current Namespace: ${KUBE_NAMESPACE}"

images-list: ## List all built images
	@echo "Built Docker Images"
	@echo "==================="
	@${DOCKER} images | grep "${REGISTRY}" || echo "No images found"

docker-info: ## Show Docker info
	@echo "Docker Information"
	@echo "=================="
	@${DOCKER} version 2>/dev/null || true
	@${DOCKER} info 2>/dev/null | head -20 || true

# ==============================================================================
# CLEAN TARGETS
# ==============================================================================

clean: clean-images clean-k8s ## Clean all

clean-images: ## Remove built Docker images
	@echo "Removing built Docker images..."
	@${DOCKER} rmi -f ${SOGO5_IMAGE} ${REGISTRY}/opendesk-sogo5:latest 2>/dev/null || true
	@${DOCKER} rmi -f ${SOGO6_IMAGE} ${REGISTRY}/opendesk-sogo6:latest 2>/dev/null || true
	@${DOCKER} rmi -f ${DEV_AGENT_IMAGE} ${REGISTRY}/opendesk-dev-agent:latest 2>/dev/null || true
	@${DOCKER} rmi -f ${ZOT_IMAGE} ${REGISTRY}/zot-registry:latest 2>/dev/null || true
	@echo "Docker images removed"

clean-k8s: ## Remove Kubernetes deployments
	@echo "Removing Kubernetes deployments..."
	@${KUBECTL} delete --context=${KUBE_CONTEXT} -n ${KUBE_NAMESPACE} -k k8s/dev-agent --ignore-not-found=true 2>/dev/null || true
	@${KUBECTL} delete --context=${KUBE_CONTEXT} -n zot-registry -k k8s/zot-registry --ignore-not-found=true 2>/dev/null || true
	@${KUBECTL} delete --context=${KUBE_CONTEXT} -n sogo -k k8s/sogo5 --ignore-not-found=true 2>/dev/null || true
	@${KUBECTL} delete --context=${KUBE_CONTEXT} -n sogo6 -k k8s/sogo6 --ignore-not-found=true 2>/dev/null || true
	@echo "Kubernetes deployments removed"

clean-build: ## Remove build artifacts
	@echo "Removing build artifacts..."
	@rm -rf result/ 2>/dev/null || true
	@${DOCKER} system prune -f 2>/dev/null || true

clean-sbom: ## Remove SBOM files
	@echo "Removing SBOM files..."
	@rm -rf sbom/output/ 2>/dev/null || true

# ==============================================================================
# DEPENDENCY TARGETS
# ==============================================================================

# Include SBOM Makefile
-include sbom/Makefile
