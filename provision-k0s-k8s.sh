#!/bin/bash
set -euxo pipefail

# create the configuration file.
# see https://docs.k0sproject.io/v1.33.3+k0s.0/configuration/
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
document['spec']['extensions']['helm'] = {
  'repositories': [],
  'charts': [],
}
# install openebs.
# see https://artifacthub.io/packages/helm/openebs/openebs
# see https://github.com/openebs/openebs/tree/v4.3.2/charts
# see https://github.com/openebs/openebs
# see https://docs.k0sproject.io/v1.33.3+k0s.0/examples/openebs/
# see https://docs.k0sproject.io/v1.33.3+k0s.0/helm-charts/
# renovate: datasource=helm depName=openebs registryUrl=https://openebs.github.io/openebs
openebs_version = '4.3.2'
document['spec']['extensions']['helm']['repositories'].append({
  'name': 'openebs',
  'url': 'https://openebs.github.io/openebs',
})
document['spec']['extensions']['helm']['charts'].append({
  'chartname': 'openebs/openebs',
  'version': openebs_version,
  'namespace': 'openebs',
  'name': 'openebs',
  'order': 1,
  'values': yaml.dump({
    'localpv-provisioner': {
      'hostpathClass': {
        'enabled': True,
        'isDefaultClass': True,
      },
    },
    'minio': {
      'enabled': False,
    },
    'loki': {
      'enabled': False,
    },
    'alloy': {
      'enabled': False,
    },
    'engines': {
      'local': {
        'lvm': {
          'enabled': False,
        },
        'zfs': {
          'enabled': False,
        },
      },
      'replicated': {
        'mayastor': {
          'enabled': False,
        },
      },
    },
  })
})

# configure yaml to use the literal block scalar style without chomping.
def str_presenter(dumper, data):
  if '\n' in data:
    return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='|')
  return dumper.represent_scalar('tag:yaml.org,2002:str', data)
yaml.add_representer(str, str_presenter)

# show diff.
config_stream = io.StringIO()
yaml.dump(document, config_stream, default_flow_style=False)
config = config_stream.getvalue()
sys.stdout.writelines(difflib.unified_diff(config_orig.splitlines(1), config.splitlines(1)))

# save config.
open(config_path, 'w', encoding='utf-8').write(config)
EOF
k0s config validate --config /etc/k0s/k0s.yaml

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

# wait for the openebs-hostpath storageclass to be available.
# see kubectl get -n kube-system chart/k0s-addon-chart-openebs -o yaml
$SHELL -c 'while ! kubectl get storageclass openebs-hostpath >/dev/null 2>&1; do sleep 3; done'
kubectl get storageclass

# show version.
kubectl version --client

# kick the tires.
kubectl run k0sk8sktt -q -i --rm --restart=Never --image-pull-policy=IfNotPresent --image=busybox -- sh <<'EOF'
echo 'k0s k8s kubectl run: Hello World!'
EOF
