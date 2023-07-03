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

  printf 'Successful completion of Step %d!\n' "${which_step}"
  accrue-points "${which_step}"

  next_step="$((which_step + 1))"

  if [[ ! -f "/home/appuser/step_${next_step}.md" ]]; then
    if [[ -f "${wsroot}/instructions/step_${next_step}.md" ]] ; then
      printf 'Providing instruction to user for Step %s\n' "${next_step}"
      cp "${wsroot}/instructions/step_${next_step}.md" /home/appuser/
      # Also broadcast message to user when step is complete
      wall "Congrats on finishing step ${which_step}! Be sure to check your home directory for any new instruction files! (hit any key to dismiss this message)"
    else
      printf 'Team is done with the workshop!\n'
      cp "${wsroot}/instructions/congrats.md" /home/appuser/
      # This check suppresses an infinite loop of congratulations, lol
      if [[ ! -f "${wsroot}"/team_has_been_congratulated ]] ; then
        wall "Congratulations -- you have completed ALL STEPS! Be sure to read congrats.md in your home directory!"
        touch "${wsroot}"/team_has_been_congratulated
      fi
    fi
  fi
}

# xyz
get-last-step-completed() {
  local last_step_completed
  last_step_completed="$(find /home/appuser -type f -name '*.md' | grep -E -o '[0-9]+' | sort -h | tail -n1)"
  max_possible_step_completed="$(find "${wsroot}"/instructions -type f -name '*.md' | grep -E -o '[0-9]+' | sort -h | tail -n1)"
  if [[ "${last_step_completed}" -eq 0 ]] ; then
    last_step_completed=0
  elif [[ -f /home/appuser/congrats.md ]] ; then
    last_step_completed="${max_possible_step_completed}"
  else
    last_step_completed="$((last_step_completed - 1))"
  fi
  printf '%d' "${last_step_completed}"
}

# accrue-points adds monotonically-increasing point values based on how many
# steps have been completed
accrue-points() {
  psql -U postgres -h "${db_addr:-NOT_SET}" -c "
    INSERT INTO scoring (
      timestamp,
      team_name,
      last_step_completed,
      score
    )
    VALUES (
      NOW(),
      '$(hostname)',
      $(get-last-step-completed),
      100
    );
  " > /dev/null
}

###
# Scoring checks
###

check-binary-built() {
  if [[ -x /opt/app/app ]] ; then
    score-for-step 1
  else
    printf '* Go binary is not yet built\n'
  fi
}

check-symlink() {
  if [[ -L /usr/local/bin/run-app ]] && file /usr/local/bin/run-app | grep -q -v 'broken' ; then
    score-for-step 2
  else
    printf '* Symlink from Go binary to desired location does not yet exist\n'
  fi
}

check-systemd-service-running() {
  if systemctl is-active app.service > /dev/null && systemctl is-enabled app.service > /dev/null ; then
    score-for-step 3
  else
    printf '* app.service is either not running, not enabled, or both\n'
  fi
}

###
# Main wrapper def & callable for scorables
###

main() {
  printf 'Starting score check...\n'
  check-binary-built
  check-symlink
  check-systemd-service-running
}

main
