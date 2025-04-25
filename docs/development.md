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

To make this persistent across sessions, consider adding these exports to your `.bashrc` or `.bash_profile`.

> **Note**: The first run will attempt to push operator images to your Quay.io namespace. Ensure the resulting repositories are made **public** or configure a **global pull secret** in your OpenShift or Kubernetes cluster to avoid image pull issues.

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
