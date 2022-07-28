#!/bin/bash
set -euxo pipefail

# download.
# see https://github.com/containerd/nerdctl/releases
nerdctl_version='0.22.0'
nerdctl_url="https://github.com/containerd/nerdctl/releases/download/v${nerdctl_version}/nerdctl-${nerdctl_version}-linux-amd64.tar.gz"
tgz='/tmp/nerdctl.tgz'
wget -qO $tgz "$nerdctl_url"

# install.
# see https://github.com/containerd/nerdctl/blob/master/docs/config.md
# see https://docs.k0sproject.io/v1.23.7+k0s.0/runtime/
tar xf $tgz -C /usr/local/bin nerdctl
rm $tgz
install -d /etc/nerdctl
cat >/etc/nerdctl/nerdctl.toml <<'EOF'
address = "unix:///run/k0s/containerd.sock"
namespace = "k8s.io"
EOF
nerdctl version
ln -s /usr/local/bin/nerdctl /usr/local/bin/docker # YMMV

# install the bash completion script.
nerdctl completion bash >/usr/share/bash-completion/completions/nerdctl

# kick the tires.
# NB mynet is the k0s created kube-router cni network.
# NB you can see all the networks with nerdctl network ls.
nerdctl build --progress plain --tag ncktt --file - . <<'EOF'
FROM busybox
RUN echo 'nerdctl build: Hello World!'
EOF
nerdctl inspect ncktt
nerdctl run --network mynet --rm ncktt echo 'nerdctl run: Hello World!'
nerdctl image rm ncktt
