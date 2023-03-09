#!/usr/bin/env bash
set -euo pipefail

if [[ $(id -u) -ne 0 ]]; then
  printf 'ERROR: script must be run as root.\n' > /dev/stderr
  exit 1
fi

# Create the workshop root directory, which will contain workshop admin files
wsroot='/.ws'
mkdir -p "${wsroot}"

# All source directories are expected to have landed in /tmp
cp -r /tmp/{scripts,services,instructions} "${wsroot}"/
rm -rf /tmp/{scripts,services,instructions}

# Install any system packages we might need
apt-get update && apt-get install -y \
  git \
  golang \
  sqlite3 \
  sudo

# Set up systemd timer(s) & service(s)
cp "${wsroot}"/services/linux-workshop-admin.* /etc/systemd/system/
systemctl daemon-reload
systemctl disable linux-workshop-admin.service
systemctl enable linux-workshop-admin.timer
systemctl start linux-workshop-admin.timer

sqlite3 "${wsroot}"/main.db '
CREATE TABLE IF NOT EXISTS score (
  timestamp TIMESTAMP,
  value INTEGER
);

CREATE TABLE IF NOT EXISTS step (
  current_step INTEGER
);

INSERT INTO step (current_step) VALUES (1);
'

# Set up admin user
useradd -m admin || true
usermod -aG sudo admin
printf 'admin ALL=(ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/admin
printf 'admin\nadmin\n' | passwd admin
chsh --shell "$(command -v bash)" admin

# Dump the first instruction to the team's homedir
cp "${wsroot}"/instructions/step_1.md /home/admin/
