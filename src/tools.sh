#!/bin/bash
set -euo pipefail

echo "==================================================================="
echo "              CONFIGURANDO HERRAMIENTAS DE DESARROLLO"
echo "==================================================================="

USER_NAME="${TARGET_USER:-${SUDO_USER:-$USER}}"
USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6)"

echo "Configurando herramientas para el usuario: $USER_NAME ($USER_HOME)"

# -------------------------------------------------------------------
# Terminal Ptyxis
# -------------------------------------------------------------------
echo "-------------------------------------------------------------------"
if dpkg -s ptyxis &>/dev/null; then
    echo "Terminal Ptyxis ya está instalado. Buscando actualizaciones..."
    apt install --only-upgrade -y ptyxis 2>/dev/null || true
    echo "Terminal Ptyxis verificado correctamente."
else
    echo "Instalando terminal Ptyxis..."
    apt install -y ptyxis || echo "Aviso: No se pudo instalar ptyxis directamente desde repositorios estándar."
fi

# -------------------------------------------------------------------
# Java 21 SDK
# -------------------------------------------------------------------
echo "-------------------------------------------------------------------"
if dpkg -s openjdk-21-jdk &>/dev/null; then
    echo "OpenJDK 21 ya está instalado. Buscando actualizaciones..."
    apt install --only-upgrade -y openjdk-21-jdk 2>/dev/null || true
    echo "OpenJDK 21 verificado correctamente."
else
    echo "Instalando OpenJDK 21..."
    apt install -y openjdk-21-jdk
fi

# -------------------------------------------------------------------
# Herramientas base de compilación y C++/Qt5
# -------------------------------------------------------------------
echo "-------------------------------------------------------------------"
echo "Verificando/actualizando utilidades de compilación, CMake y Qt5..."
apt install -y build-essential cmake pkg-config git gdb qtcreator qtbase5-dev qt5-qmake

# -------------------------------------------------------------------
# Docker y Docker Compose
# -------------------------------------------------------------------
echo "-------------------------------------------------------------------"
if dpkg -s docker.io &>/dev/null; then
    echo "Docker ya está instalado. Buscando actualizaciones..."
    apt install --only-upgrade -y docker.io docker-compose 2>/dev/null || true
    echo "Docker verificado correctamente."
else
    echo "Instalando Docker y Docker Compose..."
    apt install -y docker.io docker-compose
fi

if id -nG "$USER_NAME" | grep -qw "docker"; then
    echo "El usuario $USER_NAME ya pertenece al grupo docker."
else
    echo "Añadiendo a $USER_NAME al grupo docker..."
    usermod -aG docker "$USER_NAME"
fi

echo "Asegurando servicio Docker para el arranque del sistema..."
systemctl enable docker.service containerd.service 2>/dev/null || true
systemctl start docker.service 2>/dev/null || true

# -------------------------------------------------------------------
# PNPM (Instalación y actualización en contexto de usuario)
# -------------------------------------------------------------------
echo "-------------------------------------------------------------------"
PNPM_BIN=""
if sudo -u "$USER_NAME" command -v pnpm &>/dev/null; then
    PNPM_BIN="$(sudo -u "$USER_NAME" command -v pnpm)"
elif [ -x "$USER_HOME/.local/share/pnpm/bin/pnpm" ]; then
    PNPM_BIN="$USER_HOME/.local/share/pnpm/bin/pnpm"
elif [ -x "$USER_HOME/.local/share/pnpm/pnpm" ]; then
    PNPM_BIN="$USER_HOME/.local/share/pnpm/pnpm"
fi

if [ -n "$PNPM_BIN" ]; then
    echo "PNPM ya está instalado. Buscando actualizaciones..."
    sudo -u "$USER_NAME" env PATH="$USER_HOME/.local/share/pnpm/bin:$USER_HOME/.local/share/pnpm:$PATH" "$PNPM_BIN" self-update 2>/dev/null || echo "PNPM ya se encuentra en su versión más reciente."
    echo "PNPM verificado correctamente."
