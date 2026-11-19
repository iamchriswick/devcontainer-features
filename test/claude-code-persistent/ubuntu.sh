#!/bin/bash

set -e

source dev-container-features-test-lib

HOOKS_DIR="/usr/local/share/devcontainers/features/claude-code-persistent/hooks"
MOUNT_DIR="/mnt/devcontainers/features/claude-code-persistent"

check "claude runs as the remote user" bash -lc "claude --version"
check "onCreate.sh is staged in the hooks directory" test -f "$HOOKS_DIR/onCreate.sh"
check "updateContent.sh is staged in the hooks directory" test -f "$HOOKS_DIR/updateContent.sh"
check "~/.claude is a symlink to the volume's conf" test "$(readlink "$HOME/.claude")" = "$MOUNT_DIR/conf"
check "confdir profile script exports CLAUDE_CONFIG_DIR" grep -q "^export CLAUDE_CONFIG_DIR=\"$MOUNT_DIR/conf\"$" /etc/profile.d/claude-code-persistent-confdir.sh
check "no .credentials.json in conf" test ! -e "$MOUNT_DIR/conf/.credentials.json"
check "no tmpdir profile script" test ! -e /etc/profile.d/claude-code-persistent-tmpdir.sh

reportResults
