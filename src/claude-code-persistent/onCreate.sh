#!/bin/sh
# Copyright (c) 2026 @iamchriswick
# Licensed under the MIT License. See https://github.com/iamchriswick/devcontainers/tree/features/src/claude-code-persistent/LICENSE for license information.

set -e
. "$(dirname "$0")/util.sh"

# Lifecycle hooks run as the remote user, without the _REMOTE_USER variables.
_REMOTE_USER="${_REMOTE_USER:-$(id -un)}"

# Make sure there isn't already an installation of the tool
remote_user_has_command claude && {
	version=$(remote_user_run 'claude -v')
	echoyel "Claude Code $version is already installed"
	exit 0
}

# Dependencies
has_command curl || {
	echored "ERROR: This feature requires curl to be installed. Install with devcontainer feature ghcr.io/devcontainers/features/common-utils"
	exit 1
}

# Alpine dependencies
ensure_bash_on_alpine
if os_alpine; then
	apk add --no-cache libgcc libstdc++ ripgrep
fi

# Install Claude Code
echo "Installing Claude Code via https://claude.ai/install.sh"
echo ""
echo "Note: Claude install script does not output progress..."
# Run the install as the remote user, as script installs locally
remote_user_run 'curl -fsSL https://claude.ai/install.sh | bash'
add_to_user_profiles 'export PATH="$HOME/.local/bin:$PATH"'

# Verify installation
remote_user_has_command claude && {
	version=$(remote_user_run 'claude -v')
	echogrn "Claude Code $version installed successfully"
}
