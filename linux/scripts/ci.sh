#!/usr/bin/env bash
set -euo pipefail

# Only try to install if running in GHA
if [[ -n "${GITHUB_ACTION:-}" ]] ; then
  sudo apt-get update && sudo apt-get install -y \
    shellcheck
fi

###
printf '> Running shellcheck...\n'
find . \
  -type f \
  -name '*.sh' \
  -not -path '*.terraform*' \
  -print0 \
| xargs -0 -I{} shellcheck {}

###
printf '> Finding Go modules...\n'
find . -type f -name 'go.mod' > /tmp/go-modules

if [[ "$(</tmp/go-modules wc -l)" -gt 0 ]] ; then
  printf '> Installing CI checks for Go...\n'
  for pkg in \
    honnef.co/go/tools/cmd/staticcheck@latest \
    github.com/kisielk/errcheck@latest \
  ; do
    go install "${pkg}"
  done
fi

while read -r module ; do
  # Don't check the intentionally-broken dummy-app-src directory
  if [[ "${module}" =~ 'dummy-app-src' ]] ; then continue ; fi
  printf '> Running CI checks for Go module defined at %s...\n' "${module}"
  mod_dir="$(dirname "${module}")"
  (
    cd "${mod_dir}"
    printf '>> Running go vet...\n'
    go vet ./...
    printf '>> Running linter...\n'
    staticcheck ./...
    printf '>> Running error checker...\n'
    errcheck ./...
  )
done < /tmp/go-modules

# TODO: enable in a separate PR
# printf '> Running IaC linter...\n'
# go run github.com/terraform-linters/tflint@latest --chdir=./terraform

###
printf '> Success!\n'
