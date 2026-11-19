#!/bin/bash

set -e

source dev-container-features-test-lib

MOUNT_DIR="/mnt/devcontainers/features/claude-code-persistent"

check "tmp exists in the volume" test -d "$MOUNT_DIR/tmp"
check "tmpdir profile script exports CLAUDE_CODE_TMPDIR" grep -q "^export CLAUDE_CODE_TMPDIR=\"$MOUNT_DIR/tmp\"$" /etc/profile.d/claude-code-persistent-tmpdir.sh

reportResults
