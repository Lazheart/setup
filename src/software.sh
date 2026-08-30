#!/bin/bash
set -euo pipefail

echo "==================================================================="
echo "                   INSTALANDO SOFTWARE GENERAL"
echo "==================================================================="

# Directorio temporal de descargas
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

pushd "$TMP_DIR" > /dev/null

# -------------------------------------------------------------------
# Google Chrome
# -------------------------------------------------------------------
echo "Descargando e instalando Google Chrome..."
wget -q --show-progress "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" -O google-chrome.deb
apt install -y ./google-chrome.deb
echo "Google Chrome instalado correctamente."

# -------------------------------------------------------------------
# Steam
# -------------------------------------------------------------------
echo "Descargando e instalando Steam..."
wget -q --show-progress "https://cdn.fastly.steamstatic.com/client/installer/steam.deb" -O steam.deb
apt install -y ./steam.deb
echo "Steam instalado correctamente."

# -------------------------------------------------------------------
# Heroic Games Launcher
# -------------------------------------------------------------------
echo "Descargando e instalando Heroic Games Launcher..."
wget -q --show-progress "https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/download/v2.22.1/Heroic-2.22.1-linux-amd64.deb" -O heroic.deb
apt install -y ./heroic.deb
echo "Heroic Games Launcher instalado correctamente."

# -------------------------------------------------------------------
# AnyDesk
# -------------------------------------------------------------------
echo "Descargando e instalando AnyDesk..."
wget -q --show-progress "https://download.anydesk.com/linux/anydesk_8.0.4-1_amd64.deb" -O anydesk.deb
apt install -y ./anydesk.deb
echo "AnyDesk instalado correctamente."

popd > /dev/null

echo "==================================================================="
echo "              SOFTWARE GENERAL INSTALADO CON ÉXITO"
echo "==================================================================="
