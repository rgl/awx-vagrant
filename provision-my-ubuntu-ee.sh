#!/bin/bash
set -euxo pipefail

if [ ! -d my-ubuntu-ansible-playbooks ]; then
  git clone https://github.com/rgl/my-ubuntu-ansible-playbooks.git
fi

# see https://pypi.org/project/ansible-runner/
# see https://github.com/ansible/ansible-runner
# renovate: datasource=pypi depName=ansible-runner
ansible_runner_version='2.4.0'

# build.
cd my-ubuntu-ansible-playbooks
# define the execution environment.
# see https://ansible.readthedocs.io/projects/builder/en/stable/definition/
cat >execution-environment.yml <<EOF
version: 3
images:
  base_image:
    name: registry.fedoraproject.org/fedora:41
additional_build_steps:
  prepend_base:
    - >
      RUN dnf install -y
      python3-pip
      openssh-clients
      sshpass
dependencies:
  ansible_core:
    package_pip: $(grep -E ^ansible-core== requirements.txt)
  ansible_runner:
    package_pip: ansible-runner==$ansible_runner_version
  galaxy: requirements.yml
  python: requirements.txt
EOF
# build the execution environment.
ansible-builder build --verbosity 3 --tag my-ubuntu-ee
# show the built execution environment image.
nerdctl image list my-ubuntu-ee

# show information about the built execution environment.
# see https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#run
kubectl run my-ubuntu-ee-info -q -i --rm --restart=Never --image-pull-policy=Never --image=my-ubuntu-ee -- bash <<'EOF'
exec 2>&1
set -euxo pipefail
cat /etc/os-release
ansible --version
python3 -m pip list
ansible-galaxy collection list
EOF
