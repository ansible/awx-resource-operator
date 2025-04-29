# ./up.sh

# -- Usage Notes
#
# If you are testing changes to the runner image and need to build it,
# you must specify the runner image in manager.yml to use it, or on the
# job CR as runner_image and runner_version. The default value is quay.io/$QUAY_USER/awx-resource-runner:dev

# -- Prepare

# Set default in manifest and crd files
files=(
    config/manager/manager.yaml
)
for file in "${files[@]}"; do
  if ! grep -qF 'imagePullPolicy:' ${file}; then
    sed -i -e "/image: controller:latest/a \\
        imagePullPolicy: Always" ${file};
  fi
done

# Set imagePullPolicy to Always
files=(
    config/manager/manager.yaml
)
for file in "${files[@]}"; do
  if grep -qF 'imagePullPolicy: IfNotPresent' ${file}; then
    sed -i -e "s|imagePullPolicy: IfNotPresent|imagePullPolicy: Always|g"  ${file};
  fi
done


#!/bin/bash
# AWX Resource Operator up.sh

# -- Usage
#   NAMESPACE=resource TAG=dev QUAY_USER=developer ./up.sh
#
# -- Environment Variables for AWX/Controller Connection
#   RESOURCE_SERVER_URL - URL of the AWX/Controller server
#   RESOURCE_SERVER_TOKEN - OAuth2 token for authentication
#
# -- Automatic OAuth2 Token Generation
#   If RESOURCE_SERVER_TOKEN is not set but the following variables are set,
#   the script will attempt to automatically create an OAuth2 token:
#   RESOURCE_SERVER_ADMIN_USER - Admin username
#   RESOURCE_SERVER_ADMIN_PASSWORD - Admin password

# -- User Variables
NAMESPACE=${NAMESPACE:-resource}
QUAY_USER=${QUAY_USER:-developer}
TAG=${TAG:-$(git rev-parse --short HEAD)}
DEV_TAG=${DEV_TAG:-dev}
DEV_TAG_PUSH=${DEV_TAG_PUSH:-true}

# -- Container Build Engine (podman or docker)
ENGINE=${ENGINE:-podman}

# -- Variables
IMG=quay.io/$QUAY_USER/awx-resource-operator
RUNNER_IMG=quay.io/$QUAY_USER/awx-resource-runner
KUBE_APPLY="kubectl apply -n $NAMESPACE -f"

# -- Wait for existing project to be deleted
# Function to check if the namespace is in terminating state
is_namespace_terminating() {
    oc get namespace $NAMESPACE 2>/dev/null | grep -q 'Terminating'
    return $?
}

# Check if the namespace exists and is in terminating state
if kubectl get namespace $NAMESPACE 2>/dev/null; then
    echo "Namespace $NAMESPACE exists."

    if is_namespace_terminating; then
        echo "Namespace $NAMESPACE is in terminating state. Waiting for it to be fully terminated..."
        while is_namespace_terminating; do
            sleep 5
        done
        echo "Namespace $NAMESPACE has been terminated."
    fi
fi


# -- Create namespace
kubectl create namespace $NAMESPACE


# -- Prepare

# Set imagePullPolicy to Always
files=(
    config/manager/manager.yaml
)
for file in "${files[@]}"; do
  if grep -qF 'imagePullPolicy: IfNotPresent' ${file}; then
    sed -i -e "s|imagePullPolicy: IfNotPresent|imagePullPolicy: Always|g" ${file};
  fi
done


# -- Cleanup old operator
oc delete deployment/resource-operator-controller-manager

# -- Login to Quay.io
$ENGINE login quay.io

if [ $ENGINE = 'podman' ]; then
  if [ -f "$XDG_RUNTIME_DIR/containers/auth.json" ] ; then
    REGISTRY_AUTH_CONFIG=$XDG_RUNTIME_DIR/containers/auth.json
    echo "Found registry auth config: $REGISTRY_AUTH_CONFIG"
  elif [ -f $HOME/.config/containers/auth.json ] ; then
    REGISTRY_AUTH_CONFIG=$HOME/.config/containers/auth.json
    echo "Found registry auth config: $REGISTRY_AUTH_CONFIG"
  elif [ -f "/home/$USER/.docker/config.json" ] ; then
    REGISTRY_AUTH_CONFIG=/home/$USER/.docker/config.json
    echo "Found registry auth config: $REGISTRY_AUTH_CONFIG"
  else
    echo "No Podman configuration files were found."
  fi
