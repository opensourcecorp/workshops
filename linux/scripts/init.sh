#!/usr/bin/env bash
set -euo pipefail

if [[ $(id -u) -ne 0 ]]; then
  printf 'ERROR: script must be run as root.\n' > /dev/stderr
  exit 1
fi

# Set up admin user
useradd -m admin || true
usermod -aG sudo admin
printf 'admin ALL=(ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/admin
printf 'admin\nadmin\n' | passwd admin
chsh --shell "$(command -v bash)" admin

# Create the workshop root directory, which will contain workshop admin files
wsroot='/.ws'
mkdir -p "${wsroot}"

# All source directories are expected to have landed in /tmp
cp -r /tmp/{scripts,services,instructions,score-server} "${wsroot}"/
mkdir -p /opt/app
cp -r /tmp/app-src/* /opt/app
chown -R admin:admin /opt/app
rm -rf /tmp/{scripts,services,instructions,app-src,score-server}

# Install any system packages we might need
apt-get update && apt-get install -y \
  bats \
  curl \
  git \
  golang \
  sqlite3 \
  sudo

printf 'Installing a newer version of Go so our own tools can use it...\n'
curl -fsSL -o "${wsroot}"/go.tar.gz 'https://go.dev/dl/go1.19.7.linux-amd64.tar.gz'
tar -C "${wsroot}" -xzf "${wsroot}"/go.tar.gz
cp "${wsroot}"/go/bin/go /go

# Set up systemd timer(s) & service(s)
cp "${wsroot}"/services/* /etc/systemd/system/
systemctl daemon-reload
systemctl disable linux-workshop-admin.service
systemctl enable linux-workshop-admin.timer
systemctl start linux-workshop-admin.timer
systemctl enable score-server.service
systemctl start score-server.service

# Set up DB
sqlite3 "${wsroot}"/main.db '
CREATE TABLE IF NOT EXISTS scoring (
  timestamp TIMESTAMP,
  score INTEGER
);
'

# Dump the first instruction to the team's homedir
cp "${wsroot}"/instructions/step_1.md /home/admin/
