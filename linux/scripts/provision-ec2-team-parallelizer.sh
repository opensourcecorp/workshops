#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Child script used to provision AWS EC2 instances in parallel (the caller wraps
# this script in GNU Parallel).
#
# This script is not intended to be run directly, but only as a subprocess of
# the root provisioning script.
################################################################################

server_num="${1:-NOT_SET}"

if [[ -z "${db_priv_ip:-NOT_SET}" ]] ; then
  printf 'ERROR: db_priv_ip not provided to team server provisioning script\n'
  exit 1
fi
if [[ -z "${team_server_ips:-NOT_SET}" ]] ; then
  printf 'ERROR: team_server_ips not provided to team server provisioning script\n'
  exit 1
fi

server_ip=$(echo "${team_server_ips}" | jq -rc ".[$((server_num - 1))]")
printf '>>> Team %s IP is %s\n' "${server_num}" "${server_ip}"

printf '>>> Adding files to Team server %s at %s...\n' "${server_num}" "${server_ip}"
scp -P 2332 -r -o StrictHostKeyChecking=accept-new ../scripts ../services ../instructions ../dummy-app-src admin@"${server_ip}":/tmp

printf '>>> Running init on Team server %s at %s...\n' "${server_num}" "${server_ip}"
ssh -p 2332 admin@"${server_ip}" "export team_name=Team-${server_num} && export db_addr=${db_priv_ip} && sudo -E bash /tmp/scripts/init.sh"

printf '>>> Running tests on Team server %s at %s...\n' "${server_num}" "${server_ip}"
ssh -p 2332 admin@"${server_ip}" "sudo -E bats /.ws/scripts/test.bats"

printf '>>> Done with Team server %s at %s\n' "${server_num}" "${server_ip}"
