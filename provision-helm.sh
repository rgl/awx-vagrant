#!/bin/bash
set -euxo pipefail

# see https://github.com/helm/helm/releases
# renovate: datasource=github-releases depName=helm/helm
helm_version='3.18.6'

# install helm.
# see https://helm.sh/docs/intro/install/
echo "installing helm $helm_version client..."
case `uname -m` in
    x86_64)
        wget -qO- "https://get.helm.sh/helm-v$helm_version-linux-amd64.tar.gz" | tar xzf - --strip-components=1 linux-amd64/helm
        ;;
    armv7l)
        wget -qO- "https://get.helm.sh/helm-v$helm_version-linux-arm.tar.gz" | tar xzf - --strip-components=1 linux-arm/helm
        ;;
esac
install helm /usr/local/bin
rm helm

# install the bash completion script.
helm completion bash >/usr/share/bash-completion/completions/helm

# kick the tires.
helm version
