#!/bin/bash
set -euo pipefail

echo "==================================================================="
echo "                   CONFIGURANDO SOFTWARE GENERAL"
echo "==================================================================="

# Directorio temporal de descargas (solo si se necesita)
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# -------------------------------------------------------------------
# Google Chrome
# -------------------------------------------------------------------
echo "-------------------------------------------------------------------"
if dpkg -s google-chrome-stable &>/dev/null || command -v google-chrome &>/dev/null; then
    echo "Google Chrome ya está instalado. Buscando actualizaciones vía apt..."
    apt install --only-upgrade -y google-chrome-stable 2>/dev/null || true
    echo "Google Chrome verificado/actualizado correctamente."
else
    echo "Descargando e instalando Google Chrome..."
    wget -q --show-progress "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" -O "$TMP_DIR/google-chrome.deb"
    apt install -y "$TMP_DIR/google-chrome.deb"
    rm -f "$TMP_DIR/google-chrome.deb"
    echo "Google Chrome instalado correctamente."
fi

# -------------------------------------------------------------------
# Steam
# -------------------------------------------------------------------
echo "-------------------------------------------------------------------"
if dpkg -s steam-launcher &>/dev/null || dpkg -s steam &>/dev/null || command -v steam &>/dev/null; then
    echo "Steam ya está instalado. Buscando actualizaciones vía apt..."
    apt install --only-upgrade -y steam-launcher steam 2>/dev/null || true
    echo "Steam verificado/actualizado correctamente."
else
    echo "Descargando e instalando Steam..."
    wget -q --show-progress "https://cdn.fastly.steamstatic.com/client/installer/steam.deb" -O "$TMP_DIR/steam.deb"
    apt install -y "$TMP_DIR/steam.deb"
    rm -f "$TMP_DIR/steam.deb"
    echo "Steam instalado correctamente."
fi

# -------------------------------------------------------------------
# Heroic Games Launcher
# -------------------------------------------------------------------
echo "-------------------------------------------------------------------"
INSTALLED_HEROIC="$(dpkg-query -W -f='${Version}' heroic 2>/dev/null || true)"
LATEST_HEROIC_TAG="$(curl -s --connect-timeout 5 https://api.github.com/repos/Heroic-Games-Launcher/HeroicGamesLauncher/releases/latest | grep -Po '"tag_name": "\K[^"]*' || echo "")"
[ -z "$LATEST_HEROIC_TAG" ] && LATEST_HEROIC_TAG="v2.22.1"
TARGET_HEROIC_VER="${LATEST_HEROIC_TAG#v}"

if [ -n "$INSTALLED_HEROIC" ]; then
    if [ "$INSTALLED_HEROIC" = "$TARGET_HEROIC_VER" ]; then
        echo "Heroic Games Launcher ya está instalado en la versión más reciente (v$INSTALLED_HEROIC). Omitiendo descarga."
    else
        echo "Actualizando Heroic Games Launcher de v$INSTALLED_HEROIC a v$TARGET_HEROIC_VER..."
        wget -q --show-progress "https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/download/v${TARGET_HEROIC_VER}/Heroic-${TARGET_HEROIC_VER}-linux-amd64.deb" -O "$TMP_DIR/heroic.deb"
        apt install -y "$TMP_DIR/heroic.deb"
        rm -f "$TMP_DIR/heroic.deb"
        echo "Heroic Games Launcher actualizado a v$TARGET_HEROIC_VER con éxito."
    fi
else
    echo "Descargando e instalando Heroic Games Launcher (v$TARGET_HEROIC_VER)..."
    wget -q --show-progress "https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/download/v${TARGET_HEROIC_VER}/Heroic-${TARGET_HEROIC_VER}-linux-amd64.deb" -O "$TMP_DIR/heroic.deb"
    apt install -y "$TMP_DIR/heroic.deb"
    rm -f "$TMP_DIR/heroic.deb"
    echo "Heroic Games Launcher instalado correctamente."
fi

# -------------------------------------------------------------------
# AnyDesk
# -------------------------------------------------------------------
echo "-------------------------------------------------------------------"
if dpkg -s anydesk &>/dev/null || command -v anydesk &>/dev/null; then
    INSTALLED_ANYDESK="$(dpkg-query -W -f='${Version}' anydesk 2>/dev/null || echo "detectada")"
    echo "AnyDesk ya está instalado (versión $INSTALLED_ANYDESK). Buscando actualizaciones vía apt..."
    apt install --only-upgrade -y anydesk 2>/dev/null || echo "AnyDesk ya se encuentra en su versión actual."
    echo "AnyDesk verificado correctamente."
else
    echo "Descargando e instalando AnyDesk..."
    wget -q --show-progress "https://download.anydesk.com/linux/anydesk_8.0.4-1_amd64.deb" -O "$TMP_DIR/anydesk.deb"
    apt install -y "$TMP_DIR/anydesk.deb"
    rm -f "$TMP_DIR/anydesk.deb"
    echo "AnyDesk instalado correctamente."
fi

echo "==================================================================="
echo "              SOFTWARE GENERAL CONFIGURADO CON ÉXITO"
echo "==================================================================="
