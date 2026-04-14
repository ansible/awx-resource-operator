# operator.mk — AWX Resource Operator specific targets and variables
#
# This file is NOT synced across repos. Each operator maintains its own.

#@ Operator Variables

VERSION ?= $(shell git describe --tags 2>/dev/null || echo 0.2.0)
IMAGE_TAG_BASE ?= quay.io/ansible/awx-resource-operator
NAMESPACE ?= resource
DEPLOYMENT_NAME ?= resource-operator-controller-manager

# Runner image: follows QUAY_USER override like the operator image
RUNNER_IMAGE_TAG_BASE ?= quay.io/ansible/awx-resource-runner
RUNNER_VERSION ?= $(VERSION)
_RUNNER_NAME = $(notdir $(RUNNER_IMAGE_TAG_BASE))
DEV_RUNNER_IMG ?= $(if $(QUAY_USER),quay.io/$(QUAY_USER)/$(_RUNNER_NAME),$(RUNNER_IMAGE_TAG_BASE))
RUNNER_IMG ?= $(DEV_RUNNER_IMG):$(RUNNER_VERSION)

# AWX connection
AWX_NAMESPACE ?= awx

# Feature flags
BUILD_IMAGE ?= true
BUILD_RUNNER ?= true
CREATE_CR ?= false

# Teardown configuration
TEARDOWN_CR_KINDS ?= ansiblejob jobtemplate ansibleproject ansibleworkflow ansiblecredential ansibleschedule ansibleinstancegroup workflowtemplate ansibleinventory
TEARDOWN_BACKUP_KINDS ?=
TEARDOWN_RESTORE_KINDS ?=
OLM_SUBSCRIPTIONS ?=

##@ AWX Resource Operator

.PHONY: operator-up
operator-up: _operator-build-and-push _resource-build-runner _operator-deploy _operator-wait-ready _operator-post-deploy _connection-secret ## AWX Resource-specific deploy
	@:

.PHONY: _resource-build-runner
_resource-build-runner:
	@if [ "$(BUILD_IMAGE)" != "true" ] || [ "$(BUILD_RUNNER)" != "true" ]; then exit 0; fi
	@echo "Building runner image $(RUNNER_IMG)..."
	@$(_CONTAINER_CMD) build -f Dockerfile.runner -t $(RUNNER_IMG) .
	@echo "Pushing $(RUNNER_IMG)..."
	@$(_CONTAINER_CMD) push $(RUNNER_IMG)

.PHONY: _connection-secret
_connection-secret:
	@if [ -n "$(RESOURCE_SERVER_ADMIN_USER)" ] && [ -n "$(RESOURCE_SERVER_ADMIN_PASSWORD)" ] && [ -n "$(RESOURCE_SERVER_URL)" ] && [ -z "$(RESOURCE_SERVER_TOKEN)" ]; then \
		echo "Admin credentials found. Creating OAuth2 token..."; \
		if command -v ansible-playbook >/dev/null 2>&1; then \
			ANSIBLE_STDOUT_CALLBACK=json ansible-playbook dev/create_oauth2_token.yml > /tmp/token_output.json; \
			TOKEN=$$(grep -o '"oauth2_token": "[^"]*"' /tmp/token_output.json | cut -d'"' -f4); \
			rm -f /tmp/token_output.json; \
			if [ -n "$$TOKEN" ]; then \
				echo "OAuth2 token created successfully."; \
				$(KUBECTL) create secret generic awxaccess -n $(NAMESPACE) \
					--from-literal=host="$(RESOURCE_SERVER_URL)" \
					--from-literal=token="$$TOKEN" \
					--dry-run=client -o yaml | $(KUBECTL) apply -f -; \
				echo "Created connection secret 'awxaccess' in namespace $(NAMESPACE)"; \
			else \
				echo "WARNING: Failed to extract OAuth2 token from playbook output."; \
			fi; \
		else \
			echo "WARNING: ansible-playbook not found. Set RESOURCE_SERVER_TOKEN manually."; \
		fi; \
	elif [ -n "$(RESOURCE_SERVER_URL)" ] && [ -n "$(RESOURCE_SERVER_TOKEN)" ]; then \
		$(KUBECTL) create secret generic awxaccess -n $(NAMESPACE) \
			--from-literal=host="$(RESOURCE_SERVER_URL)" \
			--from-literal=token="$(RESOURCE_SERVER_TOKEN)" \
			--dry-run=client -o yaml | $(KUBECTL) apply -f -; \
		echo "Created connection secret 'awxaccess' in namespace $(NAMESPACE)"; \
	else \
		echo "No RESOURCE_SERVER_URL/TOKEN set. Skipping connection secret."; \
	fi

.PHONY: awx-url
awx-url: ## Discover AWX route URL (use AWX_NAMESPACE to set namespace, default: awx)
	@URL=$$($(KUBECTL) get route -n $(AWX_NAMESPACE) -l app.kubernetes.io/managed-by=awx-operator \
		-o jsonpath='https://{.items[0].spec.host}' 2>/dev/null); \
	if [ -z "$$URL" ] || [ "$$URL" = "https://" ]; then \
		echo "ERROR: No AWX route found in namespace $(AWX_NAMESPACE)" >&2; \
		exit 1; \
	fi; \
	echo "$$URL"

##@ Runner

.PHONY: runner-build
runner-build: ## Build job runner image.
	$(_CONTAINER_CMD) build -f Dockerfile.runner -t $(RUNNER_IMG) .

.PHONY: runner-push
runner-push: ## Push job runner image.
	$(_CONTAINER_CMD) push $(RUNNER_IMG)

.PHONY: runner-podman-buildx
runner-podman-buildx: ## Build and push runner image for cross-platform support
	podman build --platform=$(PLATFORMS) --manifest $(RUNNER_IMG) -f Dockerfile.runner .
	podman manifest push --all $(RUNNER_IMG)
