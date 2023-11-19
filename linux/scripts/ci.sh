#!/usr/bin/env bash
set -euo pipefail

# Only try to install if running in GHA
if [[ -n "${GITHUB_ACTION:-}" ]] ; then
  apt-get update && apt-get install -y \
    golang \
    shellcheck
fi

printf '>>> Running shellcheck...\n'
find . \
  -type f \
  -name '*.sh' \
  -not -path '*.terraform*' \
  -print0 \
| xargs -0 -I{} shellcheck {}

printf '>>> Finding Go modules...\n'
find . -type f -name 'go.mod' > /tmp/go-modules
while read -r module ; do
  # Don't check the intentionally-broken dummy-app-src directory
  if [[ "${module}" =~ 'dummy-app-src' ]] ; then continue ; fi
  printf '>>> Running CI checks for Go module defined at %s...\n' "${module}"
  mod_dir="$(dirname "${module}")"
  (
    cd "${mod_dir}"
    printf '>>> Running go vet...\n'
    go vet ./...
    printf '>>> Running linter...\n'
    go run honnef.co/go/tools/cmd/staticcheck@latest ./...
    printf '>>> Running error checker...\n'
    go run github.com/kisielk/errcheck@latest ./...
  )
done < /tmp/go-modules

printf 'Success!\n'
