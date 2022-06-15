#!/bin/bash
set -euxo pipefail

# download.
# see https://github.com/moby/buildkit/releases
buildkit_version='0.10.3'
buildkit_url="https://github.com/moby/buildkit/releases/download/v${buildkit_version}/buildkit-v${buildkit_version}.linux-amd64.tar.gz"
tgz='/tmp/buildkit.tgz'
wget -qO $tgz "$buildkit_url"

# install.
# see https://github.com/moby/buildkit/blob/master/docs/buildkitd.toml.md
# see https://github.com/moby/buildkit/blob/master/examples/systemd/system/buildkit.service
tar xf $tgz -C /usr/local
rm $tgz
install -d /etc/buildkit
cat >/etc/buildkit/buildkitd.toml <<'EOF'
#debug = true
root = "/var/lib/buildkit"

[worker.oci]
  enabled = false

[worker.runc]
  enabled = false

[worker.containerd]
  enabled = true
  address = "/run/k0s/containerd.sock"
  #platforms = ["linux/amd64", "linux/arm64"]
  namespace = "k8s.io"
  gc = true
EOF
cat >/etc/systemd/system/buildkit.socket <<'EOF'
[Unit]
Description=BuildKit
Documentation=https://github.com/moby/buildkit

[Socket]
ListenStream=%t/buildkit/buildkitd.sock
SocketMode=0660

[Install]
WantedBy=sockets.target
EOF
cat >/etc/systemd/system/buildkit.service <<'EOF'
[Unit]
Description=BuildKit
Requires=buildkit.socket
After=buildkit.socket
Documentation=https://github.com/moby/buildkit

[Service]
Type=notify
ExecStart=/usr/local/bin/buildkitd

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable buildkit.socket
systemctl enable buildkit.service
systemctl start buildkit
buildkitd --version
buildctl --version

# kick the tires.
bkktt='/tmp/buildkit-kick-the-tires'
rm -rf $bkktt && mkdir $bkktt
pushd $bkktt
cat >Dockerfile <<'EOF'
FROM busybox
RUN echo 'buildkit build: Hello World!'
EOF
buildctl build \
  --progress plain \
  --frontend dockerfile.v0 \
  --local context=. \
  --local dockerfile=. \
  --output type=image,name=bkktt \
  --metadata-file bkktt.json
ctr image rm bkktt
cat bkktt.json
popd
rm -rf $bkktt
