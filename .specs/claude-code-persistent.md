# Dev Container Feature: `claude-code-persistent`

## Description

**Claude Code Persistent** is an opinionated Dev Container Feature for installing Claude Code and persisting its data across container rebuilds using a named Docker volume. The volume is shared across Dev Containers by default.
### Persisting Data
The Feature gives the user the option to persist the following Claude Code data:
- authentication and configuration
- history
- internal temp files

For more information, see the [Persisting Claude Code Data](#persisting-claude-code-data) section.

## Properties used by this feature

The properties used by **Claude Code Persistent** are as follows:

| Property           | Type                  | Description                                                                                                                                                                                                                                                                                                                                                                           |
| ------------------ | --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`               | string                | **Required**: Identifier of the Feature. Must be unique in the context of the repository where the Feature exists and must match the name of the directory where the `devcontainer-feature.json` resides.                                                                                                                                                                             |
| `version`          | string                | **Required**: The semantic version of the Feature (e.g: `1.0.0`).                                                                                                                                                                                                                                                                                                                     |
| `name`             | string                | **Required**: A *“human-friendly”* display name for the Feature.                                                                                                                                                                                                                                                                                                                      |
| `description`      | string                | Description of the Feature.                                                                                                                                                                                                                                                                                                                                                           |
| `documentationURL` | string                | Url that points to the documentation of the Feature.                                                                                                                                                                                                                                                                                                                                  |
| `options`          | object                | A map of options that will be passed as environment variables to the execution of the script.                                                                                                                                                                                                                                                                                         |
| `containerEnv`     | object                | A set of name value pairs that sets or overrides environment variables.                                                                                                                                                                                                                                                                                                               |
| `customizations`   | object                | Product specific properties, each namespace under `customizations` is treated as a separate set of properties. For each of this sets the object is parsed, values are replaced while arrays are set as a union.                                                                                                                                                                       |
| `installsAfter`    | array                 | Array of ID’s of Features (omitting a version tag) that should execute before this one. Allows control for Feature authors on soft dependencies between different Features. [See _Installation Order_ for further information](https://containers.dev/implementors/features/#installation-order).                                                                                     |
| `mounts`           | object                | Cross-orchestrator way to add additional mounts to a container. Each value is an object that accepts the same values as the [Docker CLI `--mount` flag](https://docs.docker.com/engine/reference/commandline/run/#mount). The Pre-defined [devcontainerId](https://containers.dev/implementors/json_reference#variables-in-devcontainerjson) variable may be referenced in the value. |
| `onCreateCommand`  | string, array, object | The first of three (along with `updateContentCommand` and `postCreateCommand`) that finalizes container setup when a Dev Container is created. It and subsequent commands execute **inside** the container immediately after it has started for the first time.                                                                                                                       |
| `updateContentCommand` | string, array, object | The second of three (along with `onCreateCommand` and `postCreateCommand`) that finalizes container setup when a Dev Container is created. It executes **inside** the container after `onCreateCommand`.                                                                                                                                                                         |

### Property: `options`
The options used by **Claude Code Persistent** are as follows:

| Property               | Type              | Description                                                                                                         |
| ---------------------- | ----------------- | ------------------------------------------------------------------------------------------------------------------- |
| `optionId`             | string            | ID of the option that is converted into an all-caps environment variable with the selected value in it.             |
| `optionId.type`        | string            | Type of the option. Valid types are currently: `boolean`, `string`                                                  |
| `optionId.description` | string            | Description for the option.                                                                                         |
| `optionId.enum`        | array             | A strict list of allowed string values. Free-form values are **not** allowed. Omit when using `optionId.proposals`. |
| `optionId.default`     | string or boolean | Default value for the option.                                                                                       |

#### Feature: `options`
This Feature sets the following `options` property map in `devcontainer-feature.json`. Each option controls one kind of data:

| Option | Controls |
| ------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| `CCP_INSTALL` | Installs Claude Code using Anthropic's recommended native installer. Installs as Dev Container's `remoteUser` so it updates itself. |
| `CCP_CONFDIR` | Persists the `~/.claude` directory (history, projects, settings) |
| `CCP_JSON`    | Persists the `.claude.json` file (auth/conf) |
| `CCP_CRED` 	| Persist the `~/.claude/.credentials.json ` file (auth) |
| `CCP_TMPDIR`  | Persists the Claude Code temp directory used for internal temp files. (scratchpad) |

#### How to use

In `devcontainer.json`:

```json
"options": {
	"CCP_INSTALL": {
		"type": "boolean",
		"description": "Installs Claude Code using Anthropic's recommended native installer. Installs as Dev Container's `remoteUser` so it updates itself.",
		"default": true
	},
	"CCP_CONFDIR": {
		"type": "boolean",
		"description": "Persist `~/.claude` directory (history, projects, settings)",
		"default": true
	},
	"CCP_JSON": {
		"type": "boolean",
		"description": "Persist `.claude.json` file (auth/conf)",
		"default": true
	},
	"CCP_CRED": {
            "type": "boolean",
            "description": "Persist the `~/.claude/.credentials.json ` file (auth)",
            "default": false
        },
	"CCP_TMPDIR": {
		"type": "boolean",
		"description": "Persist the Claude Code temp directory used for internal temp files. (scratchpad)",
		"default": false
	}
}
```


### Property: `containerEnv`

Claude Code reads [environment variables](https://code.claude.com/docs/en/env-vars#variables) to decide where it stores its configuration and temporary files.

#### Environment Variables
The environment variables this Feature sets are as follows:

| Variable | Purpose |
| -------- | ------- |
| `CCP_CONFDIR`  | Overrides the Claude Code configuration directory (default: `~/.claude`). All settings, session history, and plugins are stored under this path. For credentials, see [where Claude Code stores credentials](https://code.claude.com/docs/en/authentication#credential-management). |
| `CCP_TMPDIR` | Overrides the Claude Code temp directory used for internal temp files. Claude Code appends `/claude-{uid}/` to this path on Linux. Default: `os.tmpdir()`. On Linux, [sandboxed](https://code.claude.com/docs/en/sandboxing) Bash subprocesses receive a short fallback `$TMPDIR` under the system default when the override is a long path, since some tools fail when temp paths get too long. Unsandboxed Bash commands inherit the shell’s `$TMPDIR` when it is set. Claude Code’s own temp files always use this override. |

#### How to use
This Feature sets both through the `containerEnv` property in `devcontainer-feature.json`, pointing them at the persistent directory:

```json
"containerEnv": {
	"CLAUDE_CONFIG_DIR": "/mnt/devcontainers/features/claude-code-persistent/conf",
	"CLAUDE_CODE_TMPDIR": "/mnt/devcontainers/features/claude-code-persistent/tmp"
}
```

### Property: `mounts`
#### Persisting Claude Code Data
Persisting Claude Code data requires the `mounts` property, a cross-orchestrator way to add additional mounts to a container.

The `mounts` property key/value pairs for this Feature are as follows:

| key    | value                               |
| ------ | ----------------------------------- |
| source | `claude-code-persistent`            |
| target | `/mnt/devcontainers/features/claude-code-persistent` |
| type   | volume                              |
#### How to use
This Feature sets data persistence through the `mounts` property in `devcontainer-feature.json`:

```json
"mounts": [
	{
	    "source": "claude-code-persistent",
        "target": "/mnt/devcontainers/features/claude-code-persistent",
        "type": "volume"
	}
]
```

#### Isolated Data
Because the volume is a named Docker volume, every Dev Container that uses this Feature mounts the same volume, so data is shared across Dev Containers by default. A Dev Container that needs its own isolated data can override the mount source in its own `devcontainer.json`, for example by using `${devcontainerId}`:

```json
"mounts": [
	{
		"source": "claude-code-persistent-${devcontainerId}",
		"target": "/mnt/devcontainers/features/claude-code-persistent",
		"type": "volume"
	}
]
```

#### Folder Structure
##### Docker volume
The **Claude Code Persistent** Docker volume is organized into the following folder structure:

```text
🖴
├──📂 conf	// Claude Code settings, session history, credentials, etc
│  └──...
└──📂 tmp	    // Claude Code internal temp files
   └──...
```
##### Dev Container
Setting the `mounts` values above in `devcontainer-feature.json` and having `updateContentCommand` create the `conf` and `tmp` folders should produce the following folder structure when the Docker volume is mounted in the Dev Container:

```
🖴
├──...
├──📂 usr
│  └──📂 share
│     └── 📂 claude-code-persistent 	// The mounted Docker volume
│         ├──📂 conf
│         │  └──...
│         └──📂 tmp
│            └──...
└──...
```

### Property: `customizations`
The Feature adds the `anthropic.claude-code` extension to VS Code, so the Claude Code extension is available in the container without manual setup.

### Property: `installsAfter`
Claude Code Persistent runs after `common-utils`, which provides the tools the installer needs, and after other Features that install Claude Code. This lets it detect an existing installation and persist its data instead of installing a second copy.

### Property: `onCreateCommand`
The `onCreateCommand` is the first of three (along with `updateContentCommand` and `postCreateCommand`) that finalizes container setup when a Dev Container is created. It and subsequent commands execute **inside** the container immediately after it has started for the first time.

This Feature uses it for **installation**: it installs Claude Code as the remote user, unless it is already present.

### Property: `updateContentCommand`
The `updateContentCommand` runs after `onCreateCommand`, inside the container.

This Feature uses it for **persistence setup**: it creates the `conf` and `tmp` folders in the volume, backs up any existing Claude Code data, and links the user's Claude Code paths to the volume.

> [!NOTE]
> The `waitFor` enum specifies the command any tool should wait for before connecting to the Dev Container. **Defaults to `updateContentCommand`**. This allows one to use `onCreateCommand` or `updateContentCommand` for steps that must happen before `devcontainer.json` supporting tools connect while still using `postCreateCommand` for steps that can happen behind the scenes afterwards.


## Feature files

A Feature is a self-contained unit in a folder. It must contain at least a `devcontainer-feature.json` file and an `install.sh` entrypoint script. You may add other files, which are packaged alongside the required ones. This Feature uses the following files:

```text
📂 claude-code-persistent
├──📄 devcontainer-feature.json
├──📄 install.sh
├──📄 onCreate.sh
├──📄 updateContent.sh
└──📄 util.sh
```

- `devcontainer-feature.json`: Feature metadata, options, mounts and lifecycle hooks.
- `install.sh`: runs at image build and stages the lifecycle scripts.
- `onCreate.sh`: installs Claude Code (`onCreateCommand`).
- `updateContent.sh`: sets up persistence (`updateContentCommand`).
- `util.sh`: shared helper functions.

### File: `devcontainer-feature.json`

```json
{
    "id": "claude-code-persistent",
    "version": "0.1.1",
    "name": "Claude Code Persistent",
    "description": "Optinionated Claude Code installation: persist authentication, config, history and internal temp files across Dev Container rebuilds using a Docker volume.",
    "documentationURL": "[https://github.com/iamchriswick/devcontainers/tree/features](https://github.com/iamchriswick/devcontainers/tree/features/src/claude-code-persistent/README)",
    "options": {
        "CCP_INSTALL": {
            "type": "boolean",
            "description": "Installs Claude Code using Anthropic's recommended native installer. Installs as Dev Container's `remoteUser` so it updates itself.",
            "default": true
        },
        "CCP_CONFDIR": {
            "type": "boolean",
            "description": "Persist `~/.claude` directory (history, projects, settings)",
            "default": true
        },
        "CCP_JSON": {
            "type": "boolean",
            "description": "Persist `~/.claude.json` file (config)",
            "default": true
        },
        "CCP_CRED": {
            "type": "boolean",
            "description": "Persist `~/.claude/.credentials.json ` file (auth)",
            "default": false
        },
        "CCP_TMPDIR": {
            "type": "boolean",
            "description": "Persist the Claude Code temp directory used for internal temp files. (scratchpad)",
            "default": false
        }
    },
    "customizations": {
        "vscode": {
            "extensions": [
                "anthropic.claude-code"
            ]
        }
    },
    "installsAfter": [
		"ghcr.io/devcontainers/features/common-utils",        
		"ghcr.io/devcontainers/features/git",
		"ghcr.io/devcontainers/features/github-cli",
		"ghcr.io/anthropics/devcontainer-features/claude-code",
    ],
    "mounts": [
        {
            "source": "claude-code-persistent",
            "target": "/mnt/devcontainers/features/claude-code-persistent",
			"type": "volume"
		}
	],
	"onCreateCommand": "/usr/local/share/devcontainers/features/claude-code-persistent/hooks/onCreate.sh",
	"updateContentCommand": "/usr/local/share/devcontainers/features/claude-code-persistent/hooks/updateContent.sh"
}
```

### File: `install.sh`

```sh
#!/bin/sh
# Copyright (c) 2026 @iamchriswick
# Licensed under the MIT License. See https://github.com/iamchriswick/devcontainers/tree/features/src/claude-code-persistent/LICENSE for license information.

set -e
. ./util.sh

# Image build, as root: stage the hooks, which the lifecycle commands run as the
# remote user, and create the mount point. The staged directory is also the
# presence marker other Features check.

DCAT="feature"
DCAT_ID="claude-code-persistent"
LCH_DIR="/usr/local/share/devcontainers/${DCAT}s/$DCAT_ID/hooks"
DCAT_MDIR="/mnt/devcontainers/${DCAT}s/$DCAT_ID"
HERE=$(dirname "$0")

# defaultFeatures reaches every image, so an unsupported one must still build.
if [ ! -f /etc/debian_version ] || ! command -v bash >/dev/null 2>&1; then
	echoyel "Warning: $DCAT_ID needs a Debian-based image with bash; nothing installed" \
		>&2
	exit 0
fi

# A fresh named volume copies its mount point's ownership.
mkdir -p "$DCAT_MDIR"
chown "$_REMOTE_USER:$(id -gn "$_REMOTE_USER")" "$DCAT_MDIR"

# Copy init script
cp "$(dirname "$0")/util.sh" "$LCH_DIR/util.sh"
chmod +x "$LCH_DIR/util.sh"

# Copy onCreate script
cp "$(dirname "$0")/onCreate.sh" "$LCH_DIR/onCreate.sh"
chmod +x "$LCH_DIR/onCreate.sh"

# Copy updateContent script
cp "$(dirname "$0")/updateContent.sh" "$LCH_DIR/updateContent.sh"
chmod +x "$LCH_DIR/updateContent.sh"

# Dangles until onCreate installs Claude Code.
if ! { mkdir -p "$DCAT_MDIR" && cp "$HERE"/*.sh; }; then
	echo "Warning: $DCAT_ID could not stage its hooks; nothing installed!" >&2
	rm -rf "$DCAT_MDIR"
else
	rm "$LCH_DIR/util.sh"
	rm "$LCH_DIR/onCreate.sh"
	rm "$LCH_DIR/updateContent.sh"

	echogrn "$DCAT_ID $DCAT installed."
fi

exit 0

```

### File: `onCreate.sh`

```sh
#!/bin/sh
# Copyright (c) 2026 @iamchriswick
# Licensed under the MIT License. See https://github.com/iamchriswick/devcontainers/tree/features/src/claude-code-persistent/LICENSE for license information.

set -e
. ./util.sh

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

```
### File: `updateContent.sh`

```sh
#!/bin/sh
# Copyright (c) 2026 @iamchriswick
# Licensed under the MIT License. See https://github.com/iamchriswick/devcontainers/tree/features/src/claude-code-persistent/LICENSE for license information.

set -e
. ./util.sh

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
CC_TMPDIR_DEFAULT="${CLAUDE_CODE_TMPDIR:-'/tmp/claude-'$USER_ID}"

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
if [ "$CCP_CONFDIR" = "true" || "$CCP_JSON" = "true" || "$CCP_CRED" = "true" ]; then
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

	if [ -d "$CCP_CONFDIR" = "false" ]; then
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
		echogreen "✓ ~/.claude.json -> $MOUNT_CC_JSON_FILE"

	elif [ -d "$CCP_CONFDIR" = "true" ]; then
		echogreen "✓ ~/.claude.json -> $MOUNT_CCP_CONFDIR/.claude.json"
	else
		echored "⚠ Mount point $MOUNT_CCP_CONFDIR not found, skipping ~/.claude.json persistence"
	fi
else
	echoyel "Skipping ~/.claude.json persistence (disabled)"
fi

# Handle ~/.claude/.credentials.json file persistence
if [ "$CCP_CRED" = "true" ]; then

	if [ -d "$CCP_CONFDIR" = "false" ]; then
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
		echogreen "✓ ~/.claude/.credentials.json -> $MOUNT_CCP_CRED_FILE"

	elif [ -d "$CCP_CONFDIR" = "true" ]; then
		echogreen "✓ ~/.claude/.credentials.json -> $MOUNT_CCP_CONFDIR/.credentials.json"
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

```

### File: `util.sh`

```sh
#!/bin/sh
# Copyright (c) 2026 @iamchriswick
# Licensed under the MIT License. See https://github.com/iamchriswick/devcontainers/tree/features/src/claude-code-persistent/LICENSE for license information.

# This script builds on the original `util.sh` by Stuart Bell ([stu-bell/devcontainer-features](https://github.com/stu-bell/devcontainer-features)).

# v0.1.4

# check if a command exists
has_command() {
	command -v "$1" >/dev/null 2>&1
}

# check if user is root user
is_root_user() {
	[ "$(id -u)" -eq 0 ]
}

# parse major verion from a semantic version string
semver_major() {
	echo "${1#v}" | cut -d'.' -f1
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
echored() {
	echo -e "${RED}$*${NC}"
}
echogrn() {
	echo -e "${GREEN}$*${NC}"
}
echoyel() {
	echo -e "${YELLOW}$*${NC}"
}
echoblu() {
	echo -e "${BLUE}$*${NC}"
}

# If we're using Alpine, install bash before executing
ensure_bash_on_alpine() {
	. /etc/os-release
	if [ "${ID}" = "alpine" ]; then
		apk add --no-cache bash
	fi
}

# OS detection. Populates ID, ID_LIKE, VERSION
os_alpine() {
	. /etc/os-release
	[ "${ID}" = "alpine" ]
}

os_debian_like() {
	. /etc/os-release
	[ "${ID}" = "debian" ] || [ "${ID_LIKE}" = "debian" ]
}

# Run a command as the remote user for the devcontainer.
remote_user_run() {
	# Use _REMOTE_USER if available, otherwise use the devcontainer.json option USER_NAME
	command_to_run="$1"
	USER_OPTION="${REMOTE_USER_NAME:-automatic}"
	_REMOTE_USER="${_REMOTE_USER:-${USER_OPTION}}"
	if [ "${_REMOTE_USER}" = "auto" ] || [ "${_REMOTE_USER}" = "automatic" ]; then
		_REMOTE_USER="$(id -un 1000 2>/dev/null || echo "vscode")" # vscode fallback
	fi
	echo "Running as: $_REMOTE_USER, command: $command_to_run" >&2
	su - "${_REMOTE_USER}" -c "sh -lc '$command_to_run'"
}

# check if a command exists for remote user
remote_user_has_command() {
	remote_user_run "command -v \"$1\" > /dev/null 2>&1"
}
```

### File: `NOTES.md`

````markdown
## Notes

Add the following to your `devcontainer.json` if you'd like to limit the persistent volume only to this Dev Container:

```json
"mounts": [
	{
		"source": "claude-code-persistent-${devcontainerId}",
		"target": "/mnt/devcontainers/features/claude-code-persistent",
		"type": "volume"
	}
]
```

## Changelog

| Version | Notes           |
| ------- | --------------- |
| 0.1.0   | Initial version |
| 1.0.0   | Official release |

````

## Limitations and security

- **Shared credentials:** authentication data lives in the volume, which all Dev Containers on the same Docker host share by default. Anyone with access to that host can read it.
- **Supported images:** the Feature targets Debian-based images with bash. On other images, the Feature does nothing and the build continues.
- **Resetting:** removing the `claude-code-persistent` Docker volume deletes all persisted data, including authentication.
- **Isolation:** to keep one Dev Container's data separate, override the mount source with a name that includes `${devcontainerId}`.

---

## Usage in `devcontainer.json`

The `devcontainer.json` file contains any needed metadata and settings required to configure a **Development Container** for a given well-defined tool and runtime stack. It can be used by [tools and services that support the Dev Container spec](https://containers.dev/supporting) to create a **development environment** that contains one or more **Development Containers**.
### How to use
To use the [[#Description|Claude Code Persistent]] Dev Container Feature, add the following to `devcontainer.json`:

```json
{
	"features": {
		"ghcr.io/iamchriswick/devcontainers/features/claude-code-persistent": {
			"CCP_INSTALL": true,
			"CCP_CONFDIR": true,
			"CCP_JSON": true,
			"CCP_CRED": false,
			"CCP_TMPDIR": false,
		}
	}
}
```


## Documentation

Documentation for this Feature is generated automatically by the [`devcontainers/action@v1` GitHub Action](https://github.com/marketplace/actions/dev-container-publish). The workflow uses the details in `devcontainer-feature.json` and `NOTES.md` to generate `README.md`. For example:

````markdown
# Claude Code Persistent (claude-code-persistent)

Optinionated Claude Code installation: persist authentication, config, history and internal temp files across Dev Container rebuilds using a Docker volume.

## Example Usage

```json
"features": {
	"ghcr.io/iamchriswick/devcontainers/features/claude-code-persistent": {
		"CCP_INSTALL": true,
		"CCP_CONFDIR": true,
		"CCP_JSON": true,
		"CCP_CRED": false,
		"CCP_TMPDIR": false,
	}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| CCP_INSTALL | Installs Claude Code using Anthropic's recommended native installer. Installs as Dev Container's `remoteUser` so it updates itself. | boolean | true |
| CCP_CONFDIR | Persist the `~/.claude` directory (history, projects, settings) | boolean | true |
| CCP_JSON | Persist the `.claude.json` file (config) | boolean | true |
| CCP_CRED | Persist the `~/.claude/.credentials.json ` file (auth) | boolean | false |
| CCP_TMPDIR | Persist the Claude Code temp directory used for internal temp files. (scratchpad) | boolean | false |

## Notes

Add the following to your `devcontainer.json` if you'd like to limit the persistent volume only to this Dev Container:

```json
"mounts": [
	{
		"source": "claude-code-persistent-${devcontainerId}",
		"target": "/mnt/devcontainers/features/claude-code-persistent",
		"type": "volume"
	}
]
```

## Changelog

| Version | Notes           |
| ------- | --------------- |
| 0.1.0   | Initial version |
| 1.0.0   | Official release |

---

Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/iamchriswick/devcontainers/tree/features/src/claude-code-persistent/src/devcontainer-feature.json).  Add additional notes to a `NOTES.md`.

````