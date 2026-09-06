#!/bin/bash

# =============================================================================
# GNOME Visual Setup
# Instala tema de shell, iconos y cursores para GNOME
# Compatible con ejecución via sudo (usa TARGET_USER / TARGET_HOME exportados
# por setup.sh, o detecta el usuario real si se corre de forma independiente)
# =============================================================================

set -e

# Detectar usuario real y su home aunque se corra con sudo
if [ -z "${TARGET_USER:-}" ]; then
    TARGET_USER="${SUDO_USER:-$USER}"
fi
if [ -z "${TARGET_HOME:-}" ]; then
    TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
fi

TEMP_DIR="$(mktemp -d)"
chown "$TARGET_USER" "$TEMP_DIR"
trap 'rm -rf "$TEMP_DIR"' EXIT

echo "========================================"
echo "  GNOME Visual Setup"
echo "  Usuario: $TARGET_USER"
echo "========================================"

# ------------------------------------------------------------------------------
# 1. Marble Shell Theme
# Requiere: extensión User Themes, Python 3.10+
# https://github.com/imarkoff/Marble-shell-theme
# ------------------------------------------------------------------------------
install_marble_theme() {
    echo ""
    echo ">> Instalando Marble Shell Theme..."

    THEMES_DIR="$TARGET_HOME/.themes"
    if [ -d "$THEMES_DIR/Marble-red-dark" ]; then
        echo "-- Marble Shell Theme ya instalado, omitiendo."
        return
    fi

    cd "$TEMP_DIR"
    # Clonar como usuario real para evitar directorios de root
    sudo -u "$TARGET_USER" git clone --depth=1 https://github.com/imarkoff/Marble-shell-theme.git
    cd Marble-shell-theme

    # Instala todos los colores de acento (light + dark) con botones rellenos (más vibrantes)
    # Se ejecuta como usuario real para que el tema se instale en su ~/.themes
    sudo -u "$TARGET_USER" python3 install.py -a --filled --floating-panel

    echo "Marble Shell Theme instalado."
}

# ------------------------------------------------------------------------------
# 2. Kora Icon Theme
# https://github.com/bikass/kora
# kora        → carpetas azules
# kora-pgrey  → carpetas grises (depende de kora)
# ------------------------------------------------------------------------------
install_kora_icons() {
    echo ""
    echo ">> Instalando Kora Icons..."

    LOCAL_ICONS_DIR="$TARGET_HOME/.local/share/icons"
    SYSTEM_ICONS_DIR="/usr/share/icons"

    if [ -d "$LOCAL_ICONS_DIR/kora" ] || [ -d "$SYSTEM_ICONS_DIR/kora" ]; then
        echo "-- Kora Icons ya instalado, omitiendo."
        return
    fi

    mkdir -p "$LOCAL_ICONS_DIR"

    cd "$TEMP_DIR"
    sudo -u "$TARGET_USER" git clone --depth=1 https://github.com/bikass/kora.git

    # Copiar al directorio local del usuario real (como root, luego ceder propiedad)
    cp -r kora/kora        "$LOCAL_ICONS_DIR/"
    cp -r kora/kora-pgrey  "$LOCAL_ICONS_DIR/"
    chown -R "$TARGET_USER" "$LOCAL_ICONS_DIR/kora" "$LOCAL_ICONS_DIR/kora-pgrey"

    # Copiar al directorio del sistema (requiere root)
    cp -r kora/kora        "$SYSTEM_ICONS_DIR/"
    cp -r kora/kora-pgrey  "$SYSTEM_ICONS_DIR/"

    # Actualizar caché de iconos si gtk-update-icon-cache está disponible
    if command -v gtk-update-icon-cache &>/dev/null; then
        gtk-update-icon-cache -f -t "$LOCAL_ICONS_DIR/kora"        2>/dev/null || true
        gtk-update-icon-cache -f -t "$LOCAL_ICONS_DIR/kora-pgrey"  2>/dev/null || true
        gtk-update-icon-cache -f -t "$SYSTEM_ICONS_DIR/kora"       2>/dev/null || true
        gtk-update-icon-cache -f -t "$SYSTEM_ICONS_DIR/kora-pgrey" 2>/dev/null || true
    fi

    echo " Kora Icons instalado en $LOCAL_ICONS_DIR y $SYSTEM_ICONS_DIR"
}

# ------------------------------------------------------------------------------
# 3. DeepinV20 Dark Cursors
# https://github.com/yeyushengfan258/DeepinV20-dark-cursors
# install.sh copia el tema a ~/.local/share/icons/ del usuario
# ------------------------------------------------------------------------------
install_deepin_cursors() {
    echo ""
    echo ">> Instalando DeepinV20 Dark Cursors..."

    LOCAL_ICONS_DIR="$TARGET_HOME/.local/share/icons"
    if [ -d "$LOCAL_ICONS_DIR/DeepinV20-dark-cursors" ]; then
        echo "-- DeepinV20 Dark Cursors ya instalado, omitiendo."
        return
    fi

    cd "$TEMP_DIR"
    sudo -u "$TARGET_USER" git clone --depth=1 https://github.com/yeyushengfan258/DeepinV20-dark-cursors.git
    cd DeepinV20-dark-cursors

    chmod +x install.sh
    # Ejecutar como usuario real para que instale en su ~/.local/share/icons/
    sudo -u "$TARGET_USER" ./install.sh

    echo " DeepinV20 Dark Cursors instalado."
}

# ------------------------------------------------------------------------------
# Aplicar configuración via gsettings
# gsettings necesita correr como el usuario de sesión (no root)
# ------------------------------------------------------------------------------
apply_gnome_settings() {
    echo ""
    echo ">> Aplicando configuración de GNOME..."

    # Detectar DBUS_SESSION_BUS_ADDRESS del usuario real para que gsettings funcione
    DBUS_ADDR=$(sudo -u "$TARGET_USER" bash -c \
        'cat /proc/$(pgrep -u "$USER" gnome-session | head -1)/environ 2>/dev/null \
        | tr "\0" "\n" | grep DBUS_SESSION_BUS_ADDRESS | cut -d= -f2-' 2>/dev/null || true)

    run_gsettings() {
        if [ -n "$DBUS_ADDR" ]; then
            sudo -u "$TARGET_USER" env DBUS_SESSION_BUS_ADDRESS="$DBUS_ADDR" \
                gsettings "$@" 2>/dev/null || true
        else
            sudo -u "$TARGET_USER" gsettings "$@" 2>/dev/null || true
        fi
    }

    # Iconos
    run_gsettings set org.gnome.desktop.interface icon-theme 'kora'

    # Cursores
    run_gsettings set org.gnome.desktop.interface cursor-theme 'DeepinV20-dark-cursors'

    echo "Configuración aplicada."
    echo "  Nota: El tema de shell (Marble) debe seleccionarse manualmente desde"
    echo "  la extensión 'User Themes' porque requiere escoger color y modo."
}

# ------------------------------------------------------------------------------
# Ejecución principal
# ------------------------------------------------------------------------------
install_marble_theme
install_kora_icons
install_deepin_cursors
apply_gnome_settings

echo ""
echo "========================================"
echo "  ¡Instalación completada!"
echo "========================================"
echo ""
