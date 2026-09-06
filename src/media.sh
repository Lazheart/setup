#!/usr/bin/env bash
# media.sh - Instala wallpapers en /usr/share/backgrounds
# Solo copia archivos que no existan o sean diferentes (por checksum MD5)

set -euo pipefail

# ─── Configuración ────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WALLPAPERS_SRC="$(realpath "$SCRIPT_DIR/../wallpapers")"
WALLPAPERS_DST="/usr/share/backgrounds"
ASSETS_SRC="$(realpath "$SCRIPT_DIR/../assets")"
# Destino de los assets: respeta TARGET_HOME si lo exporta setup.sh
_ICONS_HOME="${TARGET_HOME:-$HOME}"
ASSETS_DST="$_ICONS_HOME/.local/share/icons"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ─── Funciones de log ─────────────────────────────────────────────────────────
log_info()  { echo -e "${CYAN}[INFO]${RESET}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${RESET}    $*"; }
log_skip()  { echo -e "${YELLOW}[SKIP]${RESET}  $*"; }
log_copy()  { echo -e "${GREEN}[COPY]${RESET}  $*"; }
log_error() { echo -e "${RED}[ERROR]${RESET} $*" >&2; }

# ─── Verificaciones previas ───────────────────────────────────────────────────
if [[ ! -d "$WALLPAPERS_SRC" ]]; then
    log_error "Directorio fuente no encontrado: $WALLPAPERS_SRC"
    exit 1
fi

if [[ ! -d "$WALLPAPERS_DST" ]]; then
    log_error "Directorio destino no existe: $WALLPAPERS_DST"
    log_error "Créalo con: sudo mkdir -p $WALLPAPERS_DST"
    exit 1
fi

if [[ ! -w "$WALLPAPERS_DST" ]]; then
    log_error "Sin permisos de escritura en: $WALLPAPERS_DST"
    log_error "Ejecuta el script con sudo."
    exit 1
fi

# ─── Instalar wallpapers ──────────────────────────────────────────────────────
echo -e "\n${BOLD}=== Instalando wallpapers ===${RESET}"
log_info "Origen : $WALLPAPERS_SRC"
log_info "Destino: $WALLPAPERS_DST"
echo ""

copied=0
skipped=0
errors=0

while IFS= read -r -d '' src_file; do
    filename="$(basename "$src_file")"
    dst_file="$WALLPAPERS_DST/$filename"

    if [[ -f "$dst_file" ]]; then
        # Comparar checksums MD5 — si son idénticos, omitir
        src_md5="$(md5sum "$src_file" | awk '{print $1}')"
        dst_md5="$(md5sum "$dst_file" | awk '{print $1}')"

        if [[ "$src_md5" == "$dst_md5" ]]; then
            log_skip "$filename  (ya existe, idéntico — omitiendo)"
            (( skipped++ )) || true
        else
            log_copy "$filename  (existe pero difiere → actualizando)"
            if cp "$src_file" "$dst_file"; then
                chmod 644 "$dst_file"
                log_ok "$filename actualizado"
                (( copied++ )) || true
            else
                log_error "No se pudo copiar: $filename"
                (( errors++ )) || true
            fi
        fi
    else
        log_copy "$filename  (nuevo)"
        if cp "$src_file" "$dst_file"; then
            chmod 644 "$dst_file"
            log_ok "$filename instalado"
            (( copied++ )) || true
        else
            log_error "No se pudo copiar: $filename"
            (( errors++ )) || true
        fi
    fi
done < <(find "$WALLPAPERS_SRC" -maxdepth 1 -type f \( \
    -iname "*.jpg"  -o \
    -iname "*.jpeg" -o \
    -iname "*.png"  -o \
    -iname "*.webp" \
\) -print0 | sort -z)

# ─── Resumen wallpapers ───────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}=== Resumen wallpapers ===${RESET}"
echo -e "${GREEN}  Copiados/actualizados : $copied${RESET}"
echo -e "${YELLOW}  Omitidos (ya existen) : $skipped${RESET}"
[[ $errors -gt 0 ]] && echo -e "${RED}  Errores               : $errors${RESET}"

# ─── Instalar assets ─────────────────────────────────────────────────────────
echo -e "\n${BOLD}=== Instalando assets ===${RESET}"
log_info "Origen : $ASSETS_SRC"
log_info "Destino: $ASSETS_DST"
echo ""

a_copied=0
a_skipped=0
a_errors=0

if [[ ! -d "$ASSETS_SRC" ]]; then
    log_error "Directorio de assets no encontrado: $ASSETS_SRC"
