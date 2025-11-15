# === INSTALL.SH ===

#!/usr/bin/env bash

set -euo pipefail

# Root verification

if [[ "$EUID" != 0 ]]; then
	printf "\033[31mError: You MUST run this script with sudo!\033[0m\n"
	exit 1
fi

check_dependencies() {
    local missing=()
    command -v dialog >/dev/null || missing+=("dialog")
    command -v python3 >/dev/null || missing+=("python3")
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "\033[31mMissing dependencies: \033[0m${missing[*]}"
        echo "Install them with the package manager of your distro!"
        exit 1
    fi
}

check_dependencies

# Variables

BIN_DIR="/usr/local/bin"
LIB_DIR="/usr/local/lib/clilog"
MAN_DIR="/usr/local/share/man/man1"

SOURCE_BIN="./bin/clilog"
SOURCE_LIB="./src/functions.sh"
SOURCE_TUI="./src/interactive.sh"
SOURCE_WEB="./src/clilog_web.py"
SOURCE_MAN="./doc/clilog.1"

TEMP_BIN_FILE="/tmp/clilog.tmp"

echo "Starting Clilog installation..."

if [[ -f "$BIN_DIR/clilog" ]]; then
    read -rp "Clilog is already installed. Do you want to update/overwrite it? (y/n): " update
    if [[ ! "$update" =~ ^[yY]$ ]]; then
        echo "Installation canceled by user."
        exit 0
    fi
fi

echo "Creating target directories: $BIN_DIR and $LIB_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$LIB_DIR"

# Completions for shell

case $SHELL in
	*fish)
		cp "completions/clilog.fish" "$HOME/.config/fish/completions/clilog.fish"
		;;
	*bash) 
		cp "completions/clilog.bash" "/usr/share/bash-completion/completions/clilog"
		;;
	*zsh)
		cp "completions/clilog.zsh" "/usr/share/zsh/site-functions/_clilog"
		autoload -U compinit && compinit
		;;
esac

# Copy binary to temp file to fix the source path
cp "$SOURCE_BIN" "$TEMP_BIN_FILE"
sed -i "s|source \".*functions.sh\"|source \"$LIB_DIR/functions.sh\"|" "$TEMP_BIN_FILE"

echo "Copying files..."
cp "$SOURCE_LIB" "$LIB_DIR/"
cp "$SOURCE_TUI" "$LIB_DIR/"
cp "$SOURCE_WEB" "$LIB_DIR/"
cp "$TEMP_BIN_FILE" "$BIN_DIR/clilog"
cp "$SOURCE_MAN" "$MAN_DIR" 

echo "Setting execution permissions..."
chmod +x "$BIN_DIR/clilog" # Make the main executable
chmod +x "$LIB_DIR/interactive.sh"  # Make TUI executable
chmod +x "$LIB_DIR/clilog_web.py" # Make WEB mode executable 
rm "$TEMP_BIN_FILE" # Delete the temp file
# === Help Messages ===
echo ""
echo "Installation completed successfully!"
echo "Test it with: clilog help"
echo "For more information, read the README or run 'man clilog' !"
echo "To start the TUI: $LIB_DIR/interactive.sh"
