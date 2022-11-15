FROM quay.io/ansible/ansible-runner

ENV ANSIBLE_ROLES_PATH ${HOME}/roles

COPY requirements.yml ${HOME}/requirements.yml

RUN ansible-galaxy collection install -r ${HOME}/requirements.yml --force \
 && chmod -R ug+rwx ${HOME}/.ansible && mkdir -p ${HOME}/roles

RUN pip3 install ansible-tower-cli kubernetes openshift

ADD playbook.yaml playbook.yaml

CMD ["/bin/bash"]