else
    # Crear directorio destino si no existe
    mkdir -p "$ASSETS_DST"

    while IFS= read -r -d '' src_file; do
        filename="$(basename "$src_file")"
        dst_file="$ASSETS_DST/$filename"

        if [[ -f "$dst_file" ]]; then
            src_md5="$(md5sum "$src_file" | awk '{print $1}')"
            dst_md5="$(md5sum "$dst_file" | awk '{print $1}')"

            if [[ "$src_md5" == "$dst_md5" ]]; then
                log_skip "$filename  (ya existe, idéntico — omitiendo)"
                (( a_skipped++ )) || true
            else
                log_copy "$filename  (existe pero difiere → actualizando)"
                if cp "$src_file" "$dst_file"; then
                    chmod 644 "$dst_file"
                    log_ok "$filename actualizado"
                    (( a_copied++ )) || true
                else
                    log_error "No se pudo copiar: $filename"
                    (( a_errors++ )) || true
                fi
            fi
        else
            log_copy "$filename  (nuevo)"
            if cp "$src_file" "$dst_file"; then
                chmod 644 "$dst_file"
                log_ok "$filename instalado"
                (( a_copied++ )) || true
            else
                log_error "No se pudo copiar: $filename"
                (( a_errors++ )) || true
            fi
        fi
    done < <(find "$ASSETS_SRC" -maxdepth 1 -type f \( \
        -iname "*.png"  -o \
        -iname "*.jpg"  -o \
        -iname "*.jpeg" -o \
        -iname "*.svg"  -o \
        -iname "*.webp" \
    \) -print0 | sort -z)

    # Ajustar propietario si se ejecuta como root
    if [[ -n "${TARGET_USER:-}" ]] && command -v chown &>/dev/null; then
        chown -R "${TARGET_USER}:${TARGET_USER}" "$ASSETS_DST" 2>/dev/null || true
    fi
fi

# ─── Resumen assets ───────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}=== Resumen assets ===${RESET}"
echo -e "${GREEN}  Copiados/actualizados : $a_copied${RESET}"
echo -e "${YELLOW}  Omitidos (ya existen) : $a_skipped${RESET}"
[[ $a_errors -gt 0 ]] && echo -e "${RED}  Errores               : $a_errors${RESET}"

# ─── Foto de perfil (.face) ───────────────────────────────────────────────────
echo -e "\n${BOLD}=== Configurando foto de perfil (.face) ===${RESET}"

FACE_SRC="$ASSETS_SRC/emiya.png"
FACE_DST="$_ICONS_HOME/.face"

face_errors=0

if [[ ! -f "$FACE_SRC" ]]; then
    log_error "Imagen de perfil no encontrada: $FACE_SRC"
    (( face_errors++ )) || true
else
    # ── ~/.face ──────────────────────────────────────────────────────────────
    _install_face() {
        local dst="$1"
        if [[ -f "$dst" ]]; then
            local src_md5 dst_md5
            src_md5="$(md5sum "$FACE_SRC" | awk '{print $1}')"
            dst_md5="$(md5sum "$dst"      | awk '{print $1}')"
            if [[ "$src_md5" == "$dst_md5" ]]; then
                log_skip "$(basename "$dst")  (ya existe, idéntico — omitiendo)"
                return 0
            else
                log_copy "$(basename "$dst")  (difiere → actualizando)"
            fi
        else
            log_copy "$(basename "$dst")  (nuevo)"
        fi
        if cp "$FACE_SRC" "$dst"; then
            chmod 644 "$dst"
            log_ok "$(basename "$dst") instalado en $(dirname "$dst")"
        else
            log_error "No se pudo copiar a: $dst"
            (( face_errors++ )) || true
        fi
    }

    _install_face "$FACE_DST"

    # ── AccountsService (GDM lo usa si está disponible) ──────────────────────
    AS_DIR="/var/lib/AccountsService/icons"
    if [[ -d "$AS_DIR" ]]; then
        _install_face "$AS_DIR/${TARGET_USER:-$(basename "$_ICONS_HOME")}"
    fi

    # Ajustar propietario del .face al usuario real
    if [[ -n "${TARGET_USER:-}" ]] && command -v chown &>/dev/null; then
        chown "${TARGET_USER}:${TARGET_USER}" "$FACE_DST" 2>/dev/null || true
    fi
fi

echo ""
[[ $face_errors -gt 0 ]] && echo -e "${RED}  Errores .face: $face_errors${RESET}"

[[ $errors -eq 0 && $a_errors -eq 0 && $face_errors -eq 0 ]] && exit 0 || exit 1
