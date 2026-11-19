#!/bin/sh
# Copyright (c) 2026 @iamchriswick
# Licensed under the MIT License. See https://github.com/iamchriswick/devcontainers/tree/features/src/claude-code-persistent/LICENSE for license information.

set -e
. "$(dirname "$0")/util.sh"

# Feature options (passed as environment variables by Dev Container)
CCP_CONFDIR="${CCP_CONFDIR:-true}"
CCP_JSON="${CCP_JSON:-true}"
CCP_CRED="${CCP_CRED:-false}"
CCP_TMPDIR="${CCP_TMPDIR:-false}"

DCAT="feature"
DCAT_ID="claude-code-persistent"
LCH_DIR="/usr/local/share/devcontainers/${DCAT}s/$DCAT_ID/hooks"
DCAT_MDIR="/mnt/devcontainers/${DCAT}s/$DCAT_ID"

# Mount points
MOUNT_CCP_CONFDIR="$DCAT_MDIR/conf"
MOUNT_CCP_TMPDIR="$DCAT_MDIR/tmp"

# User paths
USER_ID="$(id -u)"
USER_HOME="${_REMOTE_USER_HOME:-$HOME}"
USER_NAME="${_REMOTE_USER:-$(whoami)}"

# Claude Code user scope paths
CC_CONFDIR_DEFAULT="$USER_HOME/.claude"
CC_JSON_DEFAULT="$USER_HOME/.claude.json"
CC_CRED_DEFAULT="$CC_CONFDIR_DEFAULT/.credentials.json"

# Claude Code default temp dir path
CC_TMPDIR_DEFAULT="${CLAUDE_CODE_TMPDIR:-/tmp/claude-$USER_ID}"

# Helper: conditional sudo
maybe_sudo() {
	if [ "$USER_ID" -eq 0 ]; then
		"$@"
	else
		sudo "$@"
	fi
}

echoblu "Setting up $DCAT_ID..."

# Create Claude Code config directory
if [ "$CCP_CONFDIR" = "true" ] || [ "$CCP_JSON" = "true" ] || [ "$CCP_CRED" = "true" ]; then
	mkdir -p "$MOUNT_CCP_CONFDIR"
fi

# Handle ~/.claude/ directory persistense
if [ "$CCP_CONFDIR" = "true" ]; then

	if [ -d "$MOUNT_CCP_CONFDIR" ]; then
		echo "Configuring ~/.claude/ persistence..."

		# Set ownership of mount point
		maybe_sudo chown -R "$USER_NAME:$USER_NAME" "$MOUNT_CCP_CONFDIR"

		# Back up existing directory if it exists and is not a symlink
		if [ -d "$CC_CONFDIR_DEFAULT" ] && [ ! -L "$CC_CONFDIR_DEFAULT" ]; then
			echo "Backing up existing ~/.claude/ to ~/.claude.old/"
			if [ -d "$CC_CONFDIR_DEFAULT.old" ]; then
				rm -rf "$CC_CONFDIR_DEFAULT.old"
			fi
			mv "$CC_CONFDIR_DEFAULT" "$CC_CONFDIR_DEFAULT.old"

			# If volume is empty, copy the backup contents to volume
			if [ -z "$(ls -A "$MOUNT_CCP_CONFDIR")" ]; then
				echo "Migrating existing ~/.claude/ data to volume..."
				cp -r "$CC_CONFDIR_DEFAULT.old/." "$MOUNT_CCP_CONFDIR/"
			fi
		fi

		# Remove existing symlink if present
		if [ -L "$CC_CONFDIR_DEFAULT" ]; then
			rm "$CC_CONFDIR_DEFAULT"
		fi

		# Create symlink
		ln -s "$MOUNT_CCP_CONFDIR" "$CC_CONFDIR_DEFAULT"
		echogrn "✓ ~/.claude/ -> $MOUNT_CCP_CONFDIR"

		# Expose CLAUDE_CONFIG_DIR to all login shells (and VS Code's env probe)
		echo "export CLAUDE_CONFIG_DIR=\"$MOUNT_CCP_CONFDIR\"" |
			maybe_sudo tee /etc/profile.d/claude-code-persistent-confdir.sh >/dev/null

	else
		echored "⚠ Mount point $MOUNT_CCP_CONFDIR not found, skipping ~/.claude/ persistence"
	fi
