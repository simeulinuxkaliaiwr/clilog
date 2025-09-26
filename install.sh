#!/usr/bin/env bash

set -euo pipefail

BIN_DIR="/usr/local/bin"
LIB_DIR="/usr/local/lib/clilog"

SOURCE_BIN="./bin/clilog"
SOURCE_LIB="./src/functions.sh"

TEMP_BIN_FILE="/tmp/clilog.tmp"

echo "Iniciando a instalação do Clilog no sistema (requer sudo)..."

echo "Criando diretórios de destino: $BIN_DIR e $LIB_DIR"
sudo mkdir -p "$BIN_DIR"
sudo mkdir -p "$LIB_DIR"

cp "$SOURCE_BIN" "$TEMP_BIN_FILE"

echo "Corrigindo o caminho do módulo functions.sh no executável..."

sudo sed -i "s|source \"\$HOME/Projects/clilog/src/functions.sh\"|source \"$LIB_DIR/functions.sh\"|" "$TEMP_BIN_FILE"
echo "Copiando arquivos..."
sudo cp "$SOURCE_LIB" "$LIB_DIR/"
sudo cp "$TEMP_BIN_FILE" "$BIN_DIR/clilog"
echo "Configurando permissões de execução..."
sudo chmod +x "$BIN_DIR/clilog"

rm "$TEMP_BIN_FILE"

echo ""
echo "Instalação do Clilog concluída com sucesso."
echo "Teste com: clilog help"
