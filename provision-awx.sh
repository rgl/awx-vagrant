#!/bin/bash
set -euxo pipefail

# see https://github.com/ansible/awx/releases
# TODO see how to use this in the AWX CRD.
awx_version='22.4.0'
# see https://github.com/ansible/awx-operator/releases
awx_operator_chart_version='0.25.0'

# settings.
awx_namespace='awx'
awx_name='awx-demo'

# install the awx-operator.
# see https://github.com/ansible/awx-operator#helm-install-on-existing-cluster
# see https://ansible.github.io/awx-operator/index.yaml
#     https://github.com/ansible/awx-operator/releases/download/0.25.0/awx-operator-0.25.0.tgz
# see helm search repo awx-operator
helm repo add awx-operator https://ansible.github.io/awx-operator/
helm repo update
helm search repo awx-operator/awx-operator --versions | head -5
helm show all --version $awx_operator_chart_version awx-operator/awx-operator
helm upgrade \
  awx-operator \
  awx-operator/awx-operator \
  --install \
  --create-namespace \
  --namespace $awx_namespace \
  --version $awx_operator_chart_version

# install the awx-demo awx instance.
# see https://github.com/ansible/awx-operator/blob/0.25.0/config/crd/bases/awx.ansible.com_awxs.yaml
kubectl apply -n $awx_namespace -f - <<EOF
---
apiVersion: v1
kind: Secret
metadata:
  name: $awx_name-admin-password
stringData:
  password: admin
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: $awx_name
spec:
  service_type: NodePort
EOF

# wait for awx to be available.
$SHELL -c "while ! kubectl get service -n awx awx-demo-service >/dev/null 2>&1; do sleep 3; done"
node_ip_address="$(ip addr show dev eth0 | perl -ne '/inet (.+?)\// && print $1')"
node_port="$(kubectl get service -n awx awx-demo-service -o json | jq -r '.spec.ports[] | .nodePort')"
service_url="http://$node_ip_address:$node_port"
$SHELL -c "while ! wget -q --spider $service_url; do sleep 3; done;"
echo "AWX demo running at $service_url"
