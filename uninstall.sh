# === UNINSTALL.SH ===

#!/usr/bin/env bash

set -euo pipefail

if [[ "$EUID" != 0 ]]; then
	echo -e "\033[31mError: you MUST run this script with sudo!\033[0m"
	exit 1
fi

echo "Starting Clilog Uninstallation..."
read -rp "Do you REALLY want to delete clilog from your OS? (y/n): " confirm
if [[ -z "$confirm" ]] || [[ ! "$confirm" =~ ^[Yy]$ ]]; then
	echo "Ok! Exiting..."
	exit 0
fi

rm -rf "/usr/local/lib/clilog"
rm -f "/usr/local/bin/clilog"
rm -f "/usr/local/share/man/man1/clilog.1"
EXIT_STATUS=$?
if [[ "$EXIT_STATUS" -eq 0 ]]; then
	printf "\e[32mDesinstallation Completed Succesfully!\e[0m"
else
	printf "\033[31mError: Desinstallation failed, EXIT STATUS: $EXIT_STATUS\033[0m"
fi
