#!/usr/bin/env bash
# Washi clicked through in a headless Shady, with the machine's sources off
# (SHADY_SHELL_OFFLINE) at 1280x720: the window menu from a right click on
# a window's tab maximizes it, the day page opens from the clock and turns
# to the next month, the launcher opens from a published `washi.do`, the
# control page's Focus and Quiet keys write their state files, and Log out
# asks before it ends the session.
#
# Needs a built Shady and shady-shell (env.sh says where they are looked
# for); run inside `nix develop ../shady`.
set -euo pipefail
source "$(dirname "$0")/../env.sh"
unset SHADY_SOCKET WAYLAND_DISPLAY WAYLAND_SOCKET
PROBE="$SHADY_BUILD_DIR/headless-automation-probe"
[[ -x "$PROBE" ]] || { echo "washi-test: no $PROBE (build Shady's tests)" >&2; exit 2; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
runtime="$tmp/runtime"
status="$tmp/status"
log="$tmp/compositor.log"
mkdir -p "$runtime"
chmod 700 "$runtime"
: >"$status"

export XDG_RUNTIME_DIR="$runtime"
export SHADY_SHELL_OFFLINE=1 XDG_STATE_HOME="$XDG_RUNTIME_DIR/state"
export WLR_BACKENDS=headless WLR_HEADLESS_OUTPUTS=1 WLR_RENDERER=pixman
export SHADY_LUA_INIT="$RICE/tests/washi-init.lua"
export SHADY_SHELL_CONFIG="$RICE/shell.lua"
export SHADY_AUTOMATION_PROBE="$PROBE"
export SHADY_SHELL_WASHI_STATUS="$status"

set +e
timeout 20s "$SHADY_BUILD_DIR/shady" --safe -c "$RICE/tests/compositor.lua" >"$log" 2>&1
rc=$?
set -e
fail() { cat "$log" "$status" >&2; echo "washi-test: FAIL: $1" >&2; exit 1; }
(( rc == 124 )) && fail "compositor timed out"
(( rc != 0 )) && fail "compositor exited with status $rc"
grep -q 'shady-shell: lua: .*error\|shady-shell: view .*:' "$log" && fail "a view failed"
grep -q '^MAXIMIZE=PASS$' "$status" || fail "window menu"
grep -q 'shady-shell: day size ' "$log" || fail "the day page did not open"
grep -q 'shady-shell: launcher size ' "$log" || fail "the launcher did not open"
grep -q '^FOCUS=PASS$' "$status" || fail "focus"
grep -q '^DND=PASS$' "$status" || fail "quiet hours"
grep -q '^QUIT_REQUESTED=PASS$' "$status" || fail "log out"
echo "washi-test: PASS"
