# opeator image
IMG_OPERATOR ?= quay.io/open-cluster-management/platform-resource-operator:latest
# runner image
IMG_RUNNER ?= quay.io/open-cluster-management/platform-resource-runner:latest
# bundle image version
BUNDEL_VERSION ?= 0.1.1
# bundle image
IMG_BUNDLE ?= quay.io/open-cluster-management/platform-resource-operator-bundle:$(BUNDEL_VERSION)

PATH  := $(PATH):$(PWD)/bin
SHELL := env PATH=$(PATH) /bin/sh
OS    = $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH  = $(shell uname -m | sed 's/x86_64/amd64/')
OSOPER   = $(shell uname -s | tr '[:upper:]' '[:lower:]' | sed 's/darwin/apple-darwin/' | sed 's/linux/linux-gnu/')
ARCHOPER = $(shell uname -m )
_OPERATOR_SDK_VERSION ?= v0.18.2

############################################################
# dependency section
############################################################

operator-sdk:
ifeq (, $(shell which operator-sdk 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p bin ;\
	curl -LO https://github.com/operator-framework/operator-sdk/releases/download/${_OPERATOR_SDK_VERSION}/operator-sdk-${_OPERATOR_SDK_VERSION}-$(ARCHOPER)-$(OSOPER) ;\
	mv operator-sdk-${_OPERATOR_SDK_VERSION}-$(ARCHOPER)-$(OSOPER) ./bin/operator-sdk ;\
	chmod +x ./bin/operator-sdk ;\
	}
OPERATOR_SDK=$(realpath ./bin/operator-sdk)
else
OPERATOR_SDK=$(shell which operator-sdk)
endif

############################################################
# images section
############################################################

build-operator:
	docker build . -t ${IMG_OPERATOR} -f build/Dockerfile

build-runner:
	docker build . -t ${IMG_RUNNER} -f build/Dockerfile.runner

build-bundle:
	cd deploy/olm-catalog/awx-resource-operator/ ;\
	docker build -f $(BUNDEL_VERSION)/bundle-$(BUNDEL_VERSION).Dockerfile -t $(IMG_BUNDLE) . ;\
	cd $(PWD)

validate-bundle: operator-sdk
	${OPERATOR_SDK} bundle validate $(IMG_BUNDLE)

############################################################
# publish section
# prerequisite:
# docker login quay.io/open-cluster-management with valid credential
############################################################

publish-operator:
	docker push ${IMG_OPERATOR}

publish-runner:
	docker push ${IMG_RUNNER}

publish-bundle:
	docker push ${IMG_BUNDLE}
