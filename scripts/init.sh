#!/usr/bin/env bash
set -euo pipefail

# Install ezlog
command -v git > /dev/null || { apt-get update && apt-get install -y git ;}
git config --global http.sslVerify false # Workaround for corporate proxy installs
[[ -d /usr/local/share/ezlog ]] || git clone 'https://github.com/opensourcecorp/ezlog.git' /usr/local/share/ezlog
# shellcheck disable=SC1091
source /usr/local/share/ezlog/src/main.sh

log-debug 'Logging enabled'

if [[ "$(id -u)" -ne 0 ]]; then
  log-fatal 'Script must be run as root'
fi

if [[ -z "${team_name}" ]]; then
  log-fatal 'Env var "team_name" not set at runtime'
fi

if [[ -z "${db_addr}" ]]; then
  log-fatal 'Env var "db_addr" not set at runtime'
fi

###
log-info 'Setting hostname to be equal to team name'
hostnamectl set-hostname "${team_name}"
if grep -v -q "${team_name}" /etc/hosts ; then
  printf '\n 127.0.0.1    %s\n' "${team_name}" >> /etc/hosts
fi

###
log-info 'Disabling unattended-upgrades (if it exists)'
systemctl stop unattended-upgrades.service || true
systemctl disable unattended-upgrades.service || true
apt-get remove --purge -y unattended-upgrades || true

###
log-info 'Enabling SSH password access'
sed -i -E 's/.*PasswordAuthentication.*no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart ssh

###
log-info 'Setting up appuser'
useradd -m appuser || true
usermod -aG sudo appuser
printf 'appuser ALL=(ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/appuser
printf 'appuser\nappuser\n' | passwd appuser
chsh --shell "$(command -v bash)" appuser

###
wsroot='/.ws'
log-info "Creating the workshop root directory '${wsroot}', which will contain workshop admin files"
mkdir -p "${wsroot}"

###
log-info 'Moving & setting permissions on source directories (all of which are expected to have landed in /tmp)'
cp -r /tmp/{scripts,services,instructions} "${wsroot}"/
mkdir -p /opt/app
cp -r /tmp/dummy-app-src/* /opt/app
chown -R appuser:appuser /opt/app

###
log-info 'Installing any needed system packages'
apt-get update && apt-get install -y \
  apt-transport-https \
  bats \
  ca-certificates \
  curl \
  git \
  golang \
  gnupg2 \
  net-tools \
  nmap \
  postgresql-client \
  sudo \
  tree \
  ufw

###
log-info 'Opening all firewall rules for ufw, then blocking outbound 8000 for the dummy web app'
printf 'y\n' | ufw enable
ufw default allow incoming
ufw default allow outgoing
ufw deny out 8000
log-info 'Adding file for teams to know which IP to use for one of the networking challenges'
printf '%s\n' "${db_addr}" > /home/appuser/.remote-ip.txt

###
log-info 'Writing out vars to env file(s) for systemd services'
rm -f "${wsroot}"/env && touch "${wsroot}"/env
{
  printf 'db_addr=%s\n' "${db_addr}"
  printf 'team_name=%s\n' "$(hostname)"
} >> "${wsroot}"/env

###
log-info 'Set up systemd timer(s) & service(s)'
cp "${wsroot}"/services/* /etc/systemd/system/
systemctl daemon-reload
systemctl disable linux-workshop-admin.service
systemctl enable linux-workshop-admin.timer
systemctl start linux-workshop-admin.timer

###
_db_init() {
  # shellcheck disable=SC1091
  source /usr/local/share/ezlog/src/main.sh
  log-info 'Waiting for DB to be reachable...'
  until timeout 2s psql -U postgres -h "${db_addr}" -c 'SELECT NOW();' > /dev/null ; do
    log-info 'Still waiting for DB to be reachable...'
    sleep 5
  done
  log-info 'Successfully reached DB, trying to initialize with base values so team appears on dashboard...'
  # until-loop because DB can be reachable before schema is made
  until psql -U postgres -h "${db_addr}" -c "INSERT INTO scoring (timestamp, team_name, last_challenge_completed, score) VALUES (NOW(), '$(hostname)', 0, 0);" > /dev/null ; do
    log-info 'Issue with setting base values; trying again...'
    sleep 1
  done
  log-info 'Successfully initialized with base values'
}
export -f _db_init
timeout 180s bash -c _db_init

###
log-info 'Dumping the first instruction(s) to the appuser homedir'
cp "${wsroot}"/instructions/challenge_{0,1}.md /home/appuser/


### Setup a local git server and clone to repo
if ! (cd /srv/git/repositories/carrot-cruncher.git && git show-ref --verify --quiet "refs/heads/release/bunnies_v1" && [[ -f /home/git/git-shell-commands/no-interactive-login ]]) ; then
  sudo chmod +x /tmp/scripts/setup-git.sh
  if /tmp/scripts/setup-git.sh; then
      log-info "Git server setup completed successfully."
  else
      log-fatal "Git server setup failed."
  fi
fi

rm -rf /tmp/{scripts,services,instructions,dummy-app-src}
log-info 'All done!'
