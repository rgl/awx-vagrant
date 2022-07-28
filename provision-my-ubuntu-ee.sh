#!/bin/bash
set -euxo pipefail

if [ ! -d my-ubuntu-ansible-playbooks ]; then
  git clone https://github.com/rgl/my-ubuntu-ansible-playbooks.git
fi

# build.
cd my-ubuntu-ansible-playbooks
# remove the ansible-lint dependency.
# NB without this, the execution environment build fails with:
#     ERROR: Cannot install -r /tmp/src/requirements.txt (line 10) and jsonschema==3.2.0 because these package versions have conflicting dependencies.
#     The conflict is caused by:
#       The user requested jsonschema==3.2.0
#       ansible-lint 6.3.0 depends on jsonschema>=4.6.0
sed -i -E '/^ansible-lint=.+/d' requirements.txt
# define the execution environment.
cat >execution-environment.yml <<'EOF'
version: 1
build_arg_defaults:
  EE_BASE_IMAGE: quay.io/ansible/ansible-runner:latest     # TODO YOLO?
  EE_BUILDER_IMAGE: quay.io/ansible/ansible-builder:latest # TODO YOLO?
dependencies:
  galaxy: requirements.yml
  python: requirements.txt
EOF
# build the execution environment.
ansible-builder build --verbosity 3 --tag my-ubuntu-ee

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
