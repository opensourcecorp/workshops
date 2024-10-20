#!/usr/bin/env bats

################################################################################
# Runs tests to ensure that the workshop's systems are behaving as intended.
#
# You'll note several `sytemctl start`s in the tests; these allow for bypassing
# the scoring timer and run the scoring service directly. You will also note
# quite a few `sleep`s, which allow for not only tests of score accumulation,
# but more annoyingly they prevent systemd from throwing its `start-limit-hit`
# error when you stop & start a service too fast in succession.
################################################################################

wsroot='/.ws'

if [[ "$(id -u)" -ne 0 ]]; then
  printf 'Tests must be run as root user.\n' >/dev/stderr
  exit 1
fi

# This file should have been populated on init
# shellcheck disable=SC1091
source "${wsroot}"/env || exit 1
[[ -n "${db_addr:-}" ]] || exit 1

# setup* and teardown* are bats-specifically-named pre-/post-test hook
# functions. <setup|teardown>_file run once, period, and <setup|teardown> run
# once *per test*
setup_file() {
  systemctl disable linux-workshop-admin.timer
  systemctl stop linux-workshop-admin.timer
  local git_dir=/srv/git/repositories/carrot-cruncher.git
  local backup_dir=/tmp/git.backup/
  mkdir ${backup_dir} && cp -r ${git_dir}/* "${backup_dir}/" # keep git challenges from messing up setup
  _reset-score
}

teardown() {
  # Challenge 1
  rm -f /opt/app/app
  sed -i 's/Println/PrintLine/g' /opt/app/main.go

  # Challenge 2
  rm -f /usr/local/bin/run-app

  # Challenge 3
  systemctl list-units | grep -q app.service && {
    systemctl stop app.service
    systemctl disable app.service
  }
  rm -f /etc/systemd/system/app.service
  systemctl daemon-reload

  # Challenge 4
  systemctl list-units | grep -q app-deb.service && {
    systemctl stop app-deb.service
    systemctl disable app-deb.service
  }
  rm -f /etc/systemd/system/app-deb.service
  systemctl daemon-reload
  rm -f /opt/app/dist/linux/app/usr/bin/app
  rm -f /opt/app/dist/linux/app.deb
  apt-get remove -y app || true

  # Challenge 5
  ufw deny out 8000

  # Challenge 6
  rm -rf /home/appuser/.ssh/*

  # Challenge 7
  local git_dir=/srv/git/repositories/carrot-cruncher.git
  local backup_dir=/tmp/git.backup/
  rm -rf /tmp/carrot-cruncher
  if [[ -d $backup_dir ]]; then
    rm -rf ${git_dir:?}/*
    cp -r ${backup_dir}/* ${git_dir}/
  fi
  chown -R git:git ${git_dir}
  _reset-score
}

teardown_file() {
  teardown
  rm -f /home/appuser/challenge_{2..200}.md # just to be sure to catch any non-0 or 1 challenges
  rm -f /home/appuser/congrats.md
  rm -f "${wsroot}"/team_has_been_congratulated
  rm -rf /tmp/git.backup/ # keep git challenges from messing up setup
  systemctl start linux-workshop-admin.timer
}

_reset-score() {
  psql -U postgres -h "${db_addr}" -c "
    DELETE FROM scoring WHERE team_name = '$(hostname)';
    INSERT INTO scoring (timestamp, team_name, last_challenge_completed, score) VALUES (NOW(), '$(hostname)', 0, 0);
  "
}

_get-score() {
  systemctl reset-failed # to reset systemd restart rate-limiter, if other means fail to do so
  systemctl start linux-workshop-admin.service --wait
  # Need to stop again becaue starting the .service restarts the timer because
  # of its 'Want' directive
  systemctl stop linux-workshop-admin.timer
  local score="$(psql -U postgres -h "${db_addr}" -tAc 'SELECT SUM(score) FROM scoring;')"
  printf '%s' "${score}"
}

# Helpers for redundant stuff in tests, like solving challenges, etc.
_solve-challenge-1() {
  sed -i 's/PrintLine/Println/g' /opt/app/main.go
  go build -o /opt/app/app /opt/app/main.go
}

_solve-challenge-2() {
  _solve-challenge-1
  ln -fs /opt/app/app /usr/local/bin/run-app
}

_solve-challenge-3() {
  _solve-challenge-2
  cat <<EOF > /etc/systemd/system/app.service
[Unit]
Description=Prints money!

[Service]
User=appuser
ExecStart=/usr/local/bin/run-app
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable app.service
  systemctl start app.service
}

_solve-challenge-4() {
  _solve-challenge-3
  cp /opt/app/app /opt/app/dist/linux/app/usr/bin/app
  dpkg-deb --build /opt/app/dist/linux/app
  apt-get install -y /opt/app/dist/linux/app.deb
  cat <<EOF > /etc/systemd/system/app-deb.service
[Unit]
Description=Prints money!

[Service]
User=appuser
ExecStart=/usr/bin/app
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl stop app.service
  systemctl disable app.service
  systemctl enable app-deb.service
  systemctl start app-deb.service
}

_solve-challenge-5() {
  ufw allow out 8000
}

_solve-challenge-6() {
  local ssh_dir="/home/appuser/.ssh"
  local public_key_file="${ssh_dir}/id_rsa.pub"
  local private_key_file="${ssh_dir}/id_rsa"
  local known_hosts_file="${ssh_dir}/known_hosts"
  local user="appuser"

  [[ -d "${ssh_dir}" ]] && rm -rf "${ssh_dir}"
  mkdir -p "${ssh_dir}"
  chown "${user}:${user}" "${ssh_dir}"
  chmod 700 "${ssh_dir}"
  su - "${user}" -c "ssh-keygen -t rsa -f ${private_key_file} -q -N ''"
  cp "${public_key_file}" "/srv/git/ssh-keys/"
  su - "${user}" -c "ssh-keyscan -H localhost >> ${known_hosts_file}" 2>/dev/null
}

_solve-challenge-7() {
  _solve-challenge-6
  cat /srv/git/ssh-keys/id_rsa.pub >> /home/git/.ssh/authorized_keys
  local user="appuser"
  local RELEASE_BRANCH=release/bunnies_v1
  [[ -d /tmp/carrot-cruncher ]] && rm -rf /tmp/carrot-cruncher
  su - "${user}" -c "pushd /tmp >/dev/null; \\
  git config --global --add safe.directory /tmp/; \\
  git clone git@localhost:/srv/git/repositories/carrot-cruncher.git && \\
  pushd carrot-cruncher >/dev/null && \\
  git merge origin/${RELEASE_BRANCH} && \\
  git push origin main && \\
  popd >/dev/null"
}

### Challenge 8 Check. WIP
# _solve-challenge-8() {
#   local user="appuser"
#   _solve-challenge-7
#   su - "${user}" -c "pushd /tmp/carrot-cruncher >/dev/null; \\
#   git config --global --add safe.directory /tmp/; \\
#   export FILTER_BRANCH_SQUELCH_WARNING=1 && \\
#   git filter-branch --force --index-filter \\
#   \"git rm --cached --ignore-unmatch banking.txt\" \\
#   --prune-empty --tag-name-filter cat -- --all && \\
#   git push --force --all && \\
#   popd >/dev/null"
# }

################################################################################

@test "init steps succeeded" {
  [[ -f "/home/appuser/challenge_0.md" ]]
  [[ -f "/home/appuser/challenge_1.md" ]]
}

@test "challenge 1" {
  # Fails before solution
  [[ ! -f /opt/app/app ]]
  [[ ! -x /opt/app/app ]]

  # Passes after solution
  _solve-challenge-1
  local score="$(_get-score)"
  sleep 1
  printf 'DEBUG: Score from challenge 1: %s\n' "${score}"
  [[ "${score}" -ge 100 ]]
  [[ -f "/home/appuser/challenge_2.md" ]] # next instruction gets put in homedir
}

# This test also end ups implicitly tests two challenges' scores at once, which is
# good
@test "challenge 2" {
  # Fails before solution
  [[ ! -f "/home/appuser/challenge_3.md" ]]
  [[ ! -L /usr/local/bin/run-app ]]

  # Passes after solution
  _solve-challenge-2
  local score="$(_get-score)"
  sleep 1
  printf 'DEBUG: Score from challenge 2: %s\n' "${score}"
  [[ "${score}" -ge 200 ]] # challenge 1 + 2 score
  [[ -f "/home/appuser/challenge_3.md" ]]
}

@test "challenge 3" {
  # Fails before solution
  systemctl is-active app.service && return 1
  systemctl is-enabled app.service && return 1

  # Passes after solution
  _solve-challenge-3
  local score="$(_get-score)"
  sleep 1
  printf 'DEBUG: Score from challenge 3: %s\n' "${score}"
  systemctl is-active app.service || return 1
  systemctl is-enabled app.service || return 1
  [[ -f "/home/appuser/challenge_4.md" ]]
}

@test "challenge 4" {
  # Fails before solution
  [[ ! -f "/home/appuser/challenge_5.md" ]]
  systemctl is-active app-deb.service && return 1
  systemctl is-enabled app-deb.service && return 1

  # Passes after solution
  _solve-challenge-4
  local score="$(_get-score)"
  sleep 1
  printf 'DEBUG: Score from challenge 4: %s\n' "${score}"
  systemctl is-active app-deb.service || return 1
  systemctl is-enabled app-deb.service || return 1
  [[ -f "/home/appuser/challenge_5.md" ]]
}

@test "challenge 5" {
  # Fails before solution
  [[ ! -f "/home/appuser/challenge_6.md" ]]

  # Passes after solution
  _solve-challenge-5
  local score="$(_get-score)"
  sleep 1
  printf 'DEBUG: Score from challenge 5: %s\n' "${score}"
  counter=0
  until timeout 1s curl -fsSL "${db_addr}:8000" ; do
    printf 'Web app not reachable, trying again...\n' >&2
    counter="$((counter + 1))"
    if [[ "${counter}" -ge 30 ]] ; then
      return 1
    fi
    sleep 1
  done
  [[ -f "/home/appuser/challenge_6.md" ]]
}

@test "challenge 6" {
  # Fails before solution
  [[ ! -f "/home/appuser/challenge_7.md" ]]

  # Passes after solution
  _solve-challenge-6
  local score="$(_get-score)"
  sleep 1
  printf 'DEBUG: Score from challenge 6: %s\n' "${score}"
  su - "appuser" -c "pushd /opt/git/carrot-cruncher >/dev/null; git config --global --add safe.directory /opt/git/carrot-cruncher; git fetch"
  [[ -f "/home/appuser/challenge_7.md" ]]
}

@test "challenge 7" {
  # Fails before solution
  # [[ ! -f "/home/appuser/challenge_8.md" ]]

  # Passes after solution
  local git_dir=/srv/git/repositories/carrot-cruncher.git
  _solve-challenge-7
  local score="$(_get-score)"
  sleep 1
  printf 'DEBUG: Score from challenge 7: %s\n' "${score}"
  pushd "${git_dir}" >/dev/null
  git config --global --add safe.directory ${git_dir}
  if [ ! "$(git rev-parse main)" = "$(git rev-parse release/bunnies_v1)" ] ; then
    return 1
  fi
  sleep 1
  popd >/dev/null
  [[ -f "/home/appuser/congrats.md" ]]
}

### Challenge 8 Check. WIP
# @test "challenge 8" {
#   # Fails before solution
#   [[ ! -f "/home/appuser/congrats.md" ]]

#   _solve-challenge-8
#   local score="$(_get-score)"
#   sleep 1
#   printf 'DEBUG: Score from challenge 8: %s\n' "${score}"
#   pushd /srv/git/repositories/carrot-cruncher.git > /dev/null
#   local secret_pattern="SSN: 1234-BUNNY"
#   git config --global --add safe.directory /srv/git/repositories/carrot-cruncher.git;

#   # Check each commit for the secret pattern
#   for commit in $(git rev-list --all); do
#       if git show "$commit":banking.txt | grep -q "$secret_pattern"; then
#           printf "Secret found in commit $commit"
#           return 1
#       fi
#   done
#   sleep 5
#   popd >/dev/null
#   [[ -f "/home/appuser/congrats.md" ]]
# }
