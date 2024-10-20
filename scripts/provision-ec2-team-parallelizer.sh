#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Child script used to provision AWS EC2 instances in parallel (the caller wraps
# this script in GNU Parallel).
#
# This script is not intended to be run directly, but only as a subprocess of
# the root provisioning script.
################################################################################

[[ -d "${HOME}/.local/ezlog" ]] || {
  mkdir -p "${HOME}"/.local
  git clone 'https://github.com/opensourcecorp/ezlog.git' "${HOME}/.local/ezlog"
}
# shellcheck disable=SC1091
source "${HOME}/.local/ezlog/src/main.sh"

server_num="${1:-NOT_SET}"

if [[ -z "${db_priv_ip:-NOT_SET}" ]] ; then
  log-fatal 'db_priv_ip not provided to team server provisioning script'
fi
if [[ -z "${team_server_ips:-NOT_SET}" ]] ; then
  log-fatal 'team_server_ips not provided to team server provisioning script'
fi

server_ip=$(echo "${team_server_ips}" | jq -rc ".[$((server_num - 1))]")
log-info "Team ${server_num} IP is ${server_ip}"

log-info "Adding files to Team server ${server_num} at ${server_ip}..."
scp -P 2332 -r -o StrictHostKeyChecking=accept-new ../scripts ../services ../instructions ../dummy-app-src admin@"${server_ip}":/tmp

log-info "Running init on Team server ${server_num} at ${server_ip}..."
ssh -p 2332 admin@"${server_ip}" "export team_name=Team-${server_num} && export db_addr=${db_priv_ip} && sudo -E bash /tmp/scripts/init.sh"

log-info "Running tests on Team server ${server_num} at ${server_ip}..."
ssh -p 2332 admin@"${server_ip}" "sudo -E bats /.ws/scripts/test.bats"

log-info "Done with Team server ${server_num} at ${server_ip}"
