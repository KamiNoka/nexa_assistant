#!/usr/bin/env bash
#
# Удаление Nexa, установленного через scripts/install-linux.sh.

set -euo pipefail

LIB_DIR="$HOME/.local/lib/nexa"
BIN_DIR="$HOME/.local/bin"
ICON_FILE="$HOME/.local/share/icons/hicolor/256x256/apps/nexa.png"
DESKTOP_FILE="$HOME/.local/share/applications/nexa.desktop"

info() { printf '\033[1;36m[uninstall]\033[0m %s\n' "$*"; }

rm -f "$BIN_DIR/nexa" "$BIN_DIR/Nexa" "$BIN_DIR/NEXA"
rm -f "$DESKTOP_FILE"
rm -f "$ICON_FILE"
rm -rf "$LIB_DIR"

command -v update-desktop-database >/dev/null 2>&1 && \
	update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
command -v gtk-update-icon-cache >/dev/null 2>&1 && \
	gtk-update-icon-cache -q "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true

info "Nexa удалён (AppImage, ярлык, команды nexa/Nexa/NEXA)."