else
	echoyel "Skipping ~/.claude/ persistence (disabled)"
fi

# Handle ~/.claude.json file persistence
if [ "$CCP_JSON" = "true" ]; then

	if [ "$CCP_CONFDIR" = "false" ]; then
		echo "Configuring ~/.claude.json persistence..."

		# The actual file inside the volume
		MOUNT_CC_JSON_FILE="$MOUNT_CCP_CONFDIR/.claude.json"

		# Back up existing file if it exists and is not a symlink
		if [ -f "$CC_JSON_DEFAULT" ] && [ ! -L "$CC_JSON_DEFAULT" ]; then
			echo "Backing up existing ~/.claude.json to ~/.claude.json.old"
			if [ -f "$CC_JSON_DEFAULT.old" ]; then
				rm -f "$CC_JSON_DEFAULT.old"
			fi
			mv "$CC_JSON_DEFAULT" "$CC_JSON_DEFAULT.old"

			# If volume file doesn't exist, copy the backup to volume
			if [ ! -f "$MOUNT_CC_JSON_FILE" ]; then
				cp "$CC_JSON_DEFAULT.old" "$MOUNT_CC_JSON_FILE"
			fi
		fi

		# Remove existing symlink if present
		if [ -L "$CC_JSON_DEFAULT" ]; then
			rm "$CC_JSON_DEFAULT"
		fi

		# Create symlink to file inside volume
		ln -s "$MOUNT_CC_JSON_FILE" "$CC_JSON_DEFAULT"
		echogrn "✓ ~/.claude.json -> $MOUNT_CC_JSON_FILE"

	elif [ "$CCP_CONFDIR" = "true" ]; then
		echogrn "✓ ~/.claude.json -> $MOUNT_CCP_CONFDIR/.claude.json"
	else
		echored "⚠ Mount point $MOUNT_CCP_CONFDIR not found, skipping ~/.claude.json persistence"
	fi
else
	echoyel "Skipping ~/.claude.json persistence (disabled)"
fi

# Handle ~/.claude/.credentials.json file persistence
if [ "$CCP_CRED" = "true" ]; then

	if [ "$CCP_CONFDIR" = "false" ]; then
		echo "Configuring ~/.claude/.credentials.json persistence..."

		# The actual file inside the volume
		MOUNT_CCP_CRED_FILE="$MOUNT_CCP_CONFDIR/.credentials.json"

		# Back up existing file if it exists and is not a symlink
		if [ -f "$CC_CRED_DEFAULT" ] && [ ! -L "$CC_CRED_DEFAULT" ]; then
			echo "Backing up existing ~/.claude/.credentials.json to ~/.claude/.credentials.json.old"
			if [ -f "$CC_CRED_DEFAULT.old" ]; then
				rm -f "$CC_CRED_DEFAULT.old"
			fi
			mv "$CC_CRED_DEFAULT" "$CC_CRED_DEFAULT.old"

			# If volume file doesn't exist, copy the backup to volume
			if [ ! -f "$MOUNT_CCP_CRED_FILE" ]; then
				cp "$CC_CRED_DEFAULT.old" "$MOUNT_CCP_CRED_FILE"
			fi
		fi

		# Remove existing symlink if present
		if [ -L "$CC_CRED_DEFAULT" ]; then
			rm "$CC_CRED_DEFAULT"
		fi

		# Create symlink to file inside volume
		ln -s "$MOUNT_CCP_CRED_FILE" "$CC_CRED_DEFAULT"
		echogrn "✓ ~/.claude/.credentials.json -> $MOUNT_CCP_CRED_FILE"

	elif [ "$CCP_CONFDIR" = "true" ]; then
		echogrn "✓ ~/.claude/.credentials.json -> $MOUNT_CCP_CONFDIR/.credentials.json"
	else
		echored "⚠ Mount point $MOUNT_CCP_CONFDIR not found, skipping ~/.claude/.credentials.json persistence"
	fi
