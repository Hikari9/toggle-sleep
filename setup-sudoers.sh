#!/usr/bin/env bash
set -euo pipefail

TARGET_FILE="/etc/sudoers.d/toggle_sleep"
TEMP_FILE="$(mktemp)"

echo "==> Setting up passwordless sudo for pmset disablesleep and toggle-sleep..."

# Create sudoers line for current user
cat <<EOF > "${TEMP_FILE}"
${USER} ALL=(ALL) NOPASSWD: /usr/bin/pmset disablesleep *, ${HOME}/.local/bin/toggle-sleep
EOF

# Validate syntax before installing
if visudo -cf "${TEMP_FILE}" >/dev/null; then
    echo "==> Syntax valid. Installing to ${TARGET_FILE} (requires admin password once)..."
    sudo install -m 0440 "${TEMP_FILE}" "${TARGET_FILE}"
    rm -f "${TEMP_FILE}"
    echo "==> Success! Passwordless sudo is now configured for Sleep Toggle."
else
    echo "==> Error: Generated sudoers syntax is invalid." >&2
    rm -f "${TEMP_FILE}"
    exit 1
fi
