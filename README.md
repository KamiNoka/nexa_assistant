# Nexa (Linux-форк)

Локальный голосовой AI-ассистент на **Electron + Vue**: чат, команды, управление
системой (громкость, запуск приложений, окна, мышь/клавиатура), браузер и
Telegram (MTProto). Распознавание речи — локально через **Whisper**
(`faster-whisper`).

Это форк [`whydarcy/nexa_assistant`](https://github.com/whydarcy/nexa_assistant)
с **портом под Linux**: оригинал поддерживал только Windows и macOS, здесь
добавлена полная поддержка Linux и сборка **AppImage / deb**.

---

## Поддержка платформ

| Платформа | Состояние | Реализация системных фун��ций |
|-----------|-----------|------------------------------|
| **Linux** | Порт (этот форк) | `pactl`/`wpctl`/`pamixer`/`amixer`, `wmctrl`, `xdotool`, `xdg-open`/`gtk-launch` |
| Windows   | Оригинал | PowerShell |
| macOS     | Оригинал | `osascript` |

Вся нативная логика — в одном файле `dist/main.js` (готовый скомпилированный JS;
исходников `src/`/`vue/` в репозитории нет, UI лежит собранным в `renderer/`).

---

## Требования (Linux)

| Компонент | Назначение |
|-----------|-----------|
| **Node.js 18+**, **npm 9+** | запуск и сборка |
| **Python 3.9+** + `venv` | голос (Whisper) |
| **ffmpeg** | конвертация записи с микрофона |
| **wmctrl**, **xdotool** | управление окнами и ввод (X11/XWayland) |
| PipeWire (`wpctl`) или PulseAudio (`pactl`) | громкость |

Установка зависимостей ОС:

```bash
# Arch
sudo pacman -S nodejs npm python python-pip ffmpeg wmctrl xdotool

# Debian/Ubuntu
sudo apt install -y nodejs npm python3 python3-venv python3-pip ffmpeg wmctrl xdotool

# Fedora
sudo dnf install -y nodejs npm python3 python3-pip ffmpeg wmctrl xdotool
```

---

## Запуск из исходников

```bash
git clone https://github.com/KamiNoka/nexa_assistant.git
cd nexa_assistant
npm install
npm start
```

> **Если `npm install` падает на загрузке Electron** (таймаут к GitHub) —
> используйте зеркало:
> ```bash
> ELECTRON_MIRROR="https://npmmirror.com/mirrors/electron/" npm install
> ```

### Голос (один раз)

```bash
npm run setup:voice
```

Создаёт `resources/whisper/.venv` и ставит `faster-whisper`. Модель скачивается
автоматически при первом распознавании.

---

## Сборка AppImage / deb

```bash
npm run dist:linux
```

Готовые `Nexa-<версия>.AppImage` и `Nexa-<версия>.deb` появятся в `release/`.

> При проблемах с сетью к GitHub добавьте зеркала:
> ```bash
> ELECTRON_MIRROR="https://npmmirror.com/mirrors/electron/" \
> ELECTRON_BUILDER_BINARIES_MIRROR="https://npmmirror.com/mirrors/electron-builder-binaries/" \
> npm run dist:linux
> ```

---

## Установка ярлыка (AppImage)

AppImage — самодостаточный файл, но сам по себе не добавляет ярлык. Скрипт-установщик
кладёт его в систему пользователя (без root), добавляет в меню приложений и создаёт
команды терминала:

```bash
npm run install:linux           # или: bash scripts/install-linux.sh [путь-к-AppImage]
```

Что делает:
- копирует AppImage в `~/.local/lib/nexa/`;
- добавляет ярлык **Nexa** в меню/поиск приложений (с иконкой);
- создаёт команды терминала: **`nexa`**, **`Nexa`**, **`NEXA`**;
- настраивает голос (Whisper) — создаёт venv в `~/.local/share/nexa/whisper/.venv`.
  Пропустить: `npm run install:linux -- --no-voice` (или `bash scripts/install-linux.sh --no-voice`).

> **Важно про голос и AppImage:** venv нельзя держать внутри read-only AppImage,
> поэтому он живёт в `~/.local/share/nexa/whisper/.venv` (стабильное место,
> которое читает и установленное приложение). Настроить/обновить отдельно:
> `bash scripts/setup-voice-linux.sh`. Переопределить интерпретатор можно
> переменной окружения `NEXA_PYTHON`.

> Поиск приложений в GNOME/KDE регистронезависим — «nexa», «Nexa», «NEXA» найдут
> ярлык одинаково. В терминале ФС чувствительна к регистру, поэтому три варианта
> написания заведены отдельными командами.

Если `~/.local/bin` не в `PATH`, скрипт подскажет, что добавить в `~/.zshrc`/`~/.bashrc`.

Удаление:

```bash
npm run uninstall:linux
```

Через **deb** ярлык и команда `nexa` создаются автоматически при установке пакета.

---

## Возможности

- 🎙️ **Голос** — push-to-talk, локальный Whisper, конвертация через ffmpeg.
- 💬 **Чат и команды** — текстовый интерфейс и выполнение сценариев из UI.
- 🖥️ **Система** — громкость, запуск приложений по имени, управление окнами, мышь/клавиатура.
- 🌐 **Браузер** — открытие URL, поиск, навигация.
- ✈️ **Telegram** — вход по коду, отправка/чтение сообщений (MTProto).
- 🔄 **Обновления** — через GitHub Releases (`electron-updater`).

---

## Структура проекта

```text
dist/
  main.js                  Electron main-процесс + все IPC-обработчики (вкл. Linux-ветки)
  preload.js               preload-мост
  telegram-user-bridge.cjs Telegram MTProto (GramJS)
renderer/                  Собранный Vue UI (index.html + assets)
resources/
  whisper/                 whisper_recognition.py, requirements.txt, .venv (после setup:voice)
  vosk/                    Резервные speech-файлы и модели
plugins/                   Плагины/расширения
services/jarvis/           Внешний access-сервис (опционально)
scripts/
  setup-voice.js           Настройка Whisper (на Linux вызывает setup-voice-linux.sh)
  setup-voice-linux.sh     venv в ~/.local/share/nexa/whisper/.venv + faster-whisper
  install-linux.sh         Установка ярлыка, команд и голоса из AppImage
  uninstall-linux.sh       Удаление
build/                     Иконки (icon.ico, icon.png) для electron-builder
```

---

## npm-скрипты

| Скрипт | Действие |
|--------|----------|
| `npm start` | Запуск Electron из исходников |
| `npm run setup:voice` | Настройка Whisper (venv + faster-whisper) |
| `npm run dist:linux` | Сборка AppImage и deb |
| `npm run install:linux` | Установка ярлыка/команд из AppImage |
| `npm run uninstall:linux` | Удаление установленного ярлыка |
| `npm run dist` / `dist:mac` | Сборка под Windows / macOS |

---

## Решение проблем

- **`npm install` или сборка виснет на загрузке Electron** — задайте `ELECTRON_MIRROR`
  и `ELECTRON_BUILDER_BINARIES_MIRROR` (см. выше).
- **AppImage не запускается из-за sandbox** — запустите с `--no-sandbox`
  (`~/.local/lib/nexa/Nexa.AppImage --no-sandbox`).
- **Голос не работает / `ModuleNotFoundError: faster_whisper`** — настройте venv:
  `bash scripts/setup-voice-linux.sh` (создаст `~/.local/share/nexa/whisper/.venv`).
  Проверьте также наличие `ffmpeg` в `PATH`.
- **«Функция недоступна» для окон/ввода** — установите `wmctrl` и `xdotool`.
- **Нет звука/громкости** — нужен `wpctl` (PipeWire) или `pactl` (PulseAudio) в `PATH`.

---

## Лицензия

См. [LICENSE.txt](LICENSE.txt).
