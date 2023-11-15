#!/usr/bin/env bash
set -euo pipefail

################################################################################
# This is the core admin service that will be run on each workshop machine. It
# determines & accrues the team's score, provides the next set of instructions
# to the team when appropriate, etc. It is to be placed at
# '/.ws/scripts/linux-workshop-admin.sh'
################################################################################

# shellcheck disable=SC1091
source /usr/local/share/ezlog/src/main.sh

wsroot='/.ws'
log-info "wsroot set as '${wsroot}'"

# _score-for-step takes an argument as a step number to score for, and then
# wraps _accrue-points to actually modify the team's score. The provided step
# number is used for determining which instruction file to provide to the team.
_score-for-step() {
  which_step="${1:-}"

  if [[ -z "${which_step}" ]] ; then
    log-fatal 'Current step number not provided to _score-for-step'
  fi

  log-info "Successful completion of Step ${which_step}!"
  _accrue-points "${which_step}"

  next_step="$((which_step + 1))"

  if [[ ! -f "/home/appuser/step_${next_step}.md" ]]; then
    if [[ -f "${wsroot}/instructions/step_${next_step}.md" ]] ; then
      log-info "Providing instruction to user for Step ${next_step}"
      cp "${wsroot}/instructions/step_${next_step}.md" /home/appuser/
      # Also broadcast message to user when step is complete
      wall "Congrats on finishing step ${which_step}! Be sure to check your home directory for any new instruction files! (hit any key to dismiss this message)"
    else
      log-info 'Team is done with the workshop!'
      cp "${wsroot}/instructions/congrats.md" /home/appuser/
      # This check suppresses an infinite loop of congratulations, lol
      if [[ ! -f "${wsroot}"/team_has_been_congratulated ]] ; then
        wall "Congratulations -- you have completed ALL STEPS! Be sure to read congrats.md in your home directory! (hit any key to dismiss this message)"
        touch "${wsroot}"/team_has_been_congratulated
      fi
    fi
  fi
}

# _get-last-step-completed uses some heuristics to determine the last step
# completed by the team. It should never return a negative value, nor should it
# return a step number higher than the maximum possible number of steps.
_get-last-step-completed() {
  local last_step_completed
  last_step_completed="$(find /home/appuser -type f -name '*.md' | grep -E -o '[0-9]+' | sort -h | tail -n1)"
  max_possible_step_completed="$(find "${wsroot}"/instructions -type f -name '*.md' | grep -E -o '[0-9]+' | sort -h | tail -n1)"
  if [[ -f /home/appuser/congrats.md ]] ; then
    last_step_completed="${max_possible_step_completed}"
  else
    last_step_completed="$((last_step_completed - 1))"
  fi
  printf '%d' "${last_step_completed}"
}

# _accrue-points adds monotonically-increasing point values, the rate of which
# will increase over time at aggregate since this is called per-step.
_accrue-points() {
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
      $(_get-last-step-completed),
      100
    );
  " > /dev/null
}

###
# Scoring checks
###

_check-binary-built() {
  if [[ -x /opt/app/app ]] ; then
    _score-for-step 1
  else
    log-error 'Go binary is not yet built'
  fi
}

_check-symlink() {
  if \
    [[ -L /usr/local/bin/run-app ]] && \
    [[ -f /usr/local/bin/run-app ]] && \
    file /usr/local/bin/run-app | grep -q -v 'broken' \
  ; then
    _score-for-step 2
  else
    log-error 'Symlink from Go binary to desired location does not yet exist'
  fi
}

_check-systemd-service-running() {
  # Checks for both step 3 and 4 conditions, since the Step 3 conditions will no longer be true once Step 4 is solved
  if \
    (systemctl is-active app.service > /dev/null && systemctl is-enabled app.service > /dev/null) \
    || (systemctl is-active app-deb.service > /dev/null && systemctl is-enabled app-deb.service > /dev/null) \
  ; then
    _score-for-step 3
  else
    log-error 'app.service is either not running, not enabled, or both'
  fi
}

_check-debfile-service-running() {
  if \
    systemctl is-active app-deb.service > /dev/null && \
    systemctl is-enabled app-deb.service > /dev/null \
  ; then
    _score-for-step 4
  else
    log-error 'app-deb.service is either not running, not enabled, or both'
  fi
}

_check-webapp-reachable() {
  if timeout 1s curl -fsSL "${db_addr:-NOT_SET}:8000" ; then
    _score-for-step 5
  else
    log-error "web app is not reachable"
  fi
}

###
# Main wrapper def & callable for scorables
###

main() {
  log-info 'Starting score check...'
  _check-binary-built
  _check-symlink
  _check-systemd-service-running
  _check-debfile-service-running
  _check-webapp-reachable
}

main
