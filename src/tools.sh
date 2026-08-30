#!/bin/bash
set -euo pipefail

echo "==================================================================="
echo "              INSTALANDO HERRAMIENTAS DE DESARROLLO"
echo "==================================================================="

USER_NAME="${TARGET_USER:-${SUDO_USER:-$USER}}"
USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6)"

echo "Configurando herramientas para el usuario: $USER_NAME ($USER_HOME)"

# -------------------------------------------------------------------
# Terminal Ptyxis
# -------------------------------------------------------------------
echo "Instalando terminal Ptyxis..."
apt install -y ptyxis || echo "Aviso: No se pudo instalar ptyxis directamente desde repositorios estándar."

# -------------------------------------------------------------------
# Java 21 SDK
# -------------------------------------------------------------------
echo "Instalando OpenJDK 21..."
apt install -y openjdk-21-jdk

# -------------------------------------------------------------------
# Herramientas base de compilación y C++/Qt5
# -------------------------------------------------------------------
echo "Instalando utilidades de compilación, CMake y Qt5..."
apt install -y build-essential cmake pkg-config git gdb qtcreator qtbase5-dev qt5-qmake

# -------------------------------------------------------------------
# Docker y Docker Compose
# -------------------------------------------------------------------
echo "Instalando Docker y Docker Compose..."
apt install -y docker.io docker-compose

echo "Añadiendo a $USER_NAME al grupo docker..."
usermod -aG docker "$USER_NAME"

echo "Habilitando servicio Docker para el arranque del sistema..."
systemctl enable docker.service containerd.service || true
systemctl start docker.service || true

# -------------------------------------------------------------------
# PNPM (Instalación en contexto de usuario)
# -------------------------------------------------------------------
echo "Instalando y configurando PNPM para $USER_NAME..."

sudo -u "$USER_NAME" bash -c 'curl -fsSL https://get.pnpm.io/install.sh | env SHELL="$(command -v zsh || echo /bin/zsh)" sh -' || true

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
echo "Instalando Antigravity IDE..."

TMP_DIR="$(mktemp -d)"
pushd "$TMP_DIR" > /dev/null

wget -q --show-progress "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.5.5-4923483625488384/linux-x64/Antigravity%20IDE.tar.gz" -O antigravity.tar.gz
tar -xf antigravity.tar.gz

rm -rf /opt/antigravity
mv Antigravity\ IDE /opt/antigravity

# Crear ejecutable en el PATH
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

popd > /dev/null
rm -rf "$TMP_DIR"

echo "==================================================================="
echo "       HERRAMIENTAS DE DESARROLLO CONFIGURADAS CON ÉXITO"
echo "==================================================================="
