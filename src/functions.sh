#!/usr/bin/env bash

set -euo pipefail

# --- CONFIGURATION VARIABLES (for better organization) ---
CLILOG_DIR="$HOME/.config/clilog"
CLILOG_LOG="$CLILOG_DIR/notes.log"

# --- SETUP FUNCTIONS ---

_clilog_setup() {
    mkdir -p "$CLILOG_DIR"
}


_clilog_add_note() {
    local NOTE_TEXT="$1"
    
    echo "[ ] ($(date +"%Y-%m-%d %H:%M")) ${NOTE_TEXT}" >> "$CLILOG_LOG"
    echo "Note added." # Additional feedback for the user
}

_clilog_show_help() {
	cat <<EOF
Clilog - CLI Task Manager

USAGE: clilog <command> [arguments]

COMMANDS:
  add [text]       Adds a new note/task.
  list             Lists all notes, showing their IDs and status.
  done [ID]        Marks a specific note (by ID) as completed.
  undo [ID]        Unmarks a completed note, returning it to pending.
  del [ID]         Permanently deletes a specific note.
  clear            Clears ALL notes after security confirmation.
  version          Shows the current version of Clilog.
  help             Shows this help message.

The ID is the line number, checked with 'clilog list'.
EOF
	exit 1
}

_clilog_list_notes() {

    [[ ! -f "$CLILOG_LOG" ]] && { echo "No notes found!"; return; }

    awk '{
        id = NR
        if ($1 == "[X]") {
            # Green Color
            printf "\033[32m%d. %s\033[0m\n", id, $0
        } else {
            # Yellow Color (for pending)
            printf "\033[33m%d. %s\033[0m\n", id, $0
        }
    }' "$CLILOG_LOG"
}

_clilog_mark_done() {
    local id="$1"
    
    [[ ! -f "$CLILOG_LOG" ]] && { echo "No notes found!"; return 1; }
    [[ -z "$id" ]] && { echo "ID not specified, exiting..."; return 1; }

    awk -v id="$id" 'NR == id { sub(/\[ \]/, "[X]") } { print }' "$CLILOG_LOG" > "$CLILOG_LOG.tmp"

    mv "$CLILOG_LOG.tmp" "$CLILOG_LOG"

    echo "Note $id marked as completed!"
}

_clilog_undo() {
    local id="$1" 
    
    [[ ! -f "$CLILOG_LOG" ]] && { echo "No notes found!"; return 1; }
    [[ -z "$id" ]] && { echo "ID not specified, exiting..."; return 1; }

    awk -v id="$id" 'NR == id { sub(/\[X\]/, "[ ]") } { print }' "$CLILOG_LOG" > "$CLILOG_LOG.tmp"

    mv "$CLILOG_LOG.tmp" "$CLILOG_LOG"

    echo "↩️ Note $id returned to pending!"
}

_clilog_clear_notes() {
    read -rp "Do you REALLY want to clear ALL notes? (y/n): " choice
    
    if ! [[ "$choice" =~ ^[yYnN]$ ]]; then
         printf "Error: Invalid choice. Use 'y' for yes or 'n' for no, exiting...\n"
    fi

    case $choice in
        y|Y)
            printf "Ok! clearing...\n"
            > "$CLILOG_LOG" 
            ;;
        n|N)
            printf "Ok! Exiting...\n"
            exit 0
            ;;
    esac
}

_clilog_del_line() {
    local id="$1"
    
    [[ ! -f "$CLILOG_LOG" ]] && { echo "No notes found!"; return 1; }
    [[ -z "$id" ]] && { echo "ID not specified, exiting..."; return 1; }

    awk -v id="$id" 'NR != id { print }' "$CLILOG_LOG" > "$CLILOG_LOG.tmp" && \
    mv "$CLILOG_LOG.tmp" "$CLILOG_LOG"

    echo "🗑️ Note $id deleted!"
}

_clilog_show_version() {
    local version="0.1"
    echo "Clilog | Version: $version"
}

