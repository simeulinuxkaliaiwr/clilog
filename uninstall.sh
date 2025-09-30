#!/usr/bin/env bash

set -euo pipefail

echo "Starting Clilog Uninstallation... (Requires sudo!)"
read -rp "Do you REALLY want to delete clilog from your OS? (y/n): " confirm
if [[ -z "$confirm" ]] || [[ ! "$confirm" =~ ^[Yy]$ ]]; then
	echo "Ok! Exiting..."
	exit 0
fi

sudo rm -rf "/usr/local/lib/clilog"
sudo rm -f "/usr/local/bin/clilog"
sudo rm -f "/usr/local/share/man/man1/clilog.1"
EXIT_STATUS=$?
if [[ "$EXIT_STATUS" -eq 0 ]]; then
	printf "\e[32mDesinstallation Completed Succesfully!\e[0m"
else
	printf "\033[31mError: Desinstallation failed, EXIT STATUS: $EXIT_STATUS\033[0m"
fi
