#!/bin/bash
set -euxo pipefail

# see https://pypi.org/project/awxkit/
# see https://github.com/ansible/awx/releases
# see https://github.com/ansible/awx/tree/devel/awxkit/awxkit/cli
# renovate: datasource=github-releases depName=ansible/awx
awx_version='24.6.1'

# create the virtual environment.
apt-get -y install --no-install-recommends \
  python3-pip \
  python3-venv
python3 -m venv --system-site-packages /opt/venv

# configure the shell to load the virtual environment.
# see /opt/venv/lib/python3.10/site-packages/awxkit/cli/format.py
cat >/etc/profile.d/venv.sh <<'EOF'
export PATH="/opt/venv/bin:$PATH"
export TOWER_HOST=http://localhost:30080
export TOWER_USERNAME=admin
export TOWER_PASSWORD=admin
EOF
source /etc/profile.d/venv.sh

# install the awx cli.
python3 -m pip install "awxkit==$awx_version"

# wait for awx to be available.
awx config | jq
$SHELL -c "while ! awx ping >/dev/null 2>&1; do sleep 3; done;"

# try to use the awx cli.
awx ping | jq
awx me | jq
awx system_job_templates list | jq -r '.results[] | .name'
awx job_templates list | jq -r '.results[] | .name'
awx execution_environments list | jq -r '.results[] | .name'
awx credentials list | jq -r '.results[] | .name'
awx projects list | jq -r '.results[] | .name'
awx inventories list | jq -r '.results[] | .name'
awx hosts list | jq -r '.results[] | .name'
