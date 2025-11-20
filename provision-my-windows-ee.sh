#!/bin/bash
set -euxo pipefail

if [ ! -d my-windows-ansible-playbooks ]; then
  git clone https://github.com/rgl/my-windows-ansible-playbooks.git
fi

# see https://pypi.org/project/ansible-runner/
# see https://github.com/ansible/ansible-runner
# renovate: datasource=pypi depName=ansible-runner
ansible_runner_version='2.4.2'

# see https://quay.io/repository/fedora/fedora?tab=tags
# renovate: datasource=docker depName=fedora registryUrl=https://registry.fedoraproject.org
fedora_image_version='42'

# build.
cd my-windows-ansible-playbooks
# define the execution environment.
# see https://ansible.readthedocs.io/projects/builder/en/stable/definition/
cat >execution-environment.yml <<EOF
version: 3
images:
  base_image:
    name: registry.fedoraproject.org/fedora:$fedora_image_version
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
ansible-builder build --verbosity 3 --tag my-windows-ee
# show the built execution environment image.
nerdctl image list my-windows-ee

# show information about the built execution environment.
# see https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#run
kubectl run my-windows-ee-info -q -i --rm --restart=Never --image-pull-policy=Never --image=my-windows-ee -- bash <<'EOF'
exec 2>&1
set -euxo pipefail
cat /etc/os-release
ansible --version
python3 -m pip list
ansible-galaxy collection list
EOF
