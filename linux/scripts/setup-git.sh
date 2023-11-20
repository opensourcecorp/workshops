#!/usr/bin/env bash
set -euo pipefail

GIT_USER=${GIT_USER:-appuser}
GIT_HOME=${GIT_HOME:-/home/appuser}
REPO_NAME=${REPO_NAME:-carrot-cruncher}
REPO_DIR="${GIT_HOME}/repositories/${REPO_NAME}.git"
WORK_DIR="/opt/git"
APP_DIR=${APP_DIR:-/opt/app}
DEFAULT_BRANCH=${DEFAULT_BRANCH:-main}
SSH_PORT=${SSH_PORT:-2332}

function setup_ssh_keys_for_git_user() {
  local ssh_dir="${GIT_HOME}/.ssh"
  local public_key_file="${ssh_dir}/id_rsa.pub"
  local private_key_file="${ssh_dir}/id_rsa"
  local authorized_keys_file="${ssh_dir}/authorized_keys"
  
  # Create .ssh directory if it doesn't exist
  mkdir -p "${ssh_dir}"
  chown "${GIT_USER}:${GIT_USER}" "${ssh_dir}"
  chmod 700 "${ssh_dir}"
  
  # Generate the SSH key pair if it doesn't exist
  if [[ ! -f "${public_key_file}" ]]; then
    su - "${GIT_USER}" -c "ssh-keygen -t rsa -f ${private_key_file} -q -N ''"
  fi

  # Add the public key to authorized_keys if it's not already there
  if ! grep -q "$(cat "${public_key_file}")" "${authorized_keys_file}" 2>/dev/null; then
    cat "${public_key_file}" >> "${authorized_keys_file}"
  fi
  chmod 600 "${authorized_keys_file}"
  chown "${GIT_USER}:${GIT_USER}" "${authorized_keys_file}"
}

function add_to_known_hosts() {
  local ssh_dir="${GIT_HOME}/.ssh"
  local known_hosts_file="${ssh_dir}/known_hosts"
  su - "${GIT_USER}" -c "ssh-keyscan -p ${SSH_PORT} -H localhost >> ${known_hosts_file}"
  chmod 644 "${known_hosts_file}"
}

function setup_git_user() {
  if id "${GIT_USER}" &>/dev/null; then
    echo "User ${GIT_USER} already exists."
  else
    useradd -m "${GIT_USER}" || return 1
    echo "${GIT_USER}:${GIT_USER}" | chpasswd
    chsh --shell "$(command -v bash)" "${GIT_USER}"
  fi
  setup_ssh_keys_for_git_user
  add_to_known_hosts
}

function init_git_repo() {
  mkdir -p "${REPO_DIR}"
  pushd "${REPO_DIR}" > /dev/null
  git init --bare
  git config --global init.defaultBranch "${DEFAULT_BRANCH}"
  git config --global user.email "bugs@bigbadbunnies.com"
  git config --global user.name "Bugs Bunny"
  popd > /dev/null
  chown -R "${GIT_USER}:${GIT_USER}" "${REPO_DIR}"
}

function setup_local_clone() {
  local clone_dir="${WORK_DIR}/${REPO_NAME}"
  mkdir -p "${clone_dir}"
  pushd "${clone_dir}" > /dev/null
  git clone "appuser://${REPO_DIR}" .
  cp -r "${APP_DIR}"/* .
  git add .
  git commit -m "Initial commit"
  popd > /dev/null
}

function create_release_branch() {
  pushd "${WORK_DIR}/${REPO_NAME}" > /dev/null
  git checkout -b release/bunnies_v1
  sed -i -e 's/printing/picking/g' -e 's/money/carrots/g' -e 's/CHA-CHING/CRUNCH/g' main.go
  echo -e "Name: Bugs Bunny\nSecurity Question Answer: 'Crunchy King'\nSSN: 1234-BUNNY" > banking.txt
  git add .
  git commit -m "Prepare release branch"
  rm banking.txt
  git add .
  git commit -m "oops didn't mean to add that..."
  git push
  git checkout "${DEFAULT_BRANCH}"
  git push
  popd > /dev/null
}

function main() {
  setup_git_user
  init_git_repo
  setup_local_clone
  create_release_branch
  echo "Git server setup is complete."
}

main "$@"
