#!/bin/bash
set -euo pipefail

echo "==================================================================="
echo "                   CONFIGURANDO UTILIDADES DIARIAS"
echo "==================================================================="

UTILS_PKGS=(
    btop
    fastfetch
    cava
    tree
    ripgrep
    fd-find
    jq
    unzip
)

for pkg in "${UTILS_PKGS[@]}"; do
    if dpkg -s "$pkg" &>/dev/null; then
        echo "Paquete '$pkg' ya está instalado. Buscando actualizaciones..."
        apt install --only-upgrade -y "$pkg" 2>/dev/null || echo "Aviso: No se pudo verificar actualización para $pkg."
        echo "Paquete '$pkg' verificado."
    else
        echo "Instalando paquete '$pkg'..."
        apt install -y "$pkg" || echo "Aviso: No se pudo instalar $pkg."
    fi
done

echo "==================================================================="
echo "            UTILIDADES DIARIAS CONFIGURADAS CON ÉXITO"
echo "==================================================================="