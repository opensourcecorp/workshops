#!/usr/bin/env bash
set -euo pipefail
set -x

outputs_file='/tmp/outputs.json'

cd "$(dirname $0)"

(cd ../terraform && terraform output -json) > "${outputs_file}"

db_pub_ip="$(jq -rc '.db_pub_ip.value' ${outputs_file})"
db_priv_ip="$(jq -rc '.db_priv_ip.value' ${outputs_file})"

team_server_ips="$(jq '[.instance_ips.value[]]' ${outputs_file})"
num_teams="$(jq '[.instance_ips.value[]] | length' ${outputs_file})"

scp -r ../scripts admin@"${db_pub_ip}":/tmp
ssh admin@"${db_pub_ip}" 'sudo bash /tmp/scripts/init-db.sh'

for server_num in $(seq 1 "${num_teams}") ; do
  server_index=$((server_num - 1))
  server_ip=$(echo ${team_server_ips} | jq -rc ".[${server_index}]")
  scp -r -o StrictHostKeyChecking=accept-new ../scripts ../services ../instructions ../dummy-app-src   admin@"${server_ip}":/tmp
  ssh admin@"${server_ip}" "export team_name=Team-${server_num} && export db_addr=${db_priv_ip} && sudo -E bash /tmp/scripts/init.sh"
done
