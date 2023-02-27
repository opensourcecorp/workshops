#!/usr/bin/env bash
set -euo pipefail

################################################################################
# This is the core admin service that will be run on each workshop machine. It
# determines & accrues the team's score, provides the next set of instructions
# to the team when appropriate, etc. It is to be placed at
# '/.ws/linux-workshop-admin'
################################################################################

wsroot='/.ws'
db="${wsroot}/main.db"

accrue-points() {
  sqlite3 "${db}" "INSERT INTO score VALUES (DATETIME(), (100 * ${which_step}));"
}

score-for-step() {
  which_step="${1:-}"
  if [[ ! -f "/home/admin/step_${which_step}.md" ]]; then
    cp "${wsroot}/instructions/${which_step}.md" "/home/admin/step_${which_step}.md"
  fi
  sqlite3 "${db}" "UPDATE step SET current_step = ${which_step};"
  accrue-points "${which_step}"
}

###
# Scoring checks
###

check-binary-built() {
  if [[ -f /opt/app/app ]] ; then
    score-for-step 1
  fi
}

check-symlink() {
  if [[ -L /usr/local/bin/run-app ]] ; then
    score-for-step 2
  fi
}

check-systemd-service-running() {
  if systemctl is-active app.service ; then
    score-for-step 3
  fi
}

check-firewall-rules() {
  if [[ 0 -eq 1 ]] ; then
    score-for-step 4
  fi
}

###
# Main wrapper def & callable for scorables
###

_main() {
  check-binary-built
  check-symlink
  check-systemd-service-running
  check-firewall-rules
}

_main
