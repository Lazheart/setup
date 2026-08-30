#!/bin/bash
set -e

echo "Instalando Flatpak..."
sudo apt install -y flatpak
sudo apt install -y flatpak-builder
echo "Agregando repositorio oficial de Flathub..."
sudo flatpak remote-add --if-not-exists \
    flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo
echo "Repositorio Oficial de Flathub Agregado"

echo "--------------- Instalando Apps Flatpak -----------------------"

flatpak install -y flathub io.github.realmazharhussain.GdmSettings
echo "GDM Settings Instalado"

flatpak install -y flathub io.github.kolunmi.Bazaar
echo "Bazaar Instalado"

flatpak install -y flathub com.discordapp.Discord
echo "Discord Instalado"

flatpak install -y flathub org.armagetronad.ArmagetronAdvanced
echo "Tron Instalado"

flatpak install -y flathub org.vinegarhq.Sober
echo "Sober Instalado"

flatpak install -y flathub com.stremio.Stremio
echo "Stremio Instalado"

flatpak install -y flathub org.onlyoffice.desktopeditors
echo "OnlyOffice Instalado"

flatpak install -y flathub com.obsproject.Studio
echo "OBS Instalado"

echo "-------------------------------------------------------------------"