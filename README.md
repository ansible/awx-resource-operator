# Ansible Tower/AWX Resource Operator

---
> **_NOTE:_** This operator is experimental and is not considered supported or stable and ready for use
---

This purpose of this operator is to allow managing one or more Tower and AWX cluster resources. This also attempts to lay out a general model for how to interface with individual resources whether running within an Openshift cluster or being managed off-cluster.

## Existing CRDs and Roles

Currently two CRDs are implemented with backing roles:

* Job Template [CRD](deploy/crds/tower.ansible.com_jobtemplates_crd.yaml) and [Role](roles/jobtemplate/tasks/main.yml) will create a Job Template against the referenced Tower cluster
* AnsibleJob [CRD](deploy/crds/tower.ansible.com_joblaunch_crd.yaml) and [Role](roles/job/tasks/main.yml) given a Job Template name will run a job on the referenced Tower cluster

## Connectivity Secrets

All CRDs within this operator depend on a _Secret_ being defined within the desired namespace and this secret name must be given along with any of the CRs that wish, the _Secret_ itself has a particular k/v format:

    apiVersion: v1
    kind: Secret
    metadata:
      name: toweraccess
      namespace: aproject
      type: Opaque
    stringData:
      token: XXXXX
      host: https://towerhost.com

## Building the Operator

The current codebase has a fixed image location and should be modified, the examples below should also be modified to publish the images into a specific location. Start with building the operator image and publishing:

    $ operator-sdk build matburt/tower-resource-operator:0.1.0
    ...
    $ docker push matburt/tower-resource-operator:0.1.0
    ...

## Building the Job launch job container

The Tower Job launch CRD launches a k8s job in a dependent fashion. The k8s Job actually invokes the Tower Job and tracks it, this container needs to be built and published:

    $ docker build -t matburt/operator-job-run:latest -f build/Dockerfile.runner .

