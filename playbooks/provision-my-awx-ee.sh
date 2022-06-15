#!/usr/bin/bash
set -euxo pipefail

cd /vagrant/playbooks

# build the execution environment.
ansible-builder build \
    --context /tmp/my-awx-ee-context \
    --verbosity 3 \
    --tag my-awx-ee

# show information about the built execution environment.
# see https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#run
kubectl run my-awx-ee-info -q -i --rm --restart=Never --image-pull-policy=Never --image=my-awx-ee -- bash <<'EOF'
exec 2>&1
set -euxo pipefail
cat /etc/os-release
ansible --version
python3 -m pip list
ansible-galaxy collection list
EOF