fi

if [ $ENGINE = 'docker' ]; then
  if [ -f "/home/$USER/.docker/config.json" ] ; then
	  REGISTRY_AUTH_CONFIG=/home/$USER/.docker/config.json
    echo "Found registry auth config: $REGISTRY_AUTH_CONFIG"
  else
    echo "No Docker configuration files were found."
  fi
fi

# Build Resource Runner images
make docker-build docker-push IMG=$RUNNER_IMG:$TAG

make docker-push IMG=$RUNNER_IMG:$DEV_TAG

docker build -t $RUNNER_IMG:$TAG -f Dockerfile.runner .
docker push $RUNNER_IMG:$TAG # must specify this in manager.yml to use it, or on the job CR as runner_image and runner_version


# -- Build & Push Operator Image
echo "Preparing to build $IMG:$TAG ($IMG:$DEV_TAG) with $ENGINE..."
sleep 3
make docker-build docker-push IMG=$IMG:$TAG

# Tag and Push DEV_TAG Image when DEV_TAG_PUSH is 'True'
if $DEV_TAG_PUSH ; then
  $ENGINE tag $IMG:$TAG $IMG:$DEV_TAG
  make docker-push IMG=$IMG:$DEV_TAG
fi

# -- Deploy Operator
make deploy IMG=$IMG:$TAG NAMESPACE=$NAMESPACE

# Deploy Operator
NAMESPACE=$NAMESPACE IMG=quay.io/chadams/awx-resource-operator:$TAG make deploy # RUNNER_IMG=quay.io/chadams/awx-resource-runner:dev

# -- Check for admin credentials and create OAuth2 token if available
if [ -n "$RESOURCE_SERVER_ADMIN_USER" ] && [ -n "$RESOURCE_SERVER_ADMIN_PASSWORD" ] && [ -n "$RESOURCE_SERVER_URL" ] && [ -z "$RESOURCE_SERVER_TOKEN" ]; then
    echo "Admin credentials found. Attempting to create OAuth2 token..."

    # Check if ansible-playbook is available
    if command -v ansible-playbook &> /dev/null; then
        # Run the playbook to create the token
        ANSIBLE_STDOUT_CALLBACK=json ansible-playbook dev/create_oauth2_token.yml > token_output.json

        # Extract the token from the playbook output
        if [ -f token_output.json ]; then
            RESOURCE_SERVER_TOKEN=$(grep -o '"oauth2_token": "[^"]*"' token_output.json | cut -d'"' -f4)
            if [ -n "$RESOURCE_SERVER_TOKEN" ]; then
                echo "OAuth2 token created successfully."
                # Clean up temporary files
                rm -f token_output.json
            else
                echo "Failed to extract OAuth2 token from playbook output."
            fi
        else
            echo "Playbook execution failed or output file not created."
        fi
    else
        echo "ansible-playbook command not found. Cannot create OAuth2 token automatically."
        echo "Please install ansible or set RESOURCE_SERVER_TOKEN manually."
    fi
fi

# -- Create connection secret using environment variables
if [ -z "$RESOURCE_SERVER_URL" ] || [ -z "$RESOURCE_SERVER_TOKEN" ]; then
    echo "Warning: RESOURCE_SERVER_URL and/or RESOURCE_SERVER_TOKEN not set. Skipping connection secret creation."
else
    cat <<EOF | kubectl apply -n $NAMESPACE -f -
---
apiVersion: v1
kind: Secret
metadata:
  name: awxaccess
stringData:
  host: "${RESOURCE_SERVER_URL}"
  token: "${RESOURCE_SERVER_TOKEN}"
type: Opaque
EOF
    echo "Created connection secret 'awxaccess' in namespace $NAMESPACE"
fi


# Create custom resources
#oc create -f awxaccess-secret.yml
#oc create -f launch_jt_cr.yml
