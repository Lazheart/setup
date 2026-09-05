#!/bin/bash
set -euo pipefail

echo "==================================================================="
echo "              INSTALANDO Y CONFIGURANDO EXTENSIONES GNOME"
echo "==================================================================="

USER_NAME="${TARGET_USER:-${SUDO_USER:-$USER}}"
USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6)"

echo "Configurando extensiones para el usuario: $USER_NAME ($USER_HOME)"

# -------------------------------------------------------------------
# Instalación de Dependencias del Sistema y pipx
# -------------------------------------------------------------------
echo "Instalando dependencias base y pipx..."
apt install -y pipx python3-pip python3-venv gnome-shell-extension-prefs 2>/dev/null || apt install -y pipx python3-pip python3-venv || true

# -------------------------------------------------------------------
# Instalación de gnome-extensions-cli (gext)
# -------------------------------------------------------------------
echo "Instalando gnome-extensions-cli (gext)..."

# Asegurar que gext esté instalado en el sistema o en el espacio del usuario
if ! command -v gext &>/dev/null && [ ! -f "$USER_HOME/.local/bin/gext" ] && [ ! -f /usr/local/bin/gext ]; then
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
# Lista de Extensiones de GNOME a instalar
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

echo "-------------------------------------------------------------------"
echo "Instalando y activando extensiones de GNOME Shell..."
echo "-------------------------------------------------------------------"

for ext in "${GNOME_EXTENSIONS[@]}"; do
    echo "Instalando extensión: $ext..."
    if [ -n "$GEXT_BIN" ]; then
        sudo -u "$USER_NAME" "$GEXT_BIN" install "$ext" 2>/dev/null || \
        sudo -u "$USER_NAME" "$GEXT_BIN" --backend file install "$ext" 2>/dev/null || \
        echo "Aviso: No se pudo instalar $ext (puede que ya esté instalada o requiera sesión gráfica activa)."

        echo "Habilitando extensión: $ext..."
        sudo -u "$USER_NAME" "$GEXT_BIN" enable "$ext" 2>/dev/null || \
        sudo -u "$USER_NAME" gnome-extensions enable "$ext" 2>/dev/null || true
    else
        echo "Aviso: gext no encontrado en PATH, intentando habilitar directamente..."
        sudo -u "$USER_NAME" gnome-extensions enable "$ext" 2>/dev/null || echo "Aviso: No se pudo procesar $ext."
    fi
done

echo "==================================================================="
echo "        EXTENSIONES DE GNOME CONFIGURADAS CON ÉXITO"
echo "==================================================================="
