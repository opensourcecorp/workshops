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
  last_challenge_completed="$(find /home/appuser -type f -name 'challenge_*.md' | grep -E -o '[0-9]+' | sort -h | tail -n1)"
  max_possible_challenge_completed="$(find "${wsroot}"/instructions -type f -name 'challenge_*.md' | grep -E -o '[0-9]+' | sort -h | tail -n1)"
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

# Flag for checking if ssh is set
ssh_setup=1
_check-ssh-setup() {
  local test_dir=${wsroot}/git-checks/ssh
  local git_remote="/srv/git"
  local repo_dir="${git_remote}/repositories/carrot-cruncher.git"
  su - appuser -c "git config --global --add safe.directory ${test_dir}"
  if [[ -f ${git_remote}/ssh-keys/id_rsa.pub ]]; then
    log-info "Copying SSH Keys..."
    cat ${git_remote}/ssh-keys/id_rsa.pub >> /home/git/.ssh/authorized_keys && rm -f ${git_remote}/ssh-keys/id_rsa.pub
  fi
  su - appuser -c "ssh git@localhost" || exit_status=$?
  if [ "$exit_status" == 128 ]; then
    _score-for-challenge 6
    log-info "SSH successfully setup"
    ssh_setup=0
  else
    log-error "SSH Keys not setup successfully"
  fi
}

_check-git-branch-merged-correct() {
  local test_dir=${wsroot}/git-checks/merged
  local repo_dir="/srv/git/repositories/carrot-cruncher.git"
  if [ $ssh_setup -eq 1 ]; then
    log-warn "ssh keys aren't set"
    return 0
  fi
  [[ -d ${test_dir} ]] || mkdir -p ${test_dir} && chmod -R 777 ${test_dir}/..
  su - appuser -c "git config --global --add safe.directory ${test_dir}"
  [[ ! -d ${test_dir}/carrot-cruncher ]] || rm -rf ${test_dir:?}/carrot-cruncher
  su - appuser -c "git clone 'git@localhost:${repo_dir}' ${test_dir}/carrot-cruncher"
  if [ "$(su - appuser -c "cd ${test_dir}/carrot-cruncher; git fetch")" ]; then
    su - appuser -c "cd ${test_dir}/carrot-cruncher && git checkout main && git pull origin main"
  fi
  pushd "${test_dir}/carrot-cruncher" > /dev/null
  if grep -q carrot main.go; then
    popd > /dev/null
    rm -rf /${test_dir:?}/carrot-cruncher
    _score-for-challenge 7
    log-info "Feature branch merged correctly"
  else
    popd > /dev/null
    rm -rf /${test_dir:?}/carrot-cruncher
    log-error "Feature branch not merged correctly into main.\n"
  fi
  ### Secondary check for exact commit matches. Haven't gotten working yet, but enforces
  ### actually merging vs. copy/pasting code from branches
  # pushd "${repo_dir}" > /dev/null
  # git config --global --add safe.directory ${repo_dir}
  # if [ "$(git rev-parse main)" = "$(git rev-parse release/bunnies_v1)" ]; then
  #   log-info "commits match"
  # else
  #   log-error "commits don't match"
  # fi
}

### Challenge 8 Check. WIP
# _check-secret-removed() {
#   local secret_pattern="SSN: 1234-BUNNY"
#   if ! ${ssh_setup}; then
#     log-warn "ssh keys aren't set"
#     return 0
#   fi
#   pushd /srv/git/repositories/carrot-cruncher.git > /dev/null
#   git config --global --add safe.directory /srv/git/repositories/carrot-cruncher.git;
#   # Check each commit for the secret pattern
#   for commit in $(git rev-list --all); do
#       if git show "$commit":banking.txt | grep -q "$secret_pattern"; then
#           log-error "Secret found in commit $commit"
#           popd > /dev/null
#           return 0
#       fi
#   done
#   # _score-for-challenge 8
#   log-info "Secrets removed"
#   popd > /dev/null
# }

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
  _check-ssh-setup
  _check-git-branch-merged-correct
  # _check-secret-removed
}

main
