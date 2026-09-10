#!/bin/bash
set -euo pipefail

echo "==================================================================="
echo "            CONFIGURANDO FLATPAK Y APLICACIONES"
echo "==================================================================="

# -------------------------------------------------------------------
# Instalación y verificación del backend de Flatpak
# -------------------------------------------------------------------
echo "-------------------------------------------------------------------"
if dpkg -s flatpak &>/dev/null; then
    echo "Flatpak ya está instalado. Buscando actualizaciones del paquete..."
    apt install --only-upgrade -y flatpak flatpak-builder 2>/dev/null || true
    echo "Backend de Flatpak verificado correctamente."
else
    echo "Instalando Flatpak y dependencias..."
    apt install -y flatpak flatpak-builder
fi

echo "Verificando repositorio oficial de Flathub..."
flatpak remote-add --if-not-exists \
    flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo

# -------------------------------------------------------------------
# Instalación y Actualización de Aplicaciones Flatpak
# -------------------------------------------------------------------
FLATPAK_APPS=(
    "io.github.realmazharhussain.GdmSettings"
    "io.github.kolunmi.Bazaar"
    "com.discordapp.Discord"
    "org.armagetronad.ArmagetronAdvanced"
    "org.vinegarhq.Sober"
    "com.stremio.Stremio"
    "org.onlyoffice.desktopeditors"
    "com.obsproject.Studio"
    "org.mozilla.thunderbird"
    "com.anydesk.Anydesk"
)

echo "-------------------------------------------------------------------"
echo "Verificando aplicaciones Flatpak..."
echo "-------------------------------------------------------------------"

for app in "${FLATPAK_APPS[@]}"; do
    if flatpak info "$app" &>/dev/null; then
        echo "Flatpak '$app' ya está instalado. Buscando actualizaciones..."
        flatpak update -y "$app" 2>/dev/null || echo "Aviso: No se pudo actualizar $app o ya está en la última versión."
        echo "Flatpak '$app' al día."
    else
        echo "Instalando Flatpak: $app..."
        flatpak install -y flathub "$app" || echo "Aviso: No se pudo instalar $app."
    fi
done

# -------------------------------------------------------------------
# Configuración y Overrides de Flatpak (Temas e Iconos)
# -------------------------------------------------------------------
echo "-------------------------------------------------------------------"
echo "Aplicando configuraciones y permisos globales de Flatpak..."
echo "-------------------------------------------------------------------"

flatpak override --system \
    --filesystem=xdg-config/gtk-3.0:ro \
    --filesystem=xdg-config/gtk-4.0:ro \
    --filesystem=~/.themes:ro \
    --filesystem=~/.icons:ro \
    --filesystem=~/.local/share/themes:ro \
    --filesystem=~/.local/share/icons:ro \
    --filesystem=/usr/share/themes:ro \
    --filesystem=/usr/share/icons:ro 2>/dev/null || true

echo "==================================================================="
echo "          FLATPAK Y APLICACIONES CONFIGURADOS CON ÉXITO"
echo "==================================================================="