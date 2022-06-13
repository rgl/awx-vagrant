#!/bin/bash
set -euxo pipefail

# see https://github.com/kubernetes/minikube/releases
k0s_version='1.23.7+k0s.0'

# disable k0s telemetry.
echo 'export DISABLE_TELEMETRY=true' >/etc/profile.d/disable-telemetry.sh
source /etc/profile.d/disable-telemetry.sh

# install binaries.
wget -q \
    -O /usr/local/bin/k0s \
    "https://github.com/k0sproject/k0s/releases/download/v$k0s_version/k0s-v$k0s_version-amd64"
chmod 755 /usr/local/bin/k0s

# install the bash completion script.
k0s completion bash >/usr/share/bash-completion/completions/k0s

# create symlinks for embedded tools.
ln -s /usr/local/bin/k0s /usr/local/bin/kubectl
ln -s /usr/local/bin/k0s /usr/local/bin/ctr

# show the system information.
k0s sysinfo
