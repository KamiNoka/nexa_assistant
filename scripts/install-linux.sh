#!/usr/bin/env bash
#
# Установка Nexa из AppImage в систему пользователя (без root):
#  - копирует AppImage в ~/.local/lib/nexa/
#  - добавляет ярлык в меню приложений (поиск по «nexa» — регистронезависимо)
#  - создаёт команды терминала: nexa, Nexa, NEXA
#
# Использование:
#   ./scripts/install-linux.sh [путь-к-AppImage]
# Если путь не указан — берётся release/Nexa-*.AppImage или AppImage рядом со скриптом.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

APP_NAME="Nexa"
WM_CLASS="Nexa"                    # res_class окна Electron (при executableName=nexa → WM_CLASS "nexa"/"Nexa")

LIB_DIR="$HOME/.local/lib/nexa"
BIN_DIR="$HOME/.local/bin"
ICON_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"
DESKTOP_DIR="$HOME/.local/share/applications"
APP_TARGET="$LIB_DIR/Nexa.AppImage"

info() { printf '\033[1;36m[install]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[install] ВНИМАНИЕ:\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[install] ОШИБКА:\033[0m %s\n' "$*" >&2; exit 1; }

# 1. Находим AppImage
find_appimage() {
	if [ "${1:-}" != "" ]; then
		[ -f "$1" ] || die "файл не найден: $1"
		printf '%s' "$1"; return
	fi
	for cand in \
		"$PROJECT_DIR"/release/Nexa-*.AppImage \
		"$PROJECT_DIR"/release/*.AppImage \
		"$SCRIPT_DIR"/Nexa-*.AppImage \
		"$SCRIPT_DIR"/*.AppImage; do
		[ -f "$cand" ] && { printf '%s' "$cand"; return; }
	done
	die "AppImage не найден. Соберите его: npm run dist:linux — или укажите путь аргументом."
}

APPIMAGE="$(find_appimage "${1:-}")"
info "AppImage: $APPIMAGE"

# 2. Копируем AppImage
mkdir -p "$LIB_DIR" "$BIN_DIR" "$ICON_DIR" "$DESKTOP_DIR"
install -m 0755 "$APPIMAGE" "$APP_TARGET"
info "AppImage установлен: $APP_TARGET"

# 3. Иконка
if [ -f "$PROJECT_DIR/build/icon.png" ]; then
	install -m 0644 "$PROJECT_DIR/build/icon.png" "$ICON_DIR/nexa.png"
	info "Иконка установлена: $ICON_DIR/nexa.png"
else
	warn "build/icon.png не найден — ярлык будет без иконки."
fi

# 4. Команды терминала: nexa + симлинки Nexa, NEXA
#    (ФС Linux чувствительна к регистру, поэтому варианты — отдельными симлинками)
cat > "$BIN_DIR/nexa" <<EOF
#!/bin/sh
# Обёртка запуска Nexa (AppImage)
exec "$APP_TARGET" "\$@"
EOF
chmod 0755 "$BIN_DIR/nexa"
ln -sf nexa "$BIN_DIR/Nexa"
ln -sf nexa "$BIN_DIR/NEXA"
info "Команды созданы: nexa, Nexa, NEXA  (в $BIN_DIR)"

# 5. Desktop-файл (ярлык в меню/поиске приложений)
cat > "$DESKTOP_DIR/nexa.desktop" <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=$APP_NAME
GenericName=Voice Assistant
Comment=Локальный голосовой AI-ассистент
Exec=$APP_TARGET %U
Icon=nexa
Terminal=false
Categories=Utility;
Keywords=nexa;voice;assistant;ассистент;голос;
StartupWMClass=$WM_CLASS
StartupNotify=true
EOF
chmod 0644 "$DESKTOP_DIR/nexa.desktop"
info "Ярлык создан: $DESKTOP_DIR/nexa.desktop"

# 6. Обновляем кэши (если есть утилиты)
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true
command -v gtk-update-icon-cache >/dev/null 2>&1 && \
	gtk-update-icon-cache -q "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true

# 7. Проверяем PATH
case ":$PATH:" in
	*":$BIN_DIR:"*) : ;;
	*)
		warn "$BIN_DIR не в PATH — команда «nexa» из терминала пока не найдётся."
		warn "Добавьте в ~/.zshrc или ~/.bashrc строку:"
		printf '\n    export PATH="$HOME/.local/bin:$PATH"\n\n'
		;;
esac

info "Готово. Запуск: команда «nexa» в терминале или «Nexa» в поиске приложений."
