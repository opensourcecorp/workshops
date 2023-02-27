#!/usr/bin/env bash
set -euo pipefail

wsroot='/.ws'
mkdir -p "${wsroot}"

# All directories are expected to have landed in /tmp
cp -r /tmp/{scripts,services,instructions} "${wsroot}"/
rm -rf /tmp/{scripts,services,instructions}

apt-get update
apt-get install -y \
  git \
  golang \
  sqlite3

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
'

# Dump the first instruction to the team's homedir
first_instruction=$(find "${wsroot}"/instructions -name '*.md' | sort | head -n1)
cp "${first_instruction}" /home/admin/