elif [ "$CCP_CRED" = "false" ]; then
	# The actual file inside the volume
	MOUNT_CCP_CRED_FILE="$MOUNT_CCP_CONFDIR/.credentials.json"

	if [ "$CCP_CONFDIR" = "true" ] && [ -f "$MOUNT_CCP_CRED_FILE" ]; then
		echo "Removing ~/.claude/.credentials.json persistence..."

		# Rmove existing baackup file
		if [ -f "$CC_CRED_DEFAULT.old" ]; then
			echoyel "~/.claude/.credentials.json.old backup removed..."
			rm -f "$CC_CRED_DEFAULT.old"
		fi

		# If volume file exist, delete it from the volume
		if [ -f "$MOUNT_CCP_CRED_FILE" ]; then
			echoyel "$MOUNT_CCP_CRED_FILE file removed."
			rm "$MOUNT_CCP_CRED_FILE"
		fi

		# Remove existing symlink if present
		if [ -L "$CC_CRED_DEFAULT" ]; then
			rm "$CC_CRED_DEFAULT"
			echoyel "✓ ~/.claude/.credentials.json -> $MOUNT_CCP_CRED_FILE symlink removed..."
		fi

		echoyel "✓ ~/.claude/.credentials.json persistence removed..."

	else
		echored "⚠ Mount point $MOUNT_CCP_CONFDIR not found, skipping ~/.claude/.credentials.json persistence"
	fi

else
	echoyel "Skipping ~/.claude/.credentials.json persistence (disabled)"
fi

# Handle Claude Code temp directory persistense
if [ "$CCP_TMPDIR" = "true" ]; then

	# Create Claude Code temp directory
	mkdir -p "$MOUNT_CCP_TMPDIR"

	if [ -d "$MOUNT_CCP_TMPDIR" ]; then
		echo "Configuring $CC_TMPDIR_DEFAULT persistence..."

		# Set ownership of mount point
		maybe_sudo chown -R "$USER_NAME:$USER_NAME" "$MOUNT_CCP_TMPDIR"

		# Back up existing directory if it exists and is not a symlink
		if [ -d "$CC_TMPDIR_DEFAULT" ] && [ ! -L "$CC_TMPDIR_DEFAULT" ]; then
			echo "Backing up existing Claude Code temp directory to $CC_TMPDIR_DEFAULT.old"
			if [ -d "$CC_TMPDIR_DEFAULT.old" ]; then
				rm -rf "$CC_TMPDIR_DEFAULT.old"
			fi
			mv "$CC_TMPDIR_DEFAULT" "$CC_TMPDIR_DEFAULT.old"

			# If volume is empty, copy the backup contents to volume
			if [ -z "$(ls -A "$MOUNT_CCP_TMPDIR")" ]; then
				echo "Migrating existing Claude Code temp directory data to volume..."
				cp -r "$CC_TMPDIR_DEFAULT.old/." "$MOUNT_CCP_TMPDIR/"
			fi
		fi

		# Expose CLAUDE_CODE_TMPDIR to all login shells (and VS Code's env probe)
		echo "export CLAUDE_CODE_TMPDIR=\"$MOUNT_CCP_TMPDIR\"" |
			maybe_sudo tee /etc/profile.d/claude-code-persistent-tmpdir.sh >/dev/null

	else
		echored "⚠ Mount point $MOUNT_CCP_TMPDIR not found, skipping Claude Code temp directory persistence"
	fi
else
	echoyel "Skipping Claude Code temp directory persistence (disabled)"
fi

echogrn "Claude Code Persistent setup complete."
