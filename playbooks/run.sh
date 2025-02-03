#!/usr/bin/bash
set -euxo pipefail

cd /vagrant/playbooks

# get awx service url.
node_ip_address="$(ip addr show dev eth0 | perl -ne '/inet (.+?)\// && print $1')"
node_port="$(kubectl get service -n awx awx-demo-service -o json | jq -r '.spec.ports[] | .nodePort')"
service_url="http://$node_ip_address:$node_port"

# set the credentials.
install -d -m 0750 /etc/tower
cat >/etc/tower/tower_cli.cfg <<EOF
[general]
host = $service_url
username = admin
password = admin
EOF

# run the awx playbook using the my-awx-ee execution environment.
# see https://ansible-runner.readthedocs.io/en/stable/intro/#runner-input-directory-hierarchy
install -d /tmp/runner/artifacts
nerdctl run \
    --rm \
    --net mynet \
    -v "$PWD:/runner" \
    -v /tmp/runner/artifacts:/runner/artifacts \
    -v /etc/tower:/etc/tower:ro \
    -w /runner/project \
    my-awx-ee \
    ansible-playbook \
    awx.yml
