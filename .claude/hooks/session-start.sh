#!/bin/bash
# Materialize SSH access to the Proxmox node for Claude Code on the web.
# Requires the env var PROXMOX_SSH_KEY (private key contents) configured
# as a secret in the environment.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
SSH_DIR="${HOME}/.ssh"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

install -m 644 "$PROJECT_DIR/.claude/proxmox_known_hosts" "$SSH_DIR/known_hosts"

cat > "$SSH_DIR/config" <<'EOF'
Host proxmox
  HostName vm.jlbusa.com
  Port 22
  User root
  IdentityFile ~/.ssh/proxmox
  IdentitiesOnly yes
  UserKnownHostsFile ~/.ssh/known_hosts
  StrictHostKeyChecking yes
  ServerAliveInterval 30
  ServerAliveCountMax 3
EOF
chmod 600 "$SSH_DIR/config"

if [ -n "${PROXMOX_SSH_KEY:-}" ]; then
  umask 077
  printf '%s\n' "$PROXMOX_SSH_KEY" > "$SSH_DIR/proxmox"
  # Normalize: strip any trailing blank lines, ensure single trailing newline.
  sed -i -e '$a\' "$SSH_DIR/proxmox"
  chmod 600 "$SSH_DIR/proxmox"
else
  echo "session-start: PROXMOX_SSH_KEY not set; \`ssh proxmox\` will fail until you add it to the environment secrets." >&2
fi
