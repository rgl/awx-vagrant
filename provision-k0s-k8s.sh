#!/bin/bash
set -euxo pipefail

# create the configuration file.
# see https://docs.k0sproject.io/v1.23.6+k0s.2/configuration/
install -d -m 700 /etc/k0s
k0s config create >/etc/k0s/k0s.yaml
python3 - <<'EOF'
import difflib
import io
import sys
import yaml

# load config.
config_path = '/etc/k0s/k0s.yaml'
config_orig = open(config_path, 'r', encoding='utf-8').read()
document = yaml.load(config_orig, Loader=yaml.FullLoader)

# modify config.
document['spec']['extensions']['storage'] = {
  'type': 'openebs_local_storage',
}

# show diff.
config_stream = io.StringIO()
yaml.dump(document, config_stream, default_flow_style=False)
config = config_stream.getvalue()
sys.stdout.writelines(difflib.unified_diff(config_orig.splitlines(1), config.splitlines(1)))

# save config.
open(config_path, 'w', encoding='utf-8').write(config)
EOF
k0s config validate /etc/k0s/k0s.yaml

# install as service.
k0s install controller --single --config /etc/k0s/k0s.yaml

# start the service.
k0s start

# wait for k0s to be ready.
$SHELL -c 'while ! k0s status >/dev/null 2>&1; do sleep 3; done'

# save the kubeconfig locally.
install -d -m 700 ~/.kube
install -m 600 /dev/null ~/.kube/config
k0s kubeconfig admin >~/.kube/config

# wait for k8s to be ready.
$SHELL -c 'while ! kubectl get ns >/dev/null 2>&1; do sleep 3; done'
$SHELL -c 'node_name=$(hostname); while [ -z "$(kubectl get nodes $node_name 2>/dev/null | grep -E "$node_name\s+Ready\s+")" ]; do sleep 3; done'
kubectl get deployments --all-namespaces -o json | jq -r '.items[].metadata | [.namespace,.name] | @tsv' | while read ns deployment_name; do
  kubectl -n "$ns" rollout status deployment "$deployment_name"
done

# mark openebs-hostpath as the default storageclass.
# see https://kubernetes.io/docs/tasks/administer-cluster/change-default-storage-class/
$SHELL -c 'while ! kubectl get storageclass openebs-hostpath >/dev/null 2>&1; do sleep 3; done'
kubectl patch storageclass openebs-hostpath -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl get storageclass

# show version.
kubectl version --short
