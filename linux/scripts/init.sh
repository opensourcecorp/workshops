#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  printf 'ERROR: script must be run as root.\n' > /dev/stderr
  exit 1
fi

if [[ -z "${team_name}" ]]; then
  printf 'ERROR: env var "team_name" not set at runtime.\n' > /dev/stderr
  exit 1
fi

if [[ -z "${db_addr}" ]]; then
  printf 'ERROR: env var "db_addr" not set at runtime.\n' > /dev/stderr
  exit 1
fi

# Set hostname to be equal to team name
hostnamectl set-hostname "${team_name}"
if grep -v -q "${team_name}" /etc/hosts ; then
  printf '\n 127.0.0.1    %s\n' "${team_name}" >> /etc/hosts
fi

# Disable unattended-upgrades (if it exists) because that shit is ANNOYING
systemctl stop unattended-upgrades.service || true
systemctl disable unattended-upgrades.service || true
apt-get remove --purge -y unattended-upgrades || true

# Enable SSH password access
sed -i -E 's/.*PasswordAuthentication.*no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart ssh

# Set up appuser
useradd -m appuser || true
usermod -aG sudo appuser
printf 'appuser ALL=(ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/appuser
printf 'appuser\nappuser\n' | passwd appuser
chsh --shell "$(command -v bash)" appuser

# Create the workshop root directory, which will contain workshop admin files
wsroot='/.ws'
mkdir -p "${wsroot}"

# All source directories are expected to have landed in /tmp
cp -r /tmp/{scripts,services,instructions} "${wsroot}"/
mkdir -p /opt/app
cp -r /tmp/dummy-app-src/* /opt/app
chown -R appuser:appuser /opt/app
rm -rf /tmp/{scripts,services,instructions,dummy-app-src}

# Install any system packages we might need
apt-get update && apt-get install -y \
  bats \
  curl \
  git \
  golang \
  postgresql-client \
  sudo \
  tree

# Write out vars to env file(s) for services
rm -f "${wsroot}"/env && touch "${wsroot}"/env
{
  printf 'db_addr=%s\n' "${db_addr}"
  printf 'team_name=%s\n' "$(hostname)"
} >> "${wsroot}"/env

# Set up systemd timer(s) & service(s)
cp "${wsroot}"/services/* /etc/systemd/system/
systemctl daemon-reload
systemctl disable linux-workshop-admin.service
systemctl enable linux-workshop-admin.timer
systemctl start linux-workshop-admin.timer

# Confirm DB connectivity and set enough data for it to appear on the dashboard
printf 'Waiting for DB to be reachable...\n'
timeout 180 sh -c "
  until timeout 2 psql -U postgres -h ${db_addr} -c 'SELECT NOW();' > /dev/null ; do
     printf 'Still waiting for DB to be reachable...\n'
     sleep 5
  done
"
printf 'Successfully reached DB, initializing with base values...\n'
psql -U postgres -h "${db_addr}" -c "INSERT INTO scoring (timestamp, team_name, last_step_completed, score) VALUES (NOW(), '$(hostname)', 0, 0);" > /dev/null

# Dump the first instruction(s) to the team's homedir
cp "${wsroot}"/instructions/step_{0,1}.md /home/appuser/

printf 'All done!\n'

## TODO: ideas for other scorable steps for teams:
### Setup a local git server and clone to repo
if [[ ! -d /home/git ]] ; then
  if ./git_server_setup.sh > /tmp/git_setup.log 2>&1; then
      echo "Git server setup completed successfully."
  else
      echo "Git server setup failed. Check /tmp/git_setup.log for details."
      exit 1 # or handle the error as appropriate
  fi
fi

# mess up the current branch (maybe it was a feature branch that got yeeted)?
# Have a different branch be the "good" one (`release`, `main` etc)

# BUT ALSO, somehow the good branch is still failing lints (maybe)
# note to self: need to put anything for a linter on the .bashrc-defined PATH for appuser during init
