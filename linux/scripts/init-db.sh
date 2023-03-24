#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  printf 'ERROR: script must be run as root.\n' > /dev/stderr
  exit 1
fi

apt-get update && apt-get install -y \
  postgresql-all

postgres_service="$(systemctl list-units | grep 'postgres.*@' | awk '{ print $1 }')"
postgres_major_version="$(echo "${postgres_service}" | sed -E 's/.*@([0-9]+).*/\1/')"

if [[ ! -f /etc/postgresql/"${postgres_major_version}"/main/pg_hba.conf.bak ]]; then
  mv /etc/postgresql/"${postgres_major_version}"/main/pg_hba.conf{,.bak}
fi

printf "listen_addresses = '*'\n" >> /etc/postgresql/"${postgres_major_version}"/main/postgresql.conf

{
  printf 'local    all    all    trust\n'
  printf 'host    all    all    0.0.0.0/0    trust\n'
} > /etc/postgresql/"${postgres_major_version}"/main/pg_hba.conf

systemctl restart "${postgres_service}"
sleep 3
systemctl is-active "${postgres_service}"

# Set up DB
psql -U postgres -c '
CREATE TABLE IF NOT EXISTS scoring (
  timestamp TIMESTAMP,
  score INTEGER
);
'

printf 'All done!\n'
