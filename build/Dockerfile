FROM registry.redhat.io/openshift4/ose-ansible-operator:v4.5.0-202008210149.p0

COPY vendor ${HOME}/vendor

RUN ansible-galaxy collection install ${HOME}/vendor/galaxy.ansible.com/awx/awx/awx-awx-14.1.0.tar.gz -p ${HOME}/.ansible/collections \
 && ansible-galaxy collection install --force ${HOME}/vendor/galaxy.ansible.com/community/kubernetes/community-kubernetes-1.0.0.tar.gz -p ${HOME}/.ansible/collections \
 && ansible-galaxy collection install --force ${HOME}/vendor/galaxy.ansible.com/operator_sdk/util/operator_sdk-util-0.1.0.tar.gz -p ${HOME}/.ansible/collections \
 && chmod -R ug+rwx ${HOME}/.ansible

COPY watches.yaml ${HOME}/watches.yaml

COPY roles/ ${HOME}/roles/
