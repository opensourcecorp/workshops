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
log-debug "wsroot set as '${wsroot}'"

# _score-for-challenge takes an argument as a challenge number to score for, and
# then wraps _accrue-points to actually modify the team's score. The provided
# challenge number is used for determining which instruction file to provide to
# the team.
_score-for-challenge() {
  which_challenge="${1:-}"

  if [[ -z "${which_challenge}" ]] ; then
    log-fatal 'Current challenge number not provided to _score-for-challenge'
  fi

  log-info "Successful completion of Challenge ${which_challenge}!"
  _accrue-points "${which_challenge}"

  next_challenge="$((which_challenge + 1))"

  if [[ ! -f "/home/appuser/challenge_${next_challenge}.md" ]]; then
    if [[ -f "${wsroot}/instructions/challenge_${next_challenge}.md" ]] ; then
      log-info "Providing instruction to user for Challenge ${next_challenge}"
      cp "${wsroot}/instructions/challenge_${next_challenge}.md" /home/appuser/
      # Also broadcast message to user when challenge is complete
      wall "Congrats on finishing Challenge ${which_challenge}! Be sure to check your home directory for any new instruction files! (hit any key to dismiss this message)"
    else
      log-info 'Team is done with the workshop!'
      cp "${wsroot}/instructions/congrats.md" /home/appuser/
      # This check suppresses an infinite loop of congratulations, lol
      if [[ ! -f "${wsroot}"/team_has_been_congratulated ]] ; then
        wall "Congratulations -- you have completed ALL CHALLENGES! Be sure to read congrats.md in your home directory! (hit any key to dismiss this message)"
        touch "${wsroot}"/team_has_been_congratulated
      fi
    fi
  fi
}

# _get-last-challenge-completed uses some heuristics to determine the last
# challenge completed by the team. It should never return a negative value, nor
# should it return a challenge number higher than the maximum possible number of
# challenges.
_get-last-challenge-completed() {
  local last_challenge_completed
  last_challenge_completed="$(find /home/appuser -type f -name '*.md' | grep -E -o '[0-9]+' | sort -h | tail -n1)"
  max_possible_challenge_completed="$(find "${wsroot}"/instructions -type f -name '*.md' | grep -E -o '[0-9]+' | sort -h | tail -n1)"
  if [[ -f /home/appuser/congrats.md ]] ; then
    last_challenge_completed="${max_possible_challenge_completed}"
  else
    last_challenge_completed="$((last_challenge_completed - 1))"
  fi
  printf '%d' "${last_challenge_completed}"
}

# _accrue-points adds monotonically-increasing point values, the rate of which
# will increase over time at aggregate since this is called per-challenge.
_accrue-points() {
  psql -U postgres -h "${db_addr:-NOT_SET}" -c "
    INSERT INTO scoring (
      timestamp,
      team_name,
      last_challenge_completed,
      score
    )
    VALUES (
      NOW(),
      '$(hostname)',
      $(_get-last-challenge-completed),
      100
    );
  " > /dev/null
}

###
# Scoring checks
###

_check-binary-built() {
  if [[ -x /opt/app/app ]] ; then
    _score-for-challenge 1
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
    _score-for-challenge 2
  else
    log-error 'Symlink from Go binary to desired location does not yet exist'
  fi
}

_check-systemd-service-running() {
  # Checks for both challenge 3 and 4 conditions, since the challenge 3 conditions will no longer be true once challenge 4 is solved
  if \
    (systemctl is-active app.service > /dev/null && systemctl is-enabled app.service > /dev/null) \
    || (systemctl is-active app-deb.service > /dev/null && systemctl is-enabled app-deb.service > /dev/null) \
  ; then
    _score-for-challenge 3
  else
    log-error 'app.service is either not running, not enabled, or both'
  fi
}

_check-debfile-service-running() {
  if \
    systemctl is-active app-deb.service > /dev/null && \
    systemctl is-enabled app-deb.service > /dev/null \
  ; then
    _score-for-challenge 4
  else
    log-error 'app-deb.service is either not running, not enabled, or both'
  fi
}

_check-webapp-reachable() {
  if timeout 1s curl -fsSL "${db_addr:-NOT_SET}:8000" > /dev/null ; then
    _score-for-challenge 5
  else
    log-error "web app is not reachable"
  fi
}

_check-ssh-setup() {
  if su - appuser -c "cd /tmp/ && git clone git@localhost:/srv/git/repositories/carrot-cruncher.git"; then
    rm -rf /tmp/carrot-cruncher
    _score-for-challenge 7
  else
    log-error "SSH Keys not setup successfully"
  fi
}

_check-git-branch-merged-correct() {
  local test_dir=${wsroot}/git-check
  local repo_dir="/srv/git/repositories/carrot-cruncher.git"
  if [ "$(git rev-parse master)" = "$(git rev-parse release/bunnies_v1)" ] then
    log-info "commits match"
  else
    log-error "commits don't match"
  fi
  pushd "${test_dir}" > /dev/null
  # Clone if the directory is empty
  if [ ! "$(ls -A ${test_dir})" ]; then
      su - git -c "GIT_SSH_COMMAND='ssh -o StrictHostKeyChecking=accept-new' git clone 'git@localhost:${repo_dir}' ${test_dir}"
  fi
  su - git -c "git fetch; git checkout main; git pull origin main"
  if grep -q carrot main.go; then
    _score-for-challenge 8
  else
      log-error "feature branch not merged correctly into main.\n"
  fi
  popd > /dev/null
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
  _check-git-branch-merged-correct
}

main
