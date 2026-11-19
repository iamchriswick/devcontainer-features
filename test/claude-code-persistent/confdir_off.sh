#!/bin/bash

set -e

source dev-container-features-test-lib

MOUNT_DIR="/mnt/devcontainers/features/claude-code-persistent"

check "~/.claude.json is a symlink to conf/.claude.json" test "$(readlink "$HOME/.claude.json")" = "$MOUNT_DIR/conf/.claude.json"
check "~/.claude/.credentials.json is a symlink to conf/.credentials.json" test "$(readlink "$HOME/.claude/.credentials.json")" = "$MOUNT_DIR/conf/.credentials.json"

reportResults
