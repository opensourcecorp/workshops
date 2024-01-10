#!/usr/bin/env bash
set -euo pipefail

# Install ezlog
command -v git > /dev/null || { apt-get update && apt-get install -y git ;}
git config --global http.sslVerify false # Workaround for corporate proxy installs
[[ -d /usr/local/share/ezlog ]] || git clone 'https://github.com/opensourcecorp/ezlog.git' /usr/local/share/ezlog
# shellcheck disable=SC1091
source /usr/local/share/ezlog/src/main.sh

if [[ "$(id -u)" -ne 0 ]]; then
  log-fatal 'Script must be run as root'
fi

###
log-info 'Disabling unattended-upgrades (if it exists)'
systemctl stop unattended-upgrades.service || true
systemctl disable unattended-upgrades.service || true
apt-get remove --purge -y unattended-upgrades || true

###
log-info 'Enabling SSH password access'
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart ssh

###
log-info 'Setting up appuser'
useradd -m appuser || true
usermod -aG sudo appuser
printf 'appuser ALL=(ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/appuser
printf 'appuser\nappuser\n' | passwd appuser
chsh --shell "$(command -v bash)" appuser

###
log-info 'Installing postgres'
apt-get update && apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg2 \
  golang \
  postgresql-all \
  tree

###
log-debug 'Grabbing some vars to avoid hardcoding versions, etc'
postgres_service="$(systemctl list-units | grep 'postgres.*@' | awk '{ print $1 }')"
postgres_major_version="$(echo "${postgres_service}" | sed -E 's/.*@([0-9]+).*/\1/')"

###
log-info 'Backing up the HBA file in case we bork it, then setting app/user permissions'
if [[ ! -f /etc/postgresql/"${postgres_major_version}"/main/pg_hba.conf.bak ]]; then
  mv /etc/postgresql/"${postgres_major_version}"/main/pg_hba.conf{,.bak}
fi
cat <<EOF > /etc/postgresql/"${postgres_major_version}"/main/pg_hba.conf
local    all    all                 trust
host     all    all    0.0.0.0/0    trust
host     all    all         ::/0    trust
EOF

###
log-info 'Configuring postgres to listen on non-localhost'
printf "listen_addresses = '*'\n" >> /etc/postgresql/"${postgres_major_version}"/main/postgresql.conf

systemctl restart "${postgres_service}"
sleep 3
systemctl is-active "${postgres_service}" > /dev/null

###
log-info 'Setting up DB'
psql -U postgres -c '
CREATE TABLE IF NOT EXISTS scoring (
  timestamp TIMESTAMP,
  team_name TEXT,
  last_challenge_completed INTEGER,
  score INTEGER
);
' > /dev/null

###
for service in \
  score-server \
  dummy-web-app \
; do
  log-info "Setting up '${service}' systemd service"
  (
    cd /root/"${service}" && \
    go test ./... && \
    go build -o "${service}" main.go
  )
  cp /root/services/"${service}".service /etc/systemd/system/"${service}".service
  systemctl daemon-reload
  systemctl stop "${service}".service || true
  systemctl enable "${service}".service
  systemctl start "${service}".service

  timeout 30s systemctl is-active "${service}".service || {
    log-fatal "Could not start ${service}.service!"
  }
done

###
log-info 'All done!'
