#!/usr/bin/env bash

set -euo pipefail

source "/usr/local/lib/clilog/functions.sh"

main_menu() {
    local choice
    while true; do
        choice=$(dialog --clear --backtitle "Clilog TUI Interactive" --title "Interactive CliLog Version 0.3" --menu "Choose a action" 17 60 9 \
        1 "Add note" \
        2 "Del note" \
        3 "List notes" \
        4 "Mark a note as completed" \
        5 "Unmark a note as completed" \
        6 "Clears ALL notes" \
        7 "Search for a especific note" \
        8 "Edit a task by ID" \
	9 "Export notes to file (md, json, csv.)" \
        10 "Exit interactive mode" \
        2>&1 >/dev/tty)

        case "$choice" in
            1) _clilog_tui_add_note ;;
            2) _clilog_tui_del_note ;;
            3) _clilog_tui_list_notes ;;
            4) _clilog_tui_mark_done ;;
            5) _clilog_tui_undo ;;
            6) _clilog_tui_clear_note ;;
            7) _clilog_tui_search_note ;;
            8) _clilog_tui_edit_note ;;
            9) _clilog_tui_export_notes ;;
	    10)
                dialog --msgbox "Exiting interactive mode..." 8 70 2>&1 >/dev/tty
                break
                ;;
        esac
    done
}

_clilog_tui_add_note() {
    local note
    local ddue
    local due

    note=$(dialog --inputbox "Enter the content of the note you want to add:" 15 60 2>&1 >/dev/tty)
    if [[ -z "$note" ]]; then
        dialog --msgbox "Error: The content is empty" 8 50 2>&1 >/dev/tty
        return 1
    fi

    ddue=$(dialog --clear --backtitle "Clilog TUI menu V:0.3" --menu "Do you want to specify an expiration date?" 8 50 2 \
    1 "Yes" \
    2 "No" \
    2>&1 >/dev/tty)

    case "$ddue" in
        1)
            due=$(dialog --clear --backtitle "Clilog TUI menu V:0.3" --inputbox "Enter the expiration date you want (Sintaxe: YYYY-MM-DD, Ex: 2025-09-30)" 8 50 2>&1 >/dev/tty)
            if [[ -z "$due" ]]; then
                dialog --msgbox "Error: Empty Field!" 8 50 2>&1 >/dev/tty
                return 1
            fi
            _clilog_add_note "$note" --due "$due"
            ;;
        2)
            _clilog_add_note "$note"
            ;;
    esac

    dialog --msgbox "Note added successfully!" 8 50 2>&1 >/dev/tty
}

_clilog_tui_del_note() {
    local id
    local file
    file="$CLILOG_LOG"

    exec 3>&1
    id=$(dialog --inputbox "Enter the ID of the note you want to delete" 15 60 2>&1 1>&3)
    exitcode=$?
    exec 3>&-

    if [[ "$exitcode" -ne 0 ]] || [[ -z "$id" ]]; then
        dialog --msgbox "Canceled or empty input." 8 50 2>&1 >/dev/tty
        return 1
    fi

    if [[ ! -f "$file" ]]; then
        dialog --msgbox "Error: No notes found!" 15 60 2>&1 >/dev/tty
        return 1
    fi

    local line
    line=$(wc -l < "$file")
    if (( id > line )); then
        dialog --msgbox "Error: The ID you specified is greater then the number of notes you have" 15 60 2>&1 >/dev/tty
    fi
    _clilog_del_line "$id"
    dialog --msgbox "Note deleted successfully!" 8 50 2>&1 >/dev/tty
}

_clilog_tui_list_notes() {
    if [[ ! -f "$CLILOG_LOG" ]]; then
        dialog --msgbox "Error: No notes found!" 15 60 2>&1 >/dev/tty
        return
    fi
    notes=$(_clilog_list_notes | sed 's/\x1B\[[0-9;]*[JKmsu]//g')
    dialog --msgbox "$notes" 15 60 2>&1 >/dev/tty
}

