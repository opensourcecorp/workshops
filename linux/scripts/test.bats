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

if [[ "$(id -u)" -ne 0 ]] ; then
  printf 'Tests must be run as root user.\n' > /dev/stderr
  exit 1
fi

# This file should have been populated on init
source /.ws/env || exit 1

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

  reset-score
}

teardown_file() {
  teardown
  rm -f /home/appuser/step_{2..20}.md # just to be sure to catch any non-0 or 1 steps
  systemctl start linux-workshop-admin.timer
}

reset-score() {
  psql -U postgres -h "${db_addr:-NOT_SET}" -c 'UPDATE scoring SET score = 0;'
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
  printf '[Unit]
Description=Prints money!

[Service]
User=appuser
ExecStart=/usr/local/bin/run-app
Restart=always
RestartSec=2s

[Install]
WantedBy=multi-user.target
' > /etc/systemd/system/app.service
  systemctl daemon-reload
  systemctl enable app.service
  systemctl start app.service
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
  [[ "${score}" -eq 100 ]]
  [[ -f "/home/appuser/step_2.md" ]] # next instruction gets put in homedir
}

# This test also end ups implicitly tests two steps' scores at once, which is
# good
@test "step 2 scoring" {
  solve-step-2
  score="$(get-score)"
  printf 'DEBUG: Score from step 2: %s\n' "${score}"
  [[ "${score}" -eq 200 ]] # step 1 + 2 score
  [[ -f "/home/appuser/step_3.md" ]]
}

@test "step 3 scoring" {
  solve-step-3
  systemctl is-active app.service
}

@test "simulate score accumulation" {
  solve-step-1
  # each of these assignments does NOT increment the score var, but assigning it
  # suppresses the useless output from the first call anyway
  score="$(get-score)"
  score="$(get-score)"
  score="$(get-score)"
  printf 'DEBUG: Score after accumulation: %s\n' "${score}"
  [[ "${score}" -eq 300 ]]
}
