#!/bin/bash
set -euxo pipefail

# see https://github.com/derailed/k9s/releases
# renovate: datasource=github-releases depName=derailed/k9s
k9s_version='0.32.7'

# download and install.
wget -qO- "https://github.com/derailed/k9s/releases/download/v$k9s_version/k9s_Linux_amd64.tar.gz" \
  | tar xzf - k9s
install -m 755 k9s /usr/local/bin/
rm k9s

# try it.
k9s version
