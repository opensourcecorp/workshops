#!/usr/bin/env bash
set -euxo pipefail

GIT_USER=${GIT_USER:-git}
APP_USER=${APP_USER:-appuser}
GIT_HOME=${GIT_HOME:-/srv/git}
REPO_NAME=${REPO_NAME:-carrot-cruncher}
REPO_DIR="${GIT_HOME}/repositories/${REPO_NAME}.git"
WORK_DIR="/opt/git"
APP_DIR=${APP_DIR:-/opt/app}
DEFAULT_BRANCH=${DEFAULT_BRANCH:-main}
SSH_PORT=${SSH_PORT:-2332}
BRANCH_NAME=${BRANCH_NAME:-release/bunnies_v1}

# Install ezlog
command -v git >/dev/null || { apt-get update && apt-get install -y git; }
[[ -d /usr/local/share/ezlog ]] || git clone 'https://github.com/opensourcecorp/ezlog.git' /usr/local/share/ezlog
# shellcheck disable=SC1091
source /usr/local/share/ezlog/src/main.sh

function _setup_ssh_keys_for_git_user() {
  local ssh_dir="/home/${GIT_USER}/.ssh"
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
    cat "${public_key_file}" >>"${authorized_keys_file}"
  fi
  chmod 600 "${authorized_keys_file}"
  chown "${GIT_USER}:${GIT_USER}" "${authorized_keys_file}"
}

function _add_to_known_hosts() {
  local ssh_dir="/home/${GIT_USER}/.ssh"
  local known_hosts_file="${ssh_dir}/known_hosts"
  su - "${GIT_USER}" -c "ssh-keyscan -p ${SSH_PORT} -H localhost >> ${known_hosts_file}"
  chmod 644 "${known_hosts_file}"
}

function _setup_git_user() {
  if id "${GIT_USER}" &>/dev/null; then
    log-info "User ${GIT_USER} already exists."
  else
    log-info "setting up git user"
    useradd -m "${GIT_USER}" || return 1
    echo "${GIT_USER}:${GIT_USER}" | chpasswd
  fi
  _setup_ssh_keys_for_git_user
  # _add_to_known_hosts
  echo $(which git-shell) >>/etc/shells
  chsh --shell "$(command -v /bin/bash)" "${GIT_USER}"
}

function _init_git_repo() {
  log-info "Initializing remote carrot cruncher"
  rm -rf "${REPO_DIR}
  mkdir -p "${REPO_DIR}"
  pushd "${REPO_DIR}" >/dev/null
  su - ${GIT_USER} -c "git config --global init.defaultBranch ${DEFAULT_BRANCH}"
  su - ${GIT_USER} -c "git config --global user.email 'bugs@bigbadbunnies.com'"
  su - ${GIT_USER} -c "git config --global user.name 'Bugs Bunny'"
  su - ${GIT_USER} -c "pushd "${REPO_DIR}" >/dev/null; git init --bare"
  popd >/dev/null
  chown -R "${GIT_USER}:${GIT_USER}" "${REPO_DIR}"
}

function _setup_local_clone() {
  local clone_dir="${WORK_DIR}/${REPO_NAME}"
  log-info "cloning carrot cruncher"
  if [ -d "${WORK_DIR}" ]; then
    rm -rf "${WORK_DIR}"
  fi
  mkdir "${WORK_DIR}"
  chmod 777 "${WORK_DIR}"
  pushd "${WORK_DIR}" >/dev/null
  su - ${GIT_USER} -c "GIT_SSH_COMMAND='ssh -o StrictHostKeyChecking=accept-new' git clone '${GIT_USER}@localhost:${REPO_DIR}' ${clone_dir}"
  git config --global --add safe.directory /opt/git/carrot-cruncher
  pushd "${clone_dir}"
  cp -r "${APP_DIR}"/* .
  sed -i 's/PrintLine/Println/g' main.go
  su - ${GIT_USER} -c "pushd ${clone_dir}; git add .; git commit -m 'Initial commit'; git push origin"
  popd >/dev/null
}

function _create_release_branch() {
  local clone_dir="${WORK_DIR}/${REPO_NAME}"
  local branch_2="v1.0.2-rc-tmp-bugfix-2.0.1"
  pushd "${clone_dir}" >/dev/null
  log-info "setting up release branch"
  su - ${GIT_USER} -c "pushd ${clone_dir}; git checkout -b '${BRANCH_NAME}'"
  sed -i -e 's/printing/picking/g' -e 's/money/carrots/g' -e 's/CHA-CHING/CRUNCH/g' main.go
  echo -e "Name: Bugs Bunny\nSecurity Question Answer: 'Crunchy King'\nSSN: 1234-BUNNY" >banking.txt
  su - ${GIT_USER} -c "pushd ${clone_dir}; git add .; git commit -m 'Prepare release branch'"
  rm banking.txt
  su - ${GIT_USER} -c "pushd ${clone_dir}; git add .; git commit -m 'oops did not mean to add that...'"
  su - ${GIT_USER} -c "pushd ${clone_dir}; git push --set-upstream origin '${BRANCH_NAME}'"
  su - ${GIT_USER} -c "pushd ${clone_dir}; git checkout '${DEFAULT_BRANCH}'"
  su - ${GIT_USER} -c "pushd ${clone_dir}; git checkout -b '${branch_2}'"
  sed -i -e 's/printing/uh/g' -e 's/money/oh/g' -e 's/CHA-CHING/NO-NO-NOOOOO/g' main.go
  su - ${GIT_USER} -c "pushd ${clone_dir}; git add .; git commit -m 'I think we might be on to something...'"
  su - ${GIT_USER} -c "pushd ${clone_dir}; git push --set-upstream origin '${branch_2}'"
  su - ${GIT_USER} -c "pushd ${clone_dir}; git checkout '${DEFAULT_BRANCH}'"
  su - ${GIT_USER} -c "pushd ${clone_dir}; git branch -D ${BRANCH_NAME} ${branch_2}"
  popd >/dev/null
}

function _polish_off() {
  chown -R ${APP_USER}:${APP_USER} /opt/git # git appuser ownership of git directory
  chsh --shell "$(command -v git-shell)" "${GIT_USER}" # switch Git User to git-shell
}

function main() {
  _setup_git_user
  _init_git_repo
  _setup_local_clone
  _create_release_branch
  _polish_off
  log-info "Git server setup is complete."
}

main "$@"
