#!/bin/bash
set -euo pipefail

echo "-------------------------------------------------------------------"
echo "                         SETUP.SH"
echo "-------------------------------------------------------------------"

# -------------------------------------------------------------------
# Usuario real que ejecutó el script
# -------------------------------------------------------------------

USER_NAME="${SUDO_USER:-$USER}"

# -------------------------------------------------------------------
# Verificar privilegios
# -------------------------------------------------------------------

echo "Verificando privilegios..."

if [ "$(id -u)" -ne 0 ]; then
    echo "El script necesita privilegios de sudo."
    echo "Ejecutando nuevamente con sudo..."
    echo

    exec sudo "$0" "$@"
fi

echo "Ejecutando con privilegios de root."
echo "Usuario: $USER_NAME"

# -------------------------------------------------------------------
# Verificar grupo sudo
# -------------------------------------------------------------------

echo "-------------------------------------------------------------------"
echo "Verificando grupo sudo..."
echo "-------------------------------------------------------------------"

if id -nG "$USER_NAME" | grep -qw "sudo"; then
    echo "El usuario $USER_NAME ya pertenece al grupo sudo."
else
    echo "El usuario $USER_NAME no pertenece al grupo sudo."
    echo "Añadiendo usuario al grupo sudo..."

    usermod -aG sudo "$USER_NAME"

    echo "Usuario añadido al grupo sudo."
    echo "El cambio tendrá efecto después de reiniciar/iniciar sesión."
fi

# -------------------------------------------------------------------
# Actualizar repositorios
# -------------------------------------------------------------------

echo "-------------------------------------------------------------------"
echo "Actualizando repositorios..."
echo "-------------------------------------------------------------------"

apt update

# -------------------------------------------------------------------
# Instalar curl
# -------------------------------------------------------------------

echo "-------------------------------------------------------------------"
echo "Verificando curl..."
echo "-------------------------------------------------------------------"

if command -v curl >/dev/null 2>&1; then
    echo "curl ya está instalado."
else
    echo "curl no está instalado."
    echo "Instalando curl..."

    apt install -y curl

    echo "curl instalado correctamente."
fi

# -------------------------------------------------------------------
# Instalar zsh
# -------------------------------------------------------------------

echo "-------------------------------------------------------------------"
echo "Verificando zsh..."
echo "-------------------------------------------------------------------"

if command -v zsh >/dev/null 2>&1; then
    echo "zsh ya está instalado."
else
    echo "zsh no está instalado."
    echo "Instalando zsh..."

    apt install -y zsh

    echo "zsh instalado correctamente."
fi

# -------------------------------------------------------------------
# Instalar Oh My Zsh
# -------------------------------------------------------------------

echo "-------------------------------------------------------------------"
echo "Verificando Oh My Zsh..."
echo "-------------------------------------------------------------------"

OH_MY_ZSH="/home/$USER_NAME/.oh-my-zsh"

if [ -d "$OH_MY_ZSH" ]; then
    echo "Oh My Zsh ya está instalado."
else
    echo "Oh My Zsh no está instalado."
    echo "Instalando Oh My Zsh..."

    sudo -u "$USER_NAME" \
        RUNZSH=no \
        CHSH=no \
        sh -c '$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)'

    echo "Oh My Zsh instalado correctamente."
fi

# -------------------------------------------------------------------
# Configurar zsh como shell predeterminado
# -------------------------------------------------------------------

echo "-------------------------------------------------------------------"
echo "Verificando shell predeterminado..."
echo "-------------------------------------------------------------------"

ZSH_PATH="$(command -v zsh)"
CURRENT_SHELL="$(getent passwd "$USER_NAME" | cut -d: -f7)"

if [ "$CURRENT_SHELL" = "$ZSH_PATH" ]; then
    echo "zsh ya es el shell predeterminado."
else
    echo "Shell actual: $CURRENT_SHELL"
    echo "Cambiando shell predeterminado a zsh..."

    chsh -s "$ZSH_PATH" "$USER_NAME"

    echo "zsh configurado como shell predeterminado."
fi

# -------------------------------------------------------------------
# Final
# -------------------------------------------------------------------

echo "-------------------------------------------------------------------"
echo "SETUP COMPLETADO"
echo "-------------------------------------------------------------------"

echo "Usuario: $USER_NAME"
echo "Shell:   $ZSH_PATH"
echo "Reinicia la máquina para aplicar los cambios."
echo
