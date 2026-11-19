#!/bin/bash

set -e

source dev-container-features-test-lib

HOOKS_DIR="/usr/local/share/devcontainers/features/claude-code-persistent/hooks"

check "onCreate.sh reports Claude Code as already installed" bash -c "'$HOOKS_DIR/onCreate.sh' 2>&1 | grep -q 'is already installed'"
check "no native install in ~/.local/bin" test ! -e "$HOME/.local/bin/claude"
check "only one claude on PATH" test "$(bash -lc 'which -a claude' | xargs -n1 readlink -f | sort -u | wc -l)" -eq 1

reportResults
