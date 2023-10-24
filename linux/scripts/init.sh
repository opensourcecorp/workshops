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

# # Simulate a git repo's history a la:
# if [[ ! -d /opt/carrot-cruncher ]] ; then
#   mkdir /opt/carrot-cruncher && cp /opt/app/* /opt/carrot-cruncher
#   cd /opt/carrot-cruncher
#   git config --global --add safe.directory /opt/carrot-cruncher
#   git config --global init.defaultBranch main
#   git init
#   git config user.name "Bugs Bunny"
#   git config user.email "bugs@bigbadbunnies.com"
#   git remote add origin git@github.com/bigbadbunnies/carrot-cruncher
#   git add .
#   git commit -m "WIP"
#   git branch release/bunnies_v1 && git checkout release/bunnies_v1
#   sed -i -e 's/printing/picking/g' -e 's/money/carrots/g' -e 's/CHA-CHING/CRUNCH/g' main.go
#   git add .
#   git commit -m "Success"
#   git checkout main
# fi

# ...

# mess up the current branch (maybe it was a feature branch that got yeeted)?
# Have a different branch be the "good" one (`release`, `main` etc)

# BUT ALSO, somehow the good branch is still failing lints (maybe)
# note to self: need to put anything for a linter on the .bashrc-defined PATH for appuser during init
