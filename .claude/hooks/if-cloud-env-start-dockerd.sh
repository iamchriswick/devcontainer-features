#!/bin/bash
[ "$CLAUDE_CODE_REMOTE" = "true" ] || exit 0
command -v dockerd >/dev/null 2>&1 || exit 0
docker info >/dev/null 2>&1 && exit 0

setsid nohup dockerd >/tmp/dockerd.log 2>&1 </dev/null &

# Wait up to 20s for the daemon so docker commands work when Claude starts
for _ in $(seq 1 20); do
  docker info >/dev/null 2>&1 && exit 0
  sleep 1
done
echo "dockerd not ready after 20s; see /tmp/dockerd.log" >&2
exit 0