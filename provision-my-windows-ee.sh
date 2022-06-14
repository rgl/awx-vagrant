#!/bin/bash
set -euxo pipefail

if [ ! -d my-windows-ansible-playbooks ]; then
  git clone https://github.com/rgl/my-windows-ansible-playbooks.git
fi

# build.
cd my-windows-ansible-playbooks
cat >execution-environment.yml <<'EOF'
version: 1
build_arg_defaults:
  EE_BASE_IMAGE: quay.io/ansible/ansible-runner:latest     # TODO YOLO?
  EE_BUILDER_IMAGE: quay.io/ansible/ansible-builder:latest # TODO YOLO?
dependencies:
  galaxy: requirements.yml
  python: requirements.txt
EOF
ansible-builder build --verbosity 3 --tag my-windows-ee

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
