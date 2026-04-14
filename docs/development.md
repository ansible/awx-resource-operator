# Development Guide

There are development yaml examples in the [`dev/`](../dev) directory and Makefile targets that can be used to build, deploy and test changes made to the awx-resource-operator.

Run `make help` to see all available targets and options.


## Prerequisites

You will need to have the following tools installed:

* [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
* [podman](https://podman.io/docs/installation) or [docker](https://docs.docker.com/get-docker/)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [oc](https://docs.openshift.com/container-platform/4.11/cli_reference/openshift_cli/getting-started-cli.html) (if using OpenShift)

You will also need:
* A container registry account (this guide uses [quay.io](https://quay.io))
* A running AWX instance (deployed via [awx-operator](https://github.com/ansible/awx-operator))


## Registry Setup

1. Go to [quay.io](https://quay.io) and create a repository named `awx-resource-operator` under your username.
2. Login at the CLI:
```sh
podman login quay.io
```

> **Note**: The first time you run `make up`, it will create quay.io repos on your fork. You will need to either make those public or create a global pull secret on your cluster.


## Build and Deploy

The resource operator requires a running AWX instance. Make sure you are logged into your cluster (`oc login` or `kubectl` configured), then run:

```sh
# Discover the AWX URL from your cluster (AWX_NAMESPACE defaults to 'awx')
make awx-url AWX_NAMESPACE=awx

# Deploy the operator with AWX connection
RESOURCE_SERVER_URL=https://your-awx-route \
  RESOURCE_SERVER_ADMIN_USER=admin \
  RESOURCE_SERVER_ADMIN_PASSWORD=password \
  QUAY_USER=username make up
```

This will:
1. Login to container registries
2. Create the target namespace
3. Build the operator and runner images and push them to your registry
4. Deploy the operator via kustomize
5. Create a connection secret to AWX (see [Connection Secret Configuration](#connection-secret-configuration))

### Customization Options

| Variable | Default | Description |
|----------|---------|-------------|
| `QUAY_USER` | _(required)_ | Your quay.io username |
| `AWX_NAMESPACE` | `awx` | Namespace where AWX is running (used by `make awx-url`) |
| `NAMESPACE` | `resource` | Target namespace |
| `DEV_TAG` | `dev` | Image tag for dev builds |
| `CONTAINER_TOOL` | `podman` | Container engine (`podman` or `docker`) |
| `PLATFORM` | _(auto-detected)_ | Target platform (e.g., `linux/amd64`) |
| `MULTI_ARCH` | `false` | Build multi-arch image (`linux/arm64,linux/amd64`) |
| `DEV_IMG` | `quay.io/<QUAY_USER>/awx-resource-operator` | Override full image path (skips QUAY_USER) |
| `BUILD_IMAGE` | `true` | Set to `false` to skip operator image build |
| `BUILD_RUNNER` | `true` | Set to `false` to skip runner image build |
| `IMAGE_PULL_POLICY` | `Always` | Set to `Never` for local builds without push |
| `BUILD_ARGS` | _(empty)_ | Extra args passed to container build (e.g., `--no-cache`) |
| `PODMAN_CONNECTION` | _(empty)_ | Remote podman connection name |

Examples:

```bash
# Use a specific namespace and tag
QUAY_USER=username NAMESPACE=resource DEV_TAG=mytag make up

# Use docker instead of podman
CONTAINER_TOOL=docker QUAY_USER=username make up

# Build for a specific platform (e.g., when on ARM building for x86)
PLATFORM=linux/amd64 QUAY_USER=username make up

# Deploy without building (use an existing image)
BUILD_IMAGE=false DEV_IMG=quay.io/myuser/awx-resource-operator DEV_TAG=latest make up
```


## Connection Secret Configuration

The operator requires a connection secret to communicate with your AWX instance. There are two ways to configure this:

### Option 1: Automatic OAuth2 Token Generation (Recommended)

The operator can automatically generate an OAuth2 token using admin credentials. Set these environment variables before running `make up`:

```bash
export RESOURCE_SERVER_URL="https://your-awx-instance.com"
export RESOURCE_SERVER_ADMIN_USER="admin"
export RESOURCE_SERVER_ADMIN_PASSWORD="password"
```

> **Note**: This method requires `ansible-playbook` to be installed on your system.

### Option 2: Using an Existing OAuth2 Token

If you prefer to use an existing token, set these environment variables:

```bash
export RESOURCE_SERVER_URL="https://your-awx-instance.com"
export RESOURCE_SERVER_TOKEN="your-awx-token"
```

For information about manually creating tokens in AWX, see the [AWX documentation on token creation](https://docs.ansible.com/automation-controller/4.4/html/userguide/applications_auth.html#add-tokens).


## Using the Resource Operator

After deployment, you can create resources to manage your AWX instance. See the sample job templates and jobs in the [`dev/`](../dev) directory and the top-level [README.md](../README.md) for detailed usage instructions.


## Clean up

To tear down your development deployment:

```sh
make down
```

### Teardown Options

| Variable | Default | Description |
|----------|---------|-------------|
| `KEEP_NAMESPACE` | `false` | Set to `true` to keep the namespace for reuse |
| `DELETE_PVCS` | `true` | Set to `false` to preserve PersistentVolumeClaims |
| `DELETE_SECRETS` | `true` | Set to `false` to preserve secrets |

Examples:

```bash
# Keep the namespace for faster redeploy
KEEP_NAMESPACE=true make down

# Keep PVCs (preserve data between deploys)
DELETE_PVCS=false make down
```


## Testing

### Linting

Run linting checks (required for all PRs):

```sh
make lint
```


## Bundle Generation

If you have the Operator Lifecycle Manager (OLM) installed, you can generate and deploy an operator bundle:

```bash
# Generate bundle manifests and validate
make bundle

# Build and push the bundle image
make bundle-build bundle-push

# Build and push a catalog image
make catalog-build catalog-push
```

After pushing the catalog, create a `CatalogSource` in your cluster pointing to the catalog image. Once the CatalogSource is in a READY state, the operator will be available in OperatorHub.
