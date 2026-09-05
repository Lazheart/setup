#!/bin/bash
set -euo pipefail

echo "==================================================================="
echo "              CONFIGURANDO EXTENSIONES GNOME"
echo "==================================================================="

USER_NAME="${TARGET_USER:-${SUDO_USER:-$USER}}"
USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6)"

echo "Configurando extensiones para el usuario: $USER_NAME ($USER_HOME)"

# -------------------------------------------------------------------
# Instalación de Dependencias del Sistema y pipx
# -------------------------------------------------------------------
echo "-------------------------------------------------------------------"
echo "Verificando dependencias base, paquete oficial de extensiones y herramientas..."
apt install -y pipx python3-pip python3-venv gnome-shell-extension-prefs gnome-shell-extensions gnome-shell-extension-manager 2>/dev/null || \
apt install -y pipx python3-pip python3-venv gnome-shell-extension-prefs || true

# -------------------------------------------------------------------
# Instalación y verificación de gnome-extensions-cli (gext)
# -------------------------------------------------------------------
echo "-------------------------------------------------------------------"
if command -v gext &>/dev/null || [ -f "$USER_HOME/.local/bin/gext" ] || [ -f /usr/local/bin/gext ]; then
    echo "gnome-extensions-cli (gext) ya está instalado. Buscando actualizaciones..."
    pipx upgrade --global gnome-extensions-cli 2>/dev/null || \
    sudo -u "$USER_NAME" pipx upgrade gnome-extensions-cli 2>/dev/null || true
else
    echo "Instalando gnome-extensions-cli (gext)..."
    pipx install --global gnome-extensions-cli --system-site-packages 2>/dev/null || \
    sudo -u "$USER_NAME" pipx install gnome-extensions-cli --system-site-packages 2>/dev/null || \
    sudo -u "$USER_NAME" pipx install gnome-extensions-cli 2>/dev/null || \
    pip install gnome-extensions-cli --break-system-packages 2>/dev/null || true
fi

# Asegurar symlinks globales si se instaló en el directorio local del usuario
if [ -f "$USER_HOME/.local/bin/gext" ] && [ ! -f /usr/local/bin/gext ]; then
    ln -sf "$USER_HOME/.local/bin/gext" /usr/local/bin/gext
    ln -sf "$USER_HOME/.local/bin/gnome-extensions-cli" /usr/local/bin/gnome-extensions-cli 2>/dev/null || true
fi

# Resolver binario de gext
GEXT_BIN=""
if command -v gext &>/dev/null; then
    GEXT_BIN="$(command -v gext)"
elif [ -x /usr/local/bin/gext ]; then
    GEXT_BIN="/usr/local/bin/gext"
elif [ -x "$USER_HOME/.local/bin/gext" ]; then
    GEXT_BIN="$USER_HOME/.local/bin/gext"
fi

# -------------------------------------------------------------------
# Lista de Extensiones de GNOME a instalar o actualizar
# -------------------------------------------------------------------
GNOME_EXTENSIONS=(
    "blur-my-shell@aunetx"
    "caffeine@patapon.info"
    "dash-to-dock@micxgx.gmail.com"
    "EasyScreenCast@iacopodeenosee.gmail.com"
    "gtk4-ding@smedius.gitlab.com"
    "lockscreen-extension@pratap.fastmail.fm"
    "primary_input_on_lockscreen@sagidayan.com"
    "status-icons@gnome-shell-extensions.gcampax.github.com"
)

# Asegurar directorios y permisos
mkdir -p "$USER_HOME/.local/share/gnome-shell/extensions"
chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.local" 2>/dev/null || true

echo "-------------------------------------------------------------------"
echo "Verificando y configurando extensiones de GNOME Shell..."
echo "-------------------------------------------------------------------"

for ext in "${GNOME_EXTENSIONS[@]}"; do
    EXT_IS_INSTALLED=false
    if [ -d "$USER_HOME/.local/share/gnome-shell/extensions/$ext" ] || \
       [ -d "/usr/share/gnome-shell/extensions/$ext" ]; then
        EXT_IS_INSTALLED=true
    fi

    if [ "$EXT_IS_INSTALLED" = true ]; then
        echo "Extensión '$ext' ya está instalada. Buscando actualizaciones..."
        if [ -n "$GEXT_BIN" ]; then
            sudo -u "$USER_NAME" "$GEXT_BIN" -F update -y --user "$ext" 2>/dev/null || true
            echo "Asegurando habilitación de: $ext..."
            sudo -u "$USER_NAME" "$GEXT_BIN" -F enable "$ext" 2>/dev/null || true
        fi
    else
        echo "Instalando extensión: $ext..."
        if [ -n "$GEXT_BIN" ]; then
            if sudo -u "$USER_NAME" "$GEXT_BIN" -F install "$ext"; then
                echo "Habilitando extensión: $ext..."
                sudo -u "$USER_NAME" "$GEXT_BIN" -F enable "$ext" 2>/dev/null || true
            else
                echo "Aviso: No se pudo instalar $ext."
            fi
        else
            echo "Aviso: gext no encontrado en PATH, no se pudo procesar $ext."
        fi
    fi
done

echo "==================================================================="
echo "        EXTENSIONES DE GNOME CONFIGURADAS CON ÉXITO"
echo "==================================================================="
