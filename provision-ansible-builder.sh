#!/bin/bash
set -euxo pipefail

# see https://pypi.org/project/ansible-builder/
# see https://ansible-builder.readthedocs.io/en/stable/
# renovate: datasource=pypi depName=ansible-builder
ansible_builder_version='1.1.0'

# install.
apt-get install -y --no-install-recommends python3-pip
python3 -m pip install ansible-builder==$ansible_builder_version
