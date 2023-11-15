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

if [[ "$(id -u)" -ne 0 ]] ; then
  printf 'Tests must be run as root user.\n' > /dev/stderr
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

  # Step 5
  ufw deny out 8000

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
  psql -U postgres -h "${db_addr}" -c "
    DELETE FROM scoring WHERE team_name = '$(hostname)';
    INSERT INTO scoring (timestamp, team_name, last_step_completed, score) VALUES (NOW(), '$(hostname)', 0, 0);
  "
}

get-score() {
  systemctl reset-failed # to reset systemd restart rate-limiter, if other means fail to do so
  systemctl start linux-workshop-admin.service --wait
  local score="$(psql -U postgres -h "${db_addr}" -tAc 'SELECT SUM(score) FROM scoring;')"
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

solve-step-4() {
  solve-step-3
  cp /opt/app/app /opt/app/dist/debian/app/usr/bin/app
  dpkg-deb --build /opt/app/dist/debian/app
  apt-get install -y /opt/app/dist/debian/app.deb
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

solve-step-5() {
  ufw allow out 8000
}

################################################################################

@test "init steps succeeded" {
  [[ -f "/home/appuser/step_0.md" ]]
  [[ -f "/home/appuser/step_1.md" ]]
}

@test "step 1" {
  # Fails before solution
  [[ ! -f /opt/app/app ]]
  [[ ! -x /opt/app/app ]]

  # Passes after solution
  solve-step-1
  local score="$(get-score)"
  printf 'DEBUG: Score from step 1: %s\n' "${score}"
  [[ "${score}" -ge 100 ]]
  [[ -f "/home/appuser/step_2.md" ]] # next instruction gets put in homedir
}

# This test also end ups implicitly tests two steps' scores at once, which is
# good
@test "step 2" {
  # Fails before solution
  [[ ! -f "/home/appuser/step_3.md" ]]
  [[ ! -L /usr/local/bin/run-app ]]

  # Passes after solution
  solve-step-2
  local score="$(get-score)"
  printf 'DEBUG: Score from step 2: %s\n' "${score}"
  [[ "${score}" -ge 200 ]] # step 1 + 2 score
  [[ -f "/home/appuser/step_3.md" ]]
}

@test "step 3" {
  # Fails before solution
  systemctl is-active app.service && return 1
  systemctl is-enabled app.service && return 1

  # Passes after solution
  solve-step-3
  local score="$(get-score)"
  printf 'DEBUG: Score from step 3: %s\n' "${score}"
  systemctl is-active app.service || return 1
  systemctl is-enabled app.service || return 1
  [[ -f "/home/appuser/step_4.md" ]]
}

@test "step 4" {
  # Fails before solution
  [[ ! -f "/home/appuser/step_5.md" ]]
  systemctl is-active app-deb.service && return 1
  systemctl is-enabled app-deb.service && return 1

  # Passes after solution
  solve-step-4
  local score="$(get-score)"
  printf 'DEBUG: Score from step 4: %s\n' "${score}"
  systemctl is-active app-deb.service || return 1
  systemctl is-enabled app-deb.service || return 1
  [[ -f "/home/appuser/step_5.md" ]]
}

@test "step 5" {
  # Fails before solution
  # [[ ! -f "/home/appuser/step_6.md" ]]

  # Passes after solution
  solve-step-5
  local score="$(get-score)"
  printf 'DEBUG: Score from step 5: %s\n' "${score}"
  counter=0
  until timeout 1s curl -fsSL "${db_addr}:8000" ; do
    printf 'Web app not reachable, trying again...\n' >&2
    counter="$((counter + 1))"
    sleep 5
    if [[ "${counter}" -ge 10 ]] ; then
      return 1
    fi
  done
  # [[ -f "/home/appuser/step_6.md" ]]
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
