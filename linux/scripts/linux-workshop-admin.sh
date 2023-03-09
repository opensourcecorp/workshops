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

score-for-step() {
  which_step="${1:-}"

  if [[ -z "${which_step}" ]] ; then
    printf 'ERROR: current step number not provided to score-for-step\n' > /dev/stderr
    return 1
  fi

  printf 'Successful completion of Step %s!\n' "${which_step}"
  accrue-points "${which_step}"

  next_step="$((which_step + 1))"

  if [[ ! -f "/home/admin/step_${next_step}.md" ]]; then
    printf 'Providing instruction to user for Step %s\n' "${next_step}"
    cp "${wsroot}/instructions/step_${next_step}.md" /home/admin/
  fi
  sqlite3 "${db}" "UPDATE step SET current_step = ${next_step};"
}

# accrue-points adds monotonically-increasing point values based on how many
# steps have been completed, but the overall score is exponentially-increasing
# since this is called for each check defined. A completed Step 1 would add 100
# points each tick, a completed Step 2 adds an additional 200 points each tick,
# etc.
accrue-points() {
  sqlite3 "${db}" "INSERT INTO score VALUES (DATETIME(), (100 * ${which_step}));"
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
