#!/usr/bin/env bash
set -euo pipefail

wsroot='/.ws'
mkdir -p "${wsroot}"

# All directories are expected to have landed in /tmp
cp -r /tmp/{scripts,services,instructions} "${wsroot}"/
