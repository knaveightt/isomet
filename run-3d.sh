#!/bin/sh
set -eu
cd "$(dirname "$0")"
if [ -n "${GODOT_BIN:-}" ]; then
 engine="$GODOT_BIN"
elif command -v godot4 >/dev/null 2>&1; then
 engine=godot4
elif command -v godot >/dev/null 2>&1; then
 engine=godot
elif [ -x /tmp/isomet-godot/Godot_v4.5.2-stable_linux.x86_64 ]; then
 engine=/tmp/isomet-godot/Godot_v4.5.2-stable_linux.x86_64
else
 echo 'Install Godot 4.5.2, then set GODOT_BIN to its executable or open godot/project.godot.' >&2
 exit 1
fi
exec "$engine" --path godot "$@"
