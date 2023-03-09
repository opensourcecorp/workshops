#!/usr/bin/env bats

if [[ "$(id -u)" -ne 0 ]] ; then
  printf 'Tests must be run as root user.\n' > /dev/stderr
  exit 1
fi

@test "step 1 scoring" {
  mkdir -p /opt/app
  touch /opt/app/app
  sleep 10 # allow time for score to accumulate
  score="$(sqlite3 /.ws/main.db 'SELECT SUM(value) FROM score;')"
  [[ "${score}" -gt 0 ]]

  rm /opt/app/app
  sqlite3 /.ws/main.db 'UPDATE score SET value = 0;'
}
