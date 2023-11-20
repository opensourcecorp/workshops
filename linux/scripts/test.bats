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

# setup* and teardown* are bats-specifically-named pre-/post-test hook
# functions. <setup|teardown>_file run once, period, and <setup|teardown> run
# once *per test*
setup_file() {
  systemctl stop linux-workshop-admin.timer
  reset-score
}

teardown() {
  # Step 1
  rm -f /opt/app/app
  sed -i 's/Println/PrintLine/g' /opt/app/main.go

  # Step 2
  rm -f /usr/local/bin/run-app

  # Step 3
  systemctl list-units | grep -q app.service && {
    systemctl stop app.service
    systemctl disable app.service
  }
  rm -f /etc/systemd/system/app.service
  systemctl daemon-reload

  # Step 4
  systemctl list-units | grep -q app-deb.service && {
    systemctl stop app-deb.service
    systemctl disable app-deb.service
  }
  rm -f /etc/systemd/system/app-deb.service
  systemctl daemon-reload
  rm -f /opt/app/dist/debian/app/usr/bin/app
  rm -f /opt/app/dist/debian/app.deb
  apt-get remove -y app

  reset-score
}

teardown_file() {
  teardown
  rm -f /home/appuser/step_{2..200}.md # just to be sure to catch any non-0 or 1 steps
  rm -f /home/appuser/congrats.md
  rm -r "${wsroot}"/team_has_been_congratulated
  systemctl start linux-workshop-admin.timer
}

reset-score() {
  psql -U postgres -h "${db_addr:-NOT_SET}" -c "
    DELETE FROM scoring WHERE team_name = '$(hostname)';
    INSERT INTO scoring (timestamp, team_name, last_step_completed, score) VALUES (NOW(), '$(hostname)', 0, 0);
  "
}

get-score() {
  systemctl reset-failed # to reset systemd restart rate-limiter, if other means fail to do so
  systemctl start linux-workshop-admin.service --wait
  score="$(psql -U postgres -h "${db_addr:-NOT_SET}" -tAc 'SELECT SUM(score) FROM scoring;')"
  printf '%s' "${score}"
}

# Helpers for redundant stuff in tests, like solving steps, etc.
solve-step-1() {
  sed -i 's/PrintLine/Println/g' /opt/app/main.go
  go build -o /opt/app/app /opt/app/main.go
}

solve-step-2() {
  solve-step-1
  ln -fs /opt/app/app /usr/local/bin/run-app
}

solve-step-3() {
  solve-step-2
  cat <<EOF >/etc/systemd/system/app.service
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

solve-step-4() {
  solve-step-3
  cp /opt/app/app /opt/app/dist/debian/app/usr/bin/app
  dpkg-deb --build /opt/app/dist/debian/app
  apt-get install -y /opt/app/dist/debian/app.deb
  cat <<EOF >/etc/systemd/system/app-deb.service
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

solve_challenge_3.1() {
  local RELEASE_BRANCH=release/bunnies_v1
  pushd "/opt/git/carrot-cruncher" >/dev/null
  git merge "${RELEASE_BRANCH}"
  git push origin main
  popd >/dev/null
}
################################################################################

@test "init steps succeeded" {
  [[ -f "/home/appuser/step_0.md" ]]
  [[ -f "/home/appuser/step_1.md" ]]
}

@test "step 1 scoring" {
  solve-step-1
  score="$(get-score)"
  printf 'DEBUG: Score from step 1: %s\n' "${score}"
  [[ "${score}" -ge 100 ]]
  [[ -f "/home/appuser/step_2.md" ]] # next instruction gets put in homedir
}

# This test also end ups implicitly tests two steps' scores at once, which is
# good
@test "step 2 scoring" {
  solve-step-2
  score="$(get-score)"
  printf 'DEBUG: Score from step 2: %s\n' "${score}"
  [[ "${score}" -ge 200 ]] # step 1 + 2 score
  [[ -f "/home/appuser/step_3.md" ]]
}

@test "step 3 scoring" {
  solve-step-3
  systemctl is-active app.service || { printf 'NOT ACTIVE\n' && return 1; }
  systemctl is-enabled app.service || { printf 'NOT ENABLED\n' && return 1; }
}

@test "step 4 scoring" {
  solve-step-4
  systemctl is-active app-deb.service || { printf 'NOT ACTIVE\n' && return 1; }
  systemctl is-enabled app-deb.service || { printf 'NOT ENABLED\n' && return 1; }
}

@test "simulate score accumulation" {
  solve-step-1
  # each of these assignments does NOT increment the score var, but assigning it
  # suppresses the useless output from the first call anyway
  score="$(get-score)"
  score="$(get-score)"
  score="$(get-score)"
  printf 'DEBUG: Score after accumulation: %s\n' "${score}"
  [[ "${score}" -ge 300 ]]
}
