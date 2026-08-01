# Makefile for openDesk-Nix
# Usage: make <target>
#
# Targets:
#   all              - Build all images
#   sogo5            - Build SOGo 5 image
#   sogo6            - Build SOGo 6 image
#   dev-agent        - Build Dev Agent image
#   push             - Push all images to GitLab registry
#   push-sogo5       - Push SOGo 5 only
#   push-sogo6       - Push SOGo 6 only
#   push-dev-agent   - Push Dev Agent only
#   load-all         - Load all built images into Docker
#   deploy-sogo5     - Deploy SOGo 5 to Kubernetes
#   deploy-sogo6     - Deploy SOGo 6 to Kubernetes
#   deploy-dev-agent - Deploy Dev Agent to Kubernetes
#   clean            - Remove all build artifacts
#   flake.update     - Update flake inputs
#   shell            - Enter development shell

# Configuration
REGISTRY := registry.gitlab.opencode.de/umr
DOCKER_USER ?= weiss
NIX_BUILD_DIR ?= .
K8S_NAMESPACE ?= opendesk

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_\-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

.PHONY: all
all: sogo5 sogo6 dev-agent ## Build all images

.PHONY: sogo5
sogo5: ## Build SOGo 5 Docker image
	@echo "🚀 Building SOGo 5 image..."
	cd $(NIX_BUILD_DIR) && nix build .#sogo5-image
	@echo "✅ SOGo 5 image built"

.PHONY: sogo6
sogo6: ## Build SOGo 6 Docker image
	@echo "🚀 Building SOGo 6 image..."
	cd $(NIX_BUILD_DIR) && nix build .#sogo6-image
	@echo "✅ SOGo 6 image built"

.PHONY: dev-agent
dev-agent: ## Build Dev Agent Docker image
	@echo "🚀 Building Dev Agent image..."
	cd $(NIX_BUILD_DIR) && nix build .#dev-agent-image
	@echo "✅ Dev Agent image built"

.PHONY: website
website: ## Build Website Docker image
	@echo "🚀 Building Website image..."
	cd $(NIX_BUILD_DIR) && nix build .#website-image 2>/dev/null || \
		(cd ../opendesk-edu-website && docker build -t $(REGISTRY)/opendesk-edu-website:latest .)
	@echo "✅ Website image built"

.PHONY: sbom-generator
sbom-generator: ## Build SBOM Generator Docker image
	@echo "🚀 Building SBOM Generator image..."
	cd $(NIX_BUILD_DIR) && nix build .#sbom-generator-image 2>/dev/null || \
		(cd ../opendesk-edu-website && docker build -t $(REGISTRY)/sbom-generator:latest -f docker/sbom-generator/Dockerfile .)
	@echo "✅ SBOM Generator image built"

# Push targets
.PHONY: push
push: push-sogo5 push-sogo6 push-dev-agent ## Push all images to GitLab registry

.PHONY: login
login: ## Login to GitLab Container Registry
	@if [ -z "$$OPENCODE_TOKEN" ]; then \
		echo "Please enter your GitLab opencode.de PAT:"; \
		read -rs OPENCODE_TOKEN; \
	fi; \
	echo "$$OPENCODE_TOKEN" | docker login $(REGISTRY) -u $(DOCKER_USER) --password-stdin
	@echo "✅ Login successful"

.PHONY: push-sogo5
push-sogo5: login ## Push SOGo 5 to registry
	@echo "📤 Pushing SOGo 5..."
	cd $(NIX_BUILD_DIR) && \
	
docker load < result 2>/dev/null || true
	@docker tag $(shell docker images -q | head -1) $(REGISTRY)/sogo5:latest
	docker push $(REGISTRY)/sogo5:latest
	@echo "✅ SOGo 5 pushed"

.PHONY: push-sogo6
push-sogo6: login ## Push SOGo 6 to registry
	@echo "📤 Pushing SOGo 6..."
	cd $(NIX_BUILD_DIR) && \
	
docker load < result 2>/dev/null || true
	@docker tag $(shell docker images -q | head -1) $(REGISTRY)/sogo6:latest
	docker push $(REGISTRY)/sogo6:latest
	@echo "✅ SOGo 6 pushed"

.PHONY: push-dev-agent
push-dev-agent: login ## Push Dev Agent to registry
	@echo "📤 Pushing Dev Agent..."
	cd $(NIX_BUILD_DIR) && \
	
docker load < result 2>/dev/null || true
	@docker tag $(shell docker images -q | head -1) $(REGISTRY)/dev-agent:latest
	docker push $(REGISTRY)/dev-agent:latest
	@echo "✅ Dev Agent pushed"

.PHONY: push-website
push-website: login ## Push Website to registry
	@echo "📤 Pushing Website..."
	cd ../opendesk-edu-website && \
	
docker build -t $(REGISTRY)/opendesk-edu-website:latest . && \
	docker push $(REGISTRY)/opendesk-edu-website:latest
	@echo "✅ Website pushed"

.PHONY: push-sbom-generator
push-sbom-generator: login ## Push SBOM Generator to registry
	@echo "📤 Pushing SBOM Generator..."
	cd ../opendesk-edu-website && \
	
docker build -t $(REGISTRY)/sbom-generator:latest -f docker/sbom-generator/Dockerfile . && \
	docker push $(REGISTRY)/sbom-generator:latest
	@echo "✅ SBOM Generator pushed"

# Load targets
.PHONY: load-all
load-all: load-sogo5 load-sogo6 load-dev-agent ## Load all images into Docker

