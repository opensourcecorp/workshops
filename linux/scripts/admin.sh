#!/usr/bin/env bash
set -euo pipefail

################################################################################
# This is the core admin service that will be run on each workshop machine. It
# determines & accrues the team's score, provides the next set of instructions
# to the team when appropriate, etc. It is to be placed at
# '/.ws/linux-workshop-admin'
################################################################################

wsroot='/.ws'
mkdir -p "${wsroot}"

scorefile="${wsroot}/score"

accrue-points() {
  printf '10\n' >> "${scorefile}"
}

provide-next-instruction() {
  next_instruction="$(awk '{ print $1 + 1 }' ${wsroot}/current_instruction)"
  if [[ ! -f "${HOME}/step_${next_instruction}.md" ]]; then
    cp "${wsroot}/instructions/${next_instruction}.md" "${HOME}/step_${next_instruction}.md"
  fi
}

# check-git-head-clean() { false ; }

# check-process-running() { false ; }

check-symlink() { false ; }

check-systemd-service-running() { false ; }

# check-firewall-rules() { false ; }

_main() {
  check-git-head-clean
  check-process-running
  check-symlink
  check-systemd-service-running
  check-firewall-rules
}

_main