_clilog_tui_mark_done() {
    exec 3>&1
    id=$(dialog --inputbox "Enter the ID to mark as done:" 10 60 2>&1 1>&3)
    exitcode=$?
    exec 3>&-

    [[ "$exitcode" -ne 0 || -z "$id" ]] && { dialog --msgbox "Canceled or empty input." 8 50 2>&1 >/dev/tty; return 1; }

    result=$(_clilog_mark_done "$id" 2>&1)
    dialog --msgbox "$result" 10 60 2>&1 >/dev/tty
}

_clilog_tui_undo() {
	id=$(dialog --inputbox "Enter the ID to unmark as completed:" 10 60 2>&1 >/dev/tty)
    	[[ -z "$id" ]] && return 1  # saiu sem digitar nada
    	result=$(_clilog_undo "$id" 2>&1)
    	dialog --msgbox "$result" 10 60 2>&1 >/dev/tty
}

_clilog_tui_clear_note() {
    	result=$(_clilog_clear_notes 2>&1)
	dialog --msgbox "$result" 10 60 2>&1 >/dev/tty
}

_clilog_tui_edit_note() {
    	local file="$CLILOG_LOG"
	local line
	line=$(wc -l < "$file")
	exec 3>&1
    	local id=$(dialog --inputbox "Enter the ID of the note to edit:" 10 60 2>&1 1>&3)
    	exitcode=$?
    	exec 3>&-

    	[[ "$exitcode" -ne 0 || -z "$id" ]] && { dialog --msgbox "Canceled or empty input." 8 50 2>&1 >/dev/tty; return 1; }
	if (( id > line )); then
		dialog --msgbox "Error: The ID you specified is greater than the number of notes you have"
	fi
	local editor=$(dialog --clear --menu "Which editor would you like to use?" 15 60 9 2>&1 >/dev/tty \
	1 "Vim" \
	2 "Nano" \
	3 "Neovim" \
	4 "Emacs" \
	5 "Vscode")

	case $editor in
		1) vim +"$id" "$file" ;;
		2) nano +"$id" "$file" ;;
		3) nvim +"$id" "$file" ;;
		4) emacs +"$id" "$file" ;;
		5) code --goto "$file:$id" ;;
	esac

}

_clilog_tui_search_note() {
    	exec 3>&1
    	keyword=$(dialog --inputbox "Enter keyword to search for:" 10 60 2>&1 1>&3)
    	exitcode=$?
    	exec 3>&-

    	[[ "$exitcode" -ne 0 || -z "$keyword" ]] && { dialog --msgbox "Canceled or empty input." 8 50 2>&1 >/dev/tty; return 1; }

    	# Remove ANSI codes da CLI antes de mostrar
    	results=$(_clilog_search_notes "$keyword" | sed 's/\x1B\[[0-9;]*[JKmsu]//g')
    	dialog --msgbox "$results" 15 60 2>&1 >/dev/tty
}

_clilog_tui_export_notes() {
    local format
    local file
    file=$(dialog --backtitle "Clilog interactive TUI Mode" --inputbox "Enter the name (or ABSOLUTE path) of the file where you want to export your notes:" 6 60 2>&1 >/dev/tty)
    [[ -z "$file" ]] && { dialog --msgbox "Error: You did not specify the file!" 8 50 2>&1 >/dev/tty; return; }
    
    format=$(dialog --backtitle "CLilog Interactive TUI Mode" --menu "Choose a format:" 15 60 3 \
        1 "Markdown (.md)" \
        2 "Json (.json)" \
        3 "Csv (.csv)" \
        2>&1 >/dev/tty)
    
    case $format in
        1)
            _clilog_export_md "$file"
            result="$?"
	    ;;
        2)
            _clilog_export_json "$file"
            result="$?"
	    ;;
        3)
            _clilog_export_csv "$file"
            result="$?"
	    ;;
    esac
    if [[ "$result" -eq 0 ]]; then
    	dialog --msgbox "Exported Successfully!" 8 50 2>&1 >/dev/tty
    else
    	dialog --msgbox "FATAL: Exit code: $result" 8 50 2>&1 >/dev/tty
    fi

}
