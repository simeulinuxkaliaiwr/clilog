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
printf "\e[32mDesinstallation Completed Succesfully!\e[0m"
