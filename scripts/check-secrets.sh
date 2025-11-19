#!/bin/bash
# Script para detectar secretos y credenciales en el código
# Busca patrones comunes de API keys, tokens, contraseñas, etc.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colores para output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

SECRETS_FOUND=0

echo "🔐 Iniciando búsqueda de secretos en el código..."
echo "=================================================="

# Archivos a excluir
EXCLUDE_FILES=(
    "node_modules"
    ".git"
    ".github"
    "dist"
    "build"
    ".next"
    "coverage"
    "*.log"
    "package-lock.json"
    "*.lock"
)

# Construir opciones de exclusión para grep
GREP_EXCLUDE=""
for file in "${EXCLUDE_FILES[@]}"; do
    GREP_EXCLUDE="$GREP_EXCLUDE --exclude-dir=$file"
done

# Patrones de secretos a buscar
declare -A PATTERNS=(
    ["AWS API Key"]="(AKIA[0-9A-Z]{16})"
    ["AWS Secret Access Key"]="aws_secret_access_key\s*=\s*['\"]?[A-Za-z0-9\/+=]{40}['\"]?"
    ["GitHub Token"]="gh[pousr]_[A-Za-z0-9_]{36,255}"
    ["Private SSH Key"]="BEGIN RSA PRIVATE KEY"
    ["API Key Pattern"]="api[_-]?key\s*[:=]\s*['\"]([^'\"]+)['\"]"
    ["Database URL"]="postgres:\/\/[^@]+@[^\/]+\/\|mongodb:\/\/.*"
    ["JWT Token"]="eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\."
    ["Slack Token"]="xox[baprs]-[0-9]{12}-[0-9]{12}-[0-9a-zA-Z]{24,32}"
    ["Generic Password"]="password\s*[:=]\s*['\"]([^'\"]{8,})['\"]"
    ["Grafana Token"]="glc_[A-Za-z0-9_-]+"
)

# Buscar cada patrón
for pattern_name in "${!PATTERNS[@]}"; do
    pattern="${PATTERNS[$pattern_name]}"
    
    echo ""
    echo "🔍 Buscando: $pattern_name"
    
    # Buscar recursivamente en el directorio del proyecto
    if grep -r $GREP_EXCLUDE -nE "$pattern" "$PROJECT_ROOT" 2>/dev/null | grep -v ".git/"; then
        echo -e "${RED}❌ Potencial secreto encontrado: $pattern_name${NC}"
        ((SECRETS_FOUND++))
    else
        echo -e "${GREEN}✓ No encontrado${NC}"
    fi
done

echo ""
echo "=================================================="

if [ $SECRETS_FOUND -gt 0 ]; then
    echo -e "${RED}⚠️  Se encontraron $SECRETS_FOUND potenciales secretos en el código${NC}"
    echo ""
    echo "Acciones recomendadas:"
    echo "1. Revisa los resultados anteriores cuidadosamente"
    echo "2. Si son falsos positivos, añade el archivo a .gitignore"
    echo "3. Si son secretos reales, rotálos inmediatamente"
    echo "4. Usa variables de entorno (.env) para credenciales"
    exit 1
else
    echo -e "${GREEN}✓ No se encontraron secretos obvios en el código${NC}"
    exit 0
fi
