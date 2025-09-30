#!/usr/bin/env bash

set -euo pipefail

BIN_DIR="/usr/local/bin"
LIB_DIR="/usr/local/lib/clilog"
MAN_DIR="/usr/local/share/man/man1"

SOURCE_BIN="./bin/clilog"
SOURCE_LIB="./src/functions.sh"
SOURCE_TUI="./src/interactive.sh"
SOURCE_WEB="./src/clilog_web.py"
SOURCE_MAN="./doc/clilog.1"

TEMP_BIN_FILE="/tmp/clilog.tmp"

echo "Starting Clilog installation (requires sudo)..."

if [[ -f "$BIN_DIR/clilog" ]]; then
    read -rp "Clilog is already installed. Do you want to update/overwrite it? (y/n): " update
    if [[ ! "$update" =~ ^[yY]$ ]]; then
        echo "Installation canceled by user."
        exit 0
    fi
fi

echo "Creating target directories: $BIN_DIR and $LIB_DIR"
sudo mkdir -p "$BIN_DIR"
sudo mkdir -p "$LIB_DIR"

# Copy binary to temp file to fix the source path
cp "$SOURCE_BIN" "$TEMP_BIN_FILE"
sudo sed -i "s|source \".*functions.sh\"|source \"$LIB_DIR/functions.sh\"|" "$TEMP_BIN_FILE"

echo "Copying files..."
sudo cp "$SOURCE_LIB" "$LIB_DIR/"
sudo cp "$SOURCE_TUI" "$LIB_DIR/"
sudo cp "$SOURCE_WEB" "$LIB_DIR/"
sudo cp "$TEMP_BIN_FILE" "$BIN_DIR/clilog"
sudo cp "$SOURCE_MAN" "$MAN_DIR" 

echo "Setting execution permissions..."
sudo chmod +x "$BIN_DIR/clilog"
sudo chmod +x "$LIB_DIR/interactive.sh"  # Make TUI executable
sudo chmod +x "$LIB_DIR/clilog_web.py" 

rm "$TEMP_BIN_FILE"

echo ""
echo "Installation completed successfully! 🔥"
echo "Test it with: clilog help"
echo "For more information, read the README or run 'man clilog' !"
echo "To start the TUI: $LIB_DIR/interactive.sh"

