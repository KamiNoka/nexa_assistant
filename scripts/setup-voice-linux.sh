#!/usr/bin/env bash
#
# Настройка голоса (Whisper) для Linux — автономно, без Node.
# Создаёт venv в стабильном пользовательском месте (вне read-only AppImage):
#   ${XDG_DATA_HOME:-~/.local/share}/nexa/whisper/.venv
# и ставит faster-whisper. Это место читает main.js (getLinuxPythonExecutable).
#
# Использование:
#   ./scripts/setup-voice-linux.sh [путь-к-requirements.txt]

set -euo pipefail

VENV_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nexa/whisper/.venv"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info() { printf '\033[1;36m[setup:voice]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[setup:voice] ВНИМАНИЕ:\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[setup:voice] ОШИБКА:\033[0m %s\n' "$*" >&2; exit 1; }

# Находим python3
PY=""
for c in python3 python; do
	if command -v "$c" >/dev/null 2>&1; then PY="$c"; break; fi
done
[ -n "$PY" ] || die "python3 не найден. Установите Python 3.9+."
info "Интерпретатор: $PY ($("$PY" --version 2>&1))"

# Определяем requirements
REQ="${1:-}"
if [ -z "$REQ" ]; then
	for c in \
		"$SCRIPT_DIR/../resources/whisper/requirements.txt" \
		"$SCRIPT_DIR/resources/whisper/requirements.txt"; do
		[ -f "$c" ] && { REQ="$c"; break; }
	done
fi

VENV_PY="$VENV_DIR/bin/python"
if [ ! -x "$VENV_PY" ]; then
	info "Создаю venv: $VENV_DIR"
	mkdir -p "$(dirname "$VENV_DIR")"
	"$PY" -m venv "$VENV_DIR"
else
	info "venv уже существует: $VENV_DIR"
fi

info "Обновляю pip"
"$VENV_PY" -m pip install --upgrade pip >/dev/null

if [ -n "$REQ" ] && [ -f "$REQ" ]; then
	info "Ставлю зависимости из $REQ"
	"$VENV_PY" -m pip install -r "$REQ"
else
	warn "requirements.txt не найден — ставлю базовый набор."
	"$VENV_PY" -m pip install "faster-whisper>=0.10.0" "numpy>=1.24.0" "pydub>=0.25.1"
fi

# Проверка
if "$VENV_PY" -c "import faster_whisper" >/dev/null 2>&1; then
	info "faster-whisper установлен и импортируется — ок."
else
	die "faster-whisper не импортируется после установки."
fi

command -v ffmpeg >/dev/null 2>&1 && info "ffmpeg найден в PATH — ок." || \
	warn "ffmpeg не найден в PATH — голос не будет работать без него."

info "Готово. venv: $VENV_DIR"
