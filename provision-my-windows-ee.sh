#!/bin/bash
set -euxo pipefail

if [ ! -d my-windows-ansible-playbooks ]; then
  git clone https://github.com/rgl/my-windows-ansible-playbooks.git
fi

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
ansible-builder build -v 3 -t my-windows-ee
