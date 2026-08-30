#!/bin/bash
set -euo pipefail

echo "==================================================================="
echo "                   INSTALANDO UTILIDADES DIARIAS"
echo "==================================================================="

echo "Actualizando paquetes de utilidades..."

UTILS_PKGS=(
    btop
    fastfetch
    cava
    tree
    bat
    ripgrep
    fd-find
    jq
    unzip
    p7zip-full
    htop
)

for pkg in "${UTILS_PKGS[@]}"; do
    echo "Instalando $pkg..."
    apt install -y "$pkg" || echo "Aviso: No se pudo instalar $pkg o ya está en la versión más reciente."
done

echo "==================================================================="
echo "            UTILIDADES DIARIAS INSTALADAS CON ÉXITO"
echo "==================================================================="