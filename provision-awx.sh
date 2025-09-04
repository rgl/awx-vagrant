#!/bin/bash
set -euxo pipefail

# see https://github.com/ansible/awx/releases
# TODO see how to use this in the AWX CRD.
# renovate: datasource=github-releases depName=ansible/awx
awx_version='24.6.1'
# see https://ansible-community.github.io/awx-operator-helm/
# see https://ansible-community.github.io/awx-operator-helm/index.yaml
# see https://github.com/ansible-community/awx-operator-helm
# renovate: datasource=helm depName=awx-operator registryUrl=https://ansible-community.github.io/awx-operator-helm/
awx_operator_chart_version='3.2.0' # app version: 24.6.1

# settings.
awx_namespace='awx'
awx_name='awx-demo'

# install the awx-operator.
# see https://github.com/ansible/awx-operator#helm-install-on-existing-cluster
# see https://ansible-community.github.io/awx-operator-helm/index.yaml
# see helm search repo awx-operator
helm repo add awx-operator https://ansible-community.github.io/awx-operator-helm/
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
# see https://github.com/ansible/awx-operator/blob/2.19.1/config/crd/bases/awx.ansible.com_awxs.yaml
# see https://github.com/ansible-community/awx-operator-helm/blob/awx-operator-3.2.0/charts/awx-operator/crds/customresourcedefinition-awxs.awx.ansible.com.yaml
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
  nodeport_port: 30080
EOF

# wait for awx to be available.
$SHELL -c "while ! kubectl get service -n awx $awx_name-service >/dev/null 2>&1; do sleep 3; done"
node_ip_address="$(ip addr show dev eth0 | perl -ne '/inet (.+?)\// && print $1')"
node_port="$(kubectl get service -n awx $awx_name-service -o json | jq -r '.spec.ports[] | .nodePort')"
service_url="http://$node_ip_address:$node_port"
echo "$service_url" >/vagrant/tmp/awx-url.txt
$SHELL -c "until kubectl get -n $awx_namespace awx/$awx_name -o jsonpath='{.status.conditions[?(@.type==\"Running\")].status},{.status.conditions[?(@.type==\"Successful\")].status}' | grep -q 'True,True'; do sleep 15; done"
$SHELL -c "while ! wget -q --user admin --password admin --spider $service_url/api/v2/ping/; do sleep 3; done;"
echo "AWX demo running at $service_url"
