#!/usr/bin/env node
/**
 * setup:voice — настройка распознавания речи (Whisper / faster-whisper).
 * Создаёт виртуальное окружение resources/whisper/.venv и ставит зависимости
 * из resources/whisper/requirements.txt.
 *
 * Поддержка: Linux и macOS (Python + venv). На Windows используется готовый
 * whisper_recognition.exe, поэтому скрипт лишь предупреждает и выходит.
 */
'use strict'

const { spawnSync } = require('child_process')
const fs = require('fs')
const path = require('path')

const WHISPER_DIR = path.join(__dirname, '..', 'resources', 'whisper')
const VENV_DIR = path.join(WHISPER_DIR, '.venv')
const REQUIREMENTS = path.join(WHISPER_DIR, 'requirements.txt')
const IS_WIN = process.platform === 'win32'
const IS_LINUX = process.platform === 'linux'

function log(msg) {
	console.log(`[setup:voice] ${msg}`)
}

function fail(msg) {
	console.error(`[setup:voice] ОШИБКА: ${msg}`)
	process.exit(1)
}

// Ищем рабочий python3 в системе
function findPython() {
	const candidates = IS_WIN ? ['python', 'py'] : ['python3', 'python']
	for (const c of candidates) {
		const r = spawnSync(c, ['--version'], { encoding: 'utf8' })
		if (r.status === 0) return c
	}
	return null
}

function run(cmd, args, opts = {}) {
	log(`$ ${cmd} ${args.join(' ')}`)
	const r = spawnSync(cmd, args, { stdio: 'inherit', ...opts })
	if (r.error) fail(`не удалось запустить ${cmd}: ${r.error.message}`)
	if (r.status !== 0) fail(`команда завершилась с кодом ${r.status}`)
}

function main() {
	if (IS_WIN) {
		log('Windows: используется готовый whisper_recognition.exe, venv не требуется.')
		log('Если нужен запуск из исходников — установите Python и faster-whisper вручную.')
		return
	}

	// На Linux venv ставим в стабильное пользовательское место (его читает и
	// установленный AppImage). Делегируем автономному bash-скрипту.
	if (IS_LINUX) {
		const sh = path.join(__dirname, 'setup-voice-linux.sh')
		run('bash', [sh, REQUIREMENTS])
		return
	}

	if (!fs.existsSync(REQUIREMENTS)) {
		fail(`не найден ${REQUIREMENTS}`)
	}

	const python = findPython()
	if (!python) {
		fail('python3 не найден. Установите Python 3.9+ и повторите.')
	}
	log(`Используем интерпретатор: ${python}`)

	// 1. Создаём venv (если ещё нет)
	const venvPython = path.join(VENV_DIR, 'bin', 'python')
	if (!fs.existsSync(venvPython)) {
		log(`Создаю виртуальное окружение: ${VENV_DIR}`)
		run(python, ['-m', 'venv', VENV_DIR])
	} else {
		log('Виртуальное окружение уже существует, пропускаю создание.')
	}

	// 2. Обновляем pip
	run(venvPython, ['-m', 'pip', 'install', '--upgrade', 'pip'])

	// 3. Ставим зависимости
	run(venvPython, ['-m', 'pip', 'install', '-r', REQUIREMENTS])

	log('Готово. Whisper настроен.')
	log('Проверка ffmpeg:')
	const ff = spawnSync('ffmpeg', ['-version'], { encoding: 'utf8' })
	if (ff.status === 0) {
		log('ffmpeg найден в PATH — ок.')
	} else {
		log('ВНИМАНИЕ: ffmpeg не найден в PATH. Установите его (напр. sudo pacman -S ffmpeg).')
	}
}

main()
