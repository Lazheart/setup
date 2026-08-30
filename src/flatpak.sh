#!/bin/bash
set -euo pipefail

echo "==================================================================="
echo "            INSTALANDO Y CONFIGURANDO FLATPAK Y APPS"
echo "==================================================================="

# -------------------------------------------------------------------
# Instalación del backend de Flatpak
# -------------------------------------------------------------------
echo "Instalando Flatpak y dependencias..."
apt install -y flatpak flatpak-builder

echo "Añadiendo repositorio oficial de Flathub..."
flatpak remote-add --if-not-exists \
    flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo

# -------------------------------------------------------------------
# Instalación de Aplicaciones Flatpak
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
)

echo "-------------------------------------------------------------------"
echo "Instalando aplicaciones Flatpak..."
echo "-------------------------------------------------------------------"

for app in "${FLATPAK_APPS[@]}"; do
    echo "Instalando Flatpak: $app..."
    flatpak install -y flathub "$app" || echo "Aviso: No se pudo instalar $app o ya está instalado."
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