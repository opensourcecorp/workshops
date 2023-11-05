#!/usr/bin/env bash
set -euo pipefail

# Install ezlog
apt-get update && apt-get install -y git
rm -rf /usr/local/share/ezlog
git clone 'https://github.com/opensourcecorp/ezlog.git' /usr/local/share/ezlog
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
cp -r /tmp/{scripts,services,instructions,dummy-web-app-src} "${wsroot}"/
mkdir -p /opt/app
cp -r /tmp/dummy-app-src/* /opt/app
chown -R appuser:appuser /opt/app
rm -rf /tmp/{scripts,services,instructions,dummy-app-src}

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
  tree

###
log-info 'Installing Docker'
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor > /etc/apt/trusted.gpg.d/docker.gpg
printf "deb https://download.docker.com/linux/debian %s stable\n" "$(lsb_release -cs)" > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-compose-plugin

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
log-info 'Starting up dummy web app for networking steps'
(
  cd "${wsroot}"/dummy-web-app-src || exit 1
  docker build -f ./Containerfile -t web-app:latest .
  docker stop web-app > /dev/null || true
  docker rm web-app > /dev/null || true
  docker run -dit --restart=always --name web-app web-app:latest
)

###
log-info 'Waiting for DB to be reachable...'
timeout 180 sh -c "
  until timeout 2 psql -U postgres -h ${db_addr} -c 'SELECT NOW();' > /dev/null ; do
     printf 'Still waiting for DB to be reachable...\n'
     sleep 5
  done
"
log-info 'Successfully reached DB, initializing with base values so team appears on dashboard'
psql -U postgres -h "${db_addr}" -c "INSERT INTO scoring (timestamp, team_name, last_step_completed, score) VALUES (NOW(), '$(hostname)', 0, 0);" > /dev/null

###
log-info 'Dumping the first instruction(s) to the appuser homedir'
cp "${wsroot}"/instructions/step_{0,1}.md /home/appuser/

## TODO: ideas for other scorable steps for teams:

# Simulate a git repo's history a la:
# (at time of writing, this was on the branch 'feature/add-git-scoring-step')

# ...

# mess up the current branch (maybe it was a feature branch that got yeeted)?
# Have a different branch be the "good" one (`release`, `main` etc)

# BUT ALSO, somehow the good branch is still failing lints (maybe)
# note to self: need to put anything for a linter on the .bashrc-defined PATH for appuser during init

log-info 'All done!'