else
    echo "Instalando y configurando PNPM para $USER_NAME..."
    sudo -u "$USER_NAME" bash -c 'curl -fsSL https://get.pnpm.io/install.sh | env SHELL="$(command -v zsh || echo /bin/zsh)" sh -' || true
fi

# Asegurar variables de entorno de PNPM en el .zshrc del usuario
ZSHRC_FILE="$USER_HOME/.zshrc"
if [ -f "$ZSHRC_FILE" ]; then
    if ! grep -q 'export PNPM_HOME=' "$ZSHRC_FILE"; then
        cat >> "$ZSHRC_FILE" <<'EOF'

# PNPM Configuration
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
EOF
        chown "$USER_NAME:$USER_NAME" "$ZSHRC_FILE"
    fi
fi

# -------------------------------------------------------------------
# Antigravity IDE
# -------------------------------------------------------------------
echo "-------------------------------------------------------------------"
ANTIGRAVITY_VERSION="2.5.5-4923483625488384"
ANTIGRAVITY_URL="https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/${ANTIGRAVITY_VERSION}/linux-x64/Antigravity%20IDE.tar.gz"

if [ -f /opt/antigravity/antigravity-ide ]; then
    CURRENT_INSTALLED_VER="$(cat /opt/antigravity/.version 2>/dev/null || echo "$ANTIGRAVITY_VERSION")"
    if [ "$CURRENT_INSTALLED_VER" = "$ANTIGRAVITY_VERSION" ]; then
        echo "Antigravity IDE ya está instalado en la versión $ANTIGRAVITY_VERSION. Omitiendo descarga."
        [ -f /opt/antigravity/.version ] || echo "$ANTIGRAVITY_VERSION" > /opt/antigravity/.version
    else
        echo "Actualizando Antigravity IDE de $CURRENT_INSTALLED_VER a $ANTIGRAVITY_VERSION..."
        TMP_DIR="$(mktemp -d)"
        pushd "$TMP_DIR" > /dev/null

        wget -q --show-progress "$ANTIGRAVITY_URL" -O antigravity.tar.gz
        tar -xf antigravity.tar.gz

        rm -rf /opt/antigravity
        mv Antigravity\ IDE /opt/antigravity
        echo "$ANTIGRAVITY_VERSION" > /opt/antigravity/.version

        popd > /dev/null
        rm -rf "$TMP_DIR"
        echo "Antigravity IDE actualizado con éxito."
    fi
else
    echo "Descargando e instalando Antigravity IDE ($ANTIGRAVITY_VERSION)..."
    TMP_DIR="$(mktemp -d)"
    pushd "$TMP_DIR" > /dev/null

    wget -q --show-progress "$ANTIGRAVITY_URL" -O antigravity.tar.gz
    tar -xf antigravity.tar.gz

    rm -rf /opt/antigravity
    mv Antigravity\ IDE /opt/antigravity
    echo "$ANTIGRAVITY_VERSION" > /opt/antigravity/.version

    popd > /dev/null
    rm -rf "$TMP_DIR"
    echo "Antigravity IDE instalado correctamente."
fi

# Crear ejecutable en el PATH si no existe o actualizarlo
cat > /usr/local/bin/antigravity <<'EOF'
#!/bin/bash
nohup /opt/antigravity/antigravity-ide "$@" >/dev/null 2>&1 &
disown
EOF
chmod +x /usr/local/bin/antigravity

# Crear acceso directo de escritorio para todos los usuarios
cat > /usr/share/applications/antigravity.desktop <<'EOF'
[Desktop Entry]
Name=Antigravity IDE
Exec=/usr/local/bin/antigravity %F
Icon=/opt/antigravity/resources/app/resources/linux/code.png
Terminal=false
Type=Application
Categories=Development;IDE;
EOF

chmod 644 /usr/share/applications/antigravity.desktop
update-desktop-database /usr/share/applications 2>/dev/null || true

echo "==================================================================="
echo "       HERRAMIENTAS DE DESARROLLO CONFIGURADAS CON ÉXITO"
echo "==================================================================="
