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

# This file should have been added to on init
source /.ws/env || exit 1

# setup* and teardown* are bats-specifically-named pre-/post-test hook
# functions. <setup|teardown>_file run once, period, and <setup|teardown> run
# once *per test*
setup_file() {
  systemctl stop linux-workshop-admin.timer
  reset-score
}

teardown() {
  rm -f /opt/app/app
  rm -f /usr/local/bin/run-app
  reset-score
}

teardown_file() {
  teardown
  rm -f /home/admin/step_{2..20}.md # just to be sure to catch any non-0 or 1 steps
  systemctl start linux-workshop-admin.timer
}

reset-score() {
  psql -U postgres -h "${db_addr:-NOT_SET}" -c 'UPDATE scoring SET score = 0;'
}

get-score() {
  systemctl reset-failed # to reset rate limiter, if all else fails
  systemctl start linux-workshop-admin.service --wait
  score="$(psql -U postgres -h "${db_addr:-NOT_SET}" -tAc 'SELECT SUM(score) FROM scoring;')"
  printf '%s' "${score}"
}

################################################################################

@test "init steps succeeded" {
  [[ -f "/home/admin/step_0.md" ]]
  [[ -f "/home/admin/step_1.md" ]]
}

@test "step 1 scoring" {
  touch /opt/app/app && chmod +x /opt/app/app
  score="$(get-score)"
  printf 'DEBUG: Score from step 1: %s\n' "${score}"
  [[ "${score}" -eq 100 ]]
  [[ -f "/home/admin/step_2.md" ]] # next instruction gets put in homedir
}

# This test also end ups implicitly tests two steps' scores at once, which is
# good
@test "step 2 scoring" {
  touch /opt/app/app && chmod +x /opt/app/app
  ln -fs /opt/app/app /usr/local/bin/run-app
  score="$(get-score)"
  printf 'DEBUG: Score from step 2: %s\n' "${score}"
  [[ "${score}" -eq 200 ]] # step 1 + 2 score
  [[ -f "/home/admin/step_3.md" ]]
}

@test "score accumulates if run multiple times" {
  touch /opt/app/app && chmod +x /opt/app/app
  # each of these assignments does NOT increment the score var, but assigning it
  # suppresses the useless output from the first call anyway
  score="$(get-score)"
  score="$(get-score)"
  score="$(get-score)"
  printf 'DEBUG: Score after accumulation: %s\n' "${score}"
  [[ "${score}" -eq 300 ]]
}
