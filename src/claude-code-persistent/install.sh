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

mkdir -p "$LCH_DIR"

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
if ! { mkdir -p "$DCAT_MDIR" && cp "$HERE"/*.sh "$LCH_DIR"/; }; then
	echo "Warning: $DCAT_ID could not stage its hooks; nothing installed!" >&2
	rm -rf "$DCAT_MDIR"
else
	# Lifecycle hooks do not receive the Feature options: make the build-time
	# values the staged hook's defaults.
	sed -i \
		-e "s|^CCP_CONFDIR=.*|CCP_CONFDIR=\"\${CCP_CONFDIR:-${CCP_CONFDIR:-true}}\"|" \
		-e "s|^CCP_JSON=.*|CCP_JSON=\"\${CCP_JSON:-${CCP_JSON:-true}}\"|" \
		-e "s|^CCP_CRED=.*|CCP_CRED=\"\${CCP_CRED:-${CCP_CRED:-false}}\"|" \
		-e "s|^CCP_TMPDIR=.*|CCP_TMPDIR=\"\${CCP_TMPDIR:-${CCP_TMPDIR:-false}}\"|" \
		"$LCH_DIR/updateContent.sh"

	echogrn "$DCAT_ID $DCAT installed."
fi

exit 0
