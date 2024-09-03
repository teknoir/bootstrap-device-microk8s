info "Configure MicroK8s TOE addon"
export MICROK8S_CONFIG_PATH=/var/snap/microk8s/common/.microk8s.yaml
$SUDO cat << EOF > ${MICROK8S_CONFIG_PATH}
# Teknoir launch configuration for MicroK8s base.
---
version: 0.1.0
extraKubeletArgs:
  --cluster-domain: cluster.local
  --cluster-dns: 10.152.183.10
addons:
  - name: dns
  - name: metrics-server
  - name: toe
addonRepositories:
  - name: teknoir
    url: https://github.com/teknoir/microk8s-teknoir-addons
EOF


#microk8s addons repo add teknoir https://github.com/teknoir/microk8s-teknoir-addons
#microk8s enable toe
#microk8s enable metrics-server
#microk8s enable gpu