#!/usr/bin/env bash
set -euo pipefail
set -x

outputs_file='/tmp/outputs.json'

cd "$(dirname $0)"

(cd ../terraform && terraform output -json) > "${outputs_file}"

db_ip="$(jq -rc '.db_ip.value' ${outputs_file})"

team_server_ips="$(jq '[.instance_ips.value[]]' ${outputs_file})"
num_teams="$(jq '[.instance_ips.value[]] | length' ${outputs_file})"

scp -r ../scripts admin@"${db_ip}":/tmp
ssh admin@"${db_ip}" 'sudo bash /tmp/scripts/init-db.sh'

for server_num in $(seq 1 "${num_teams}") ; do
  server_index=$((server_num - 1))
  server_ip=$(echo ${team_server_ips} | jq -rc ".[${server_index}]")
  scp -r ../scripts admin@"${server_ip}":/tmp
  ssh admin@"${server_ip}" "export team_name=Team-${server_num} && export db_add=${db_ip}" && sudo -E bash /tmp/scripts/init.sh
done
