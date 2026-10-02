#!/usr/bin/env bash
# Copies the AAP containerized setup bundle and the Terraform-rendered
# inventory to the EC2 host, then runs the installer there.
#
# Usage:
#   ./scripts/install-aap.sh /path/to/ansible-automation-platform-containerized-setup-bundle-<version>-x86_64.tar.gz
#
# Download the bundle from https://access.redhat.com/downloads/content/480
# (Ansible Automation Platform -> Setup Bundle, containerized).
set -euo pipefail

BUNDLE="${1:-}"
if [[ -z "${BUNDLE}" || ! -f "${BUNDLE}" ]]; then
  echo "usage: $0 <path-to-containerized-setup-bundle.tar.gz>" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$(dirname "${SCRIPT_DIR}")"

cd "${TF_DIR}"

PUBLIC_IP="$(terraform output -raw public_ip)"
SSH_USER="$(terraform output -raw ssh_user)"
INVENTORY="$(terraform output -raw installer_inventory_path)"
KEY_PATH="$(terraform output -raw ssh_private_key_path 2>/dev/null || true)"

SSH_OPTS=(-o StrictHostKeyChecking=accept-new -o ServerAliveInterval=30)
if [[ -n "${KEY_PATH}" && "${KEY_PATH}" != "null" ]]; then
  SSH_OPTS+=(-i "${KEY_PATH}")
fi

BUNDLE_NAME="$(basename "${BUNDLE}")"
BUNDLE_DIR="${BUNDLE_NAME%.tar.gz}"

echo "==> Waiting for cloud-init prerequisites on ${PUBLIC_IP}"
until ssh "${SSH_OPTS[@]}" "${SSH_USER}@${PUBLIC_IP}" \
  'test -f /var/lib/cloud/instance/aap-prereqs-done' 2>/dev/null; do
  sleep 10
done

echo "==> Copying setup bundle and inventory"
scp "${SSH_OPTS[@]}" "${BUNDLE}" "${INVENTORY}" "${SSH_USER}@${PUBLIC_IP}:~/"

echo "==> Running the AAP containerized installer (this takes 20-40 minutes)"
ssh "${SSH_OPTS[@]}" -t "${SSH_USER}@${PUBLIC_IP}" bash -s <<EOF
set -euo pipefail
cd ~
tar xzf "${BUNDLE_NAME}"
cp ~/inventory "${BUNDLE_DIR}/inventory"
cd "${BUNDLE_DIR}"
ansible-playbook -i inventory ansible.containerized_installer.install
EOF

echo
echo "==> AAP is available at: $(terraform output -raw aap_url)"
echo "    username: $(terraform output -raw aap_admin_username)"
echo "    password: terraform output -raw aap_admin_password"
