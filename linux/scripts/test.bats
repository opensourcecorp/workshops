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

setup() {
  teardown
  systemctl stop linux-workshop-admin.timer
}

teardown() {
  rm -f /opt/app/app
  rm -f /usr/local/bin/run-app
  sqlite3 /.ws/main.db 'UPDATE scoring SET score = 0;'
  sleep 3
  systemctl start linux-workshop-admin.timer
}

get-score() {
  systemctl start linux-workshop-admin.service --wait
  score="$(sqlite3 /.ws/main.db 'SELECT SUM(score) FROM scoring;')"
  printf '%s' "${score}"
}

@test "systemd timer scoring accumulation (this will be slow)" {
  # Since we actually need the timer that was stopped in setup() here, we've
  # gotta manually restart it
  sleep 5
  systemctl start linux-workshop-admin.timer
  touch /opt/app/app && chmod +x /opt/app/app
  sleep 6 # long enough for 2ish, 5s timer runs. This seems short to me, but it works :shrug:
  score="$(get-score)"
  printf 'Score after some accumulation: %s\n' "${score}"
  [[ "${score}" -ge 100 ]]
}

@test "step 1 scoring" {
  touch /opt/app/app && chmod +x /opt/app/app
  score="$(get-score)"
  printf 'Score from step 1: %s\n' "${score}"
  [[ "${score}" -eq 100 ]]
}

@test "step 2 scoring" {
  touch /opt/app/app && chmod +x /opt/app/app
  ln -fs /opt/app/app /usr/local/bin/run-app
  score="$(get-score)"
  printf 'Score from step 2: %s\n' "${score}"
  [[ "${score}" -eq 300 ]] # step 1 + 2 score
}
