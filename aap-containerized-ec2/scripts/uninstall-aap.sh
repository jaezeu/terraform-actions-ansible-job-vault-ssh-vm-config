#!/usr/bin/env bash
# Runs the AAP containerized uninstall playbook on the EC2 host. Useful when
# re-running the installer from scratch without recreating the instance.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$(dirname "${SCRIPT_DIR}")"
cd "${TF_DIR}"

PUBLIC_IP="$(terraform output -raw public_ip)"
SSH_USER="$(terraform output -raw ssh_user)"
KEY_PATH="$(terraform output -raw ssh_private_key_path 2>/dev/null || true)"

SSH_OPTS=(-o StrictHostKeyChecking=accept-new)
if [[ -n "${KEY_PATH}" && "${KEY_PATH}" != "null" ]]; then
  SSH_OPTS+=(-i "${KEY_PATH}")
fi

ssh "${SSH_OPTS[@]}" -t "${SSH_USER}@${PUBLIC_IP}" bash -s <<'EOF'
set -euo pipefail
cd ~/ansible-automation-platform-containerized-setup-bundle-*/
ansible-playbook -i inventory ansible.containerized_installer.uninstall
EOF
