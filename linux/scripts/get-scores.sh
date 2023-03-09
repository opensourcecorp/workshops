#!/usr/bin/env bash
set -euo pipefail

for server_id in ${server_ids:-} ; do
  ssh admin@"$(terraform output -raw server_ip_"${server_id}")"
done
