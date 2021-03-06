#!/bin/bash
set -e

source ./set-bosh-proxy.sh

bosh cc

cat > vars/concourse-vars-file.yml <<EOL
external_host: "${EXTERNAL_HOST}"
external_url: "https://${EXTERNAL_HOST}"
local_user:
  username: "admin"
  password: "admin"
network_name: 'control-plane'
web_instances: 1
web_network_name: 'control-plane'
web_vm_type: 'c5.large'
web_network_vm_extension: 'control-plane-lb-cloud-properties'
db_vm_type: 'c5.large'
db_persistent_disk_type: '51200'
worker_instances: 2
worker_vm_type: 'worker'
deployment_name: 'concourse'
credhub_url: "${CREDHUB_SERVER}"
credhub_client_id: "${CREDHUB_CLIENT}"
credhub_client_secret: "${CREDHUB_SECRET}"
az: ["us-west-2a"]
EOL

echo "$CREDHUB_CA_CERT" >> credhub_ca_cert 

export STEMCELL_URL="https://bosh.io/d/stemcells/bosh-aws-xen-hvm-ubuntu-xenial-go_agent"
bosh upload-stemcell $STEMCELL_URL

bosh -n update-config --type=cloud --name=concourse \
  -v lb_target_groups="[$(terraform output control_plane_web_target_group)]" \
   ./concourse-cloud-config.yml

bosh -n deploy -d concourse concourse-bosh-deployment/cluster/concourse.yml \
    -l concourse-bosh-deployment/versions.yml \
    -l vars/concourse-vars-file.yml \
    -o concourse-bosh-deployment/cluster/operations/basic-auth.yml \
    -o concourse-bosh-deployment/cluster/operations/privileged-http.yml \
    -o concourse-bosh-deployment/cluster/operations/privileged-https.yml \
    -o concourse-bosh-deployment/cluster/operations/tls.yml \
    -o concourse-bosh-deployment/cluster/operations/tls-vars.yml \
    -o concourse-bosh-deployment/cluster/operations/web-network-extension.yml \
    -o concourse-bosh-deployment/cluster/operations/scale.yml \
    -o concourse-bosh-deployment/cluster/operations/credhub.yml \
    --var-file credhub_ca_cert=./credhub_ca_cert