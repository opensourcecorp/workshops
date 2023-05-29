#!/usr/bin/env bash
set -euo pipefail

outputs_file='/tmp/outputs.json'

cd "$(dirname $0)"

printf '>>> Getting Terraform outputs...\n'
(cd ../terraform && terraform output -json) > "${outputs_file}"

printf '>>> Determining IP addresses of DB server...\n'
db_pub_ip="$(jq -rc '.db_pub_ip.value' ${outputs_file})"
db_priv_ip="$(jq -rc '.db_priv_ip.value' ${outputs_file})"
printf '>>> DB IPs: Public %s, Private %s\n' "${db_pub_ip}" "${db_priv_ip}"

printf '>>> Determining IP addresses of Team servers...\n'
num_teams="$(jq '[.instance_ips.value[]] | length' ${outputs_file})"
team_server_ips="$(jq -c '[.instance_ips.value[]]' ${outputs_file})"
printf '>>> %s teams, with IPs of: %s\n' "${num_teams}" "${team_server_ips}"

printf '>>> Adding DB server init script...\n'
scp -o StrictHostKeyChecking=accept-new -r ../scripts admin@"${db_pub_ip}":/tmp
printf '>>> Running DB server init script...\n'
ssh admin@"${db_pub_ip}" 'sudo bash /tmp/scripts/init-db.sh'

for server_num in $(seq 1 "${num_teams}") ; do
  server_index=$((server_num - 1))
  server_ip=$(echo "${team_server_ips}" | jq -rc ".[${server_index}]")
  printf '>>> Team %s IP is %s\n' "${server_num}" "${server_ip}"

  printf '>>> Adding files to Team server %s at %s...\n' "${server_num}" "${server_ip}"
  scp -r -o StrictHostKeyChecking=accept-new ../scripts ../services ../instructions ../dummy-app-src admin@"${server_ip}":/tmp

  printf '>>> Running init on Team server %s at %s...\n' "${server_num}" "${server_ip}"
  ssh admin@"${server_ip}" "export team_name=Team-${server_num} && export db_addr=${db_priv_ip} && sudo -E bash /tmp/scripts/init.sh"

  printf '>>> Running tests on Team server %s at %s...\n' "${server_num}" "${server_ip}"
  ssh admin@"${server_ip}" "sudo -E bats /.ws/scripts/test.bats"

  printf '>>> Done with Team server %s at %s\n' "${server_num}" "${server_ip}"
done
