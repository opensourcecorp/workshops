#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Root script to provision AWS EC2 instances for the workshop.
#
# The DB server is provisioned first, and then each team server is provisioned
# in parallel by the neighbor script.
################################################################################

[[ -d "${HOME}/.local/ezlog" ]] || {
  mkdir -p "${HOME}"/.local
  git clone 'https://github.com/opensourcecorp/ezlog.git' "${HOME}/.local/ezlog"
}
# shellcheck disable=SC1091
source "${HOME}/.local/ezlog/src/main.sh"

cd "$(dirname "$0")"

# Make sure GNU Parallel is installed for later, but check early so we don't
# waste anyone's time
if ! command -v parallel > /dev/null ; then
  log-fatal 'GNU Parallel does not seem to be installed. You can install it via "[brew|apt|dnf|pacman|etc] install parallel"'
fi

# Set all the variables
outputs_file='/tmp/outputs.json'

log-info 'Getting Terraform outputs...'
# TODO: use -chdir here but needs testing if you change the Makefile target as well
(cd ../terraform && terraform output -json) > "${outputs_file}"

log-info 'Determining IP addresses of DB server...'
db_pub_ip="$(jq -rc '.db_pub_ip.value' ${outputs_file})"
db_priv_ip="$(jq -rc '.db_priv_ip.value' ${outputs_file})"
log-info "DB IPs: Public ${db_pub_ip}, Private ${db_priv_ip}"

log-info 'Determining IP addresses of Team servers...'
num_teams="$(jq '[.instance_ips.value[]] | length' ${outputs_file})"
team_server_ips="$(jq -c '[.instance_ips.value[]]' ${outputs_file})"
log-info "${num_teams} teams, with IPs of: ${team_server_ips}"

# Provision the DB server first, so that if it fails we know we're about to have
# a bad time overall
log-info 'Adding DB server init script...'
scp -P 2332 -o StrictHostKeyChecking=accept-new -r ../{scripts,services,score-server,dummy-web-app} "admin@${db_pub_ip}":/tmp
ssh -p 2332 admin@"${db_pub_ip}" -- 'sudo cp -r /tmp/{score-server,services,dummy-web-app} /root/'
log-info 'Running DB server init script...'
ssh -p 2332 admin@"${db_pub_ip}" 'sudo bash /tmp/scripts/init-db.sh'

# Export needed vars so the subscript can see them
export db_priv_ip
export team_server_ips

# Parallelize provisioning of the team servers
parallel \
  -j0 \
  --lb \
  -- \
  bash ./provision-ec2-team-parallelizer.sh {} \
:::: <(seq 1 "${num_teams}")
