#!/usr/bin/env bash
# ============================================================================
# Установщик x5-proxy (github.com/dxa4/dra-proxy) — один файл, который
# делает всё сам: качает актуальный бинарник, ставит права на исполнение,
# снимает карантин macOS (чтобы Gatekeeper не блокировал запуск) и
# запускает прокси.
#
# Пользователю нужно скопировать и вставить в Терминал ОДНУ строку:
#
#   curl -fsSL https://raw.githubusercontent.com/dxa4/dra-proxy/main/install.sh | bash
#
# Больше ничего выбирать/скачивать/распаковывать вручную не нужно.
# ============================================================================
set -euo pipefail

REPO="dxa4/dra-proxy"
INSTALL_DIR="$HOME/.x5-proxy"
BIN_NAME="x5-proxy"

echo "Устанавливаю x5-proxy..."

OS_RAW="$(uname -s)"
ARCH_RAW="$(uname -m)"

if [ "$OS_RAW" != "Darwin" ]; then
  echo "Этот установщик — только для macOS."
  echo "На Windows: скачайте x5-proxy-win.exe со страницы"
  echo "  https://github.com/${REPO}/releases/latest"
  echo "и запустите двойным кликом (при предупреждении SmartScreen — «Подробнее» → «Выполнить в любом случае»)."
  exit 1
fi

if [ "$ARCH_RAW" != "arm64" ]; then
  echo "Внимание: сейчас доступна сборка только под Apple Silicon (M1/M2/M3/M4)."
  echo "На Intel Mac эта версия может не запуститься — напишите Жене."
fi

ASSET_NAME="x5-proxy-macos-arm64"
DOWNLOAD_URL="https://github.com/${REPO}/releases/latest/download/${ASSET_NAME}"

echo "Скачиваю: ${ASSET_NAME} (последний релиз)"

mkdir -p "$INSTALL_DIR"
TARGET="$INSTALL_DIR/$BIN_NAME"

if ! curl -fsSL "$DOWNLOAD_URL" -o "$TARGET"; then
  echo "Не удалось скачать файл."
  echo "Проверьте интернет/VPN и повторите, либо напишите Жене."
  exit 1
fi

chmod +x "$TARGET"
xattr -d com.apple.quarantine "$TARGET" 2>/dev/null || true

echo "Готово: $TARGET"
echo "Запускаю прокси..."
echo

exec "$TARGET" "$@"
