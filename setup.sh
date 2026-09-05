#!/bin/bash
set -euo pipefail

# -------------------------------------------------------------------
# Directorio base del repositorio
# -------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==================================================================="
echo "                  LAZHEART SYSTEM SETUP & CONFIG                   "
echo "==================================================================="

# -------------------------------------------------------------------
# Usuario real que ejecutó el script
# -------------------------------------------------------------------
export TARGET_USER="${SUDO_USER:-$USER}"
export TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

# -------------------------------------------------------------------
# Verificar privilegios de Root / Sudo
# -------------------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
    echo "El script necesita privilegios de administrador."
    echo "Solicitando elevación con sudo..."
    echo
    exec sudo "$0" "$@"
fi

echo "Ejecutando con privilegios de root para el usuario: $TARGET_USER"
echo "Directorio Home del usuario: $TARGET_HOME"

# -------------------------------------------------------------------
# Verificar y asegurar grupo sudo
# -------------------------------------------------------------------
echo "-------------------------------------------------------------------"
echo "Verificando pertenencia al grupo sudo..."
echo "-------------------------------------------------------------------"

if id -nG "$TARGET_USER" | grep -qw "sudo"; then
    echo "El usuario $TARGET_USER ya pertenece al grupo sudo."
else
    echo "Añadiendo usuario $TARGET_USER al grupo sudo..."
    usermod -aG sudo "$TARGET_USER"
    echo "Usuario añadido al grupo sudo con éxito."
fi

# -------------------------------------------------------------------
# Actualizar repositorios del sistema
# -------------------------------------------------------------------
echo "-------------------------------------------------------------------"
echo "Actualizando listas de paquetes del sistema..."
echo "-------------------------------------------------------------------"

apt update

# -------------------------------------------------------------------
# Instalar paquetes base esenciales
# -------------------------------------------------------------------
echo "-------------------------------------------------------------------"
echo "Instalando paquetes base esenciales (curl, git, zsh, ca-certificates)..."
echo "-------------------------------------------------------------------"

apt install -y curl git zsh ca-certificates gnupg build-essential

# -------------------------------------------------------------------
# Instalar y Configurar Oh My Zsh para el usuario
# -------------------------------------------------------------------
echo "-------------------------------------------------------------------"
echo "Configurando Oh My Zsh..."
echo "-------------------------------------------------------------------"

OH_MY_ZSH="$TARGET_HOME/.oh-my-zsh"

if [ -d "$OH_MY_ZSH" ]; then
    echo "Oh My Zsh ya está instalado en $OH_MY_ZSH."
else
    echo "Instalando Oh My Zsh para el usuario $TARGET_USER..."
    sudo -u "$TARGET_USER" \
        RUNZSH=no \
        CHSH=no \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    echo "Oh My Zsh instalado correctamente."
fi

# -------------------------------------------------------------------
# Configurar zsh como shell predeterminado
# -------------------------------------------------------------------
echo "-------------------------------------------------------------------"
echo "Configurando Zsh como la shell predeterminada..."
echo "-------------------------------------------------------------------"

ZSH_PATH="$(command -v zsh)"
CURRENT_SHELL="$(getent passwd "$TARGET_USER" | cut -d: -f7)"

if [ "$CURRENT_SHELL" = "$ZSH_PATH" ]; then
    echo "Zsh ya es la shell predeterminada ($ZSH_PATH)."
else
    echo "Shell actual: $CURRENT_SHELL"
    echo "Cambiando shell predeterminado a $ZSH_PATH para $TARGET_USER..."
    chsh -s "$ZSH_PATH" "$TARGET_USER"
    echo "Zsh configurado como shell predeterminado con éxito."
fi

# -------------------------------------------------------------------
# Permisos de ejecución para los módulos en src/
# -------------------------------------------------------------------
chmod +x "$SCRIPT_DIR/src/"*.sh

# -------------------------------------------------------------------
# Ejecución de Módulos
# -------------------------------------------------------------------

echo "==================================================================="
echo "                   EJECUTANDO FLUJOS DE TRABAJO"
echo "==================================================================="

echo
echo ">>> [1/5] Ejecutando: src/software.sh"
"$SCRIPT_DIR/src/software.sh"

echo
echo ">>> [2/5] Ejecutando: src/tools.sh"
"$SCRIPT_DIR/src/tools.sh"

echo
echo ">>> [3/5] Ejecutando: src/utils.sh"
"$SCRIPT_DIR/src/utils.sh"

echo
echo ">>> [4/5] Ejecutando: src/flatpak.sh"
"$SCRIPT_DIR/src/flatpak.sh"

echo
echo ">>> [5/5] Ejecutando: src/gnome_extension.sh"
"$SCRIPT_DIR/src/gnome_extension.sh"


# -------------------------------------------------------------------
# Finalización
# -------------------------------------------------------------------
echo
echo "==================================================================="
echo "                   SETUP COMPLETADO CON ÉXITO                      "
echo "==================================================================="
echo "Usuario configurado: $TARGET_USER"
echo "Shell del sistema:   $ZSH_PATH"
echo "Grupos añadidos:     sudo, docker"
echo "-------------------------------------------------------------------"
echo "NOTA: Cierra la sesión o reinicia el equipo para que los grupos y"
echo "la nueva shell por defecto tomen efecto completo en tu entorno."
echo "==================================================================="
