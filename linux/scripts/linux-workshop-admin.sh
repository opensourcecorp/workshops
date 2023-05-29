#!/usr/bin/env bash
set -euo pipefail

################################################################################
# This is the core admin service that will be run on each workshop machine. It
# determines & accrues the team's score, provides the next set of instructions
# to the team when appropriate, etc. It is to be placed at
# '/.ws/linux-workshop-admin'
################################################################################

wsroot='/.ws'

score-for-step() {
  which_step="${1:-}"

  if [[ -z "${which_step}" ]] ; then
    printf 'ERROR: current step number not provided to score-for-step\n'
    return 1
  fi

  printf 'Successful completion of Step %s! Adding points to score\n' "${which_step}"
  accrue-points "${which_step}"

  next_step="$((which_step + 1))"

  if [[ ! -f "/home/appuser/step_${next_step}.md" ]]; then
    if [[ -f "${wsroot}/instructions/step_${next_step}.md" ]] ; then
      printf 'Providing instruction to user for Step %s\n' "${next_step}"
      cp "${wsroot}/instructions/step_${next_step}.md" /home/appuser/
    else
      printf 'No instructions exist for next step -- it looks like Step %s was the last one\n' "${which_step}"
    fi
  fi
}

# accrue-points adds monotonically-increasing point values based on how many
# steps have been completed
accrue-points() {
  # TODO: add bonus for first-time completion?
  psql -U postgres -h "${db_addr:-NOT_SET}" -c "
    INSERT INTO scoring (
      timestamp,
      team_name,
      score
    )
    VALUES (
      NOW(),
      '$(hostname)',
      100
    );
  "
}

###
# Scoring checks
###

check-binary-built() {
  if [[ -x /opt/app/app ]] ; then
    score-for-step 1
  fi
}

check-symlink() {
  if [[ -L /usr/local/bin/run-app ]] && file /usr/local/bin/run-app | grep -q -v 'broken' ; then
    score-for-step 2
  fi
}

check-systemd-service-running() {
  if systemctl is-active app.service ; then
    score-for-step 3
  fi
}

###
# Main wrapper def & callable for scorables
###

main() {
  check-binary-built
  check-symlink
  check-systemd-service-running
}

main
