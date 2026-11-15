#!/usr/bin/env bash
# Make Washi one of your Shady rices by linking this checkout into
# ${XDG_DATA_HOME:-~/.local/share}/shady/rices/washi, where Shady and shady-shell
# look for rices. Then pick it with SHADY_RICE=washi (or programs.shady.rice).
#
#   ./install.sh              link it
#   ./install.sh --uninstall  remove the link again
set -euo pipefail

RICE="$(cd "$(dirname "$0")" && pwd)"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/shady/rices/washi"

if [[ "${1:-}" == "--uninstall" ]]; then
  if [[ -L "$DEST" && "$(readlink "$DEST")" == "$RICE" ]]; then
    rm "$DEST" && echo "removed $DEST"
  fi
  exit 0
fi
if [[ -e "$DEST" || -L "$DEST" ]] && [[ "$(readlink "$DEST" || true)" != "$RICE" ]]; then
  echo "Washi: $DEST already exists; move it aside first" >&2
  exit 1
fi
mkdir -p "$(dirname "$DEST")"
ln -sfn "$RICE" "$DEST"
echo "linked $DEST; start Shady with SHADY_RICE=washi"
