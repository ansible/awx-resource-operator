#!/bin/bash
# AWX Resource Operator down.sh

# -- Usage
#   NAMESPACE=resource ./down.sh

# -- Variables
NAMESPACE=${NAMESPACE:-resource}
TAG=${TAG:-dev}
QUAY_USER=${QUAY_USER:-developer}
IMG=quay.io/$QUAY_USER/eda-server-operator:$TAG

# Delete old operator deployment
oc delete deployment resource-operator-controller-manager

# Deploy Operator
make undeploy IMG=$IMG NAMESPACE=$NAMESPACE

