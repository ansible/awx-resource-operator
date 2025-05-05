# Development Guide – `awx-resource-operator`

This guide covers how to build, deploy, and test the `awx-resource-operator` locally using helper scripts and development manifests.

The [`dev/`](../dev) directory contains YAML examples and helper resources, and the root of the repo includes `up.sh` and `down.sh` scripts to streamline development and testing.

---

## Build and Deploy

After cloning the repository and logging in to your OpenShift or Kubernetes cluster via the CLI (`oc` or `kubectl`), you can bring up the operator and its resources with the following commands:

```bash
export QUAY_USER=username
export NAMESPACE=resource
export TAG=test
./up.sh
```

---

## Connection Secret Configuration

The operator requires a connection secret to communicate with your AWX instance. There are two ways to configure this:

### Option 1: Automatic OAuth2 Token Generation (Recommended)

The operator can automatically generate an OAuth2 token using admin credentials. Simply set these environment variables:

```bash
export RESOURCE_SERVER_URL="https://your-awx-instance.com"
export RESOURCE_SERVER_ADMIN_USER="admin"
export RESOURCE_SERVER_ADMIN_PASSWORD="password"
```

When these variables are set, `up.sh` will:
1. Automatically generate an OAuth2 token using the provided credentials
2. Create a connection secret named `awxaccess` in your specified namespace
3. Configure the operator to use this connection

> **Note**: This method requires `ansible-playbook` to be installed on your system.

### Option 2: Using an Existing OAuth2 Token

If you prefer to use an existing token or cannot use automatic generation, set these environment variables:

```bash
export RESOURCE_SERVER_URL="https://your-awx-instance.com"
export RESOURCE_SERVER_TOKEN="your-awx-token"
```

For information about manually creating tokens in AWX, see the [AWX documentation on token creation](https://docs.ansible.com/automation-controller/latest/html/userguide/applications_auth.html#add-tokens).

If neither option's variables are set, the script will display a warning and skip secret creation.

---

## Using the Resource Operator

You can now create a connection k8s secret to connect to your AWX instance, then try out some of the sample job templates and jobs in the config/samples directory. See the top level [README.md](../README.md) for more information on how to do that.

---

## Clean Up

To tear down your development namespace and resources:

```bash
./down.sh
```

This will delete the namespace you specified (via `NAMESPACE`) and all related resources.

---

## Running CI Tests Locally

Basic linting and CI checks can be run with:

```bash
make lint
```

Additional test coverage and integration tests will be added in future updates.

---

Let me know if you'd like a separate section on debugging or pushing updated manifests for CRDs or CSVs!