.PHONY: load-sogo5
load-sogo5: ## Load SOGo 5 into Docker
	@echo "🐳 Loading SOGo 5..."
	cd $(NIX_BUILD_DIR) && docker load < result
	@echo "✅ SOGo 5 loaded"

.PHONY: load-sogo6
load-sogo6: ## Load SOGo 6 into Docker
	@echo "🐳 Loading SOGo 6..."
	cd $(NIX_BUILD_DIR) && docker load < result
	@echo "✅ SOGo 6 loaded"

.PHONY: load-dev-agent
load-dev-agent: ## Load Dev Agent into Docker
	@echo "🐳 Loading Dev Agent..."
	cd $(NIX_BUILD_DIR) && docker load < result
	@echo "✅ Dev Agent loaded"

# Deploy targets
.PHONY: deploy
deploy: deploy-sogo5 deploy-sogo6 deploy-dev-agent ## Deploy all to Kubernetes

.PHONY: deploy-sogo5
deploy-sogo5: ## Deploy SOGo 5 to Kubernetes
	@echo "🔧 Deploying SOGo 5..."
	kubectl apply -k k8s/sogo5
	@echo "✅ SOGo 5 deployed"

.PHONY: deploy-sogo6
deploy-sogo6: ## Deploy SOGo 6 to Kubernetes
	@echo "🔧 Deploying SOGo 6..."
	kubectl apply -k k8s/sogo6
	@echo "✅ SOGo 6 deployed"

.PHONY: deploy-dev-agent
deploy-dev-agent: ## Deploy Dev Agent to Kubernetes
	@echo "🔧 Deploying Dev Agent..."
	kubectl apply -k k8s/dev-agent
	@echo "✅ Dev Agent deployed"

.PHONY: deploy-website
deploy-website: ## Deploy Website to Kubernetes
	@echo "🔧 Deploying Website..."
	kubectl apply -k k8s/website 2>/dev/null || echo "Website K8s configs not found"
	@echo "✅ Website deployed"

# Kubernetes setup
.PHONY: create-pull-secret
create-pull-secret: ## Create GitLab pull secret
	@if [ -z "$$OPENCODE_TOKEN" ]; then \
		echo "Please enter your GitLab opencode.de PAT:"; \
		read -rs OPENCODE_TOKEN; \
	fi; \
	kubectl create secret docker-registry gitlab-registry-opencode \
		--docker-server=$(REGISTRY) \
		--docker-username=$(DOCKER_USER) \
		--docker-password=$$OPENCODE_TOKEN \
		--docker-email=tobias.weiss@hrz.uni-marburg.de \
		--dry-run=client -o yaml > k8s/gitlab-registry-secret.yaml
	@echo "✅ Pull secret created at k8s/gitlab-registry-secret.yaml"
	@echo "  Apply with: kubectl apply -f k8s/gitlab-registry-secret.yaml"

.PHONY: setup-k8s
setup-k8s: create-pull-secret ## Setup Kubernetes for GitLab registry
	@echo "🔧 Setting up Kubernetes..."
	@kubectl create namespace $(K8S_NAMESPACE) 2>/dev/null || true
	kubectl apply -f k8s/gitlab-registry-secret.yaml
	@echo "✅ Kubernetes setup complete"

# Cleanup
.PHONY: clean
clean: ## Clean all build artifacts
	@echo "🧹 Cleaning..."
	cd $(NIX_BUILD_DIR) && rm -rf result gcroots per-user
	docker system prune -f 2>/dev/null || true
	@echo "✅ Cleanup complete"

.PHONY: flake.update
flake.update: ## Update flake inputs
	@echo "🔄 Updating flake inputs..."
	cd $(NIX_BUILD_DIR) && nix flake update
	@echo "✅ Flake inputs updated"

.PHONY: shell
shell: ## Enter development shell
	@echo "🐚 Entering development shell..."
	cd $(NIX_BUILD_DIR) && nix develop

.PHONY: flake.show
flake.show: ## Show available packages
	@echo "📋 Available packages:"
	cd $(NIX_BUILD_DIR) && nix flake show

.PHONY: verify
verify: ## Verify all images can be built
	@echo "🔍 Verifying all images..."
	@nix build .#sogo5-image && echo "✅ SOGo 5: OK" || echo "❌ SOGo 5: FAILED"
	@nix build .#sogo6-image && echo "✅ SOGo 6: OK" || echo "❌ SOGo 6: FAILED"
	@nix build .#dev-agent-image && echo "✅ Dev Agent: OK" || echo "❌ Dev Agent: FAILED"
	@echo "✅ Verification complete"

# CI/CD targets
.PHONY: ci-build
ci-build: all ## Build all images for CI

.PHONY: ci-push
ci-push: push ## Push all images for CI

# Helper targets
.PHONY: list-images
list-images: ## List built Docker images
	@echo "🐳 Built Docker images:"
	@docker images | grep $(REGISTRY)

.PHONY: list-pods
list-pods: ## List running pods
	@echo "🔧 Running pods:"
	@kubectl get pods -n $(K8S_NAMESPACE)

.PHONY: version
version: ## Show version info
	@echo "openDesk-Nix v1.0.0"
	@echo "Nix Version: $(shell nix --version 2>/dev/null || echo 'not installed')"
	@echo "Docker Version: $(shell docker --version 2>/dev/null || echo 'not installed')"
	@echo "Kubectl Version: $(shell kubectl version --client --short 2>/dev/null || echo 'not installed')"
