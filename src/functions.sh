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
    printf "\n\033[1;36mClilog - CLI Task Manager \033[0m\n"
    printf "\033[90mVersion:\033[0m 0.2\n\n"
    printf "\033[1mUSAGE:\033[0m clilog <command> [arguments]\n\n"

    printf "\033[1mCOMMANDS:\033[0m\n"
    printf "  \033[32madd [text]\033[0m       - Adds a new note/task.\n"
    printf "  \033[32mlist\033[0m            - Lists all notes, showing their IDs and status.\n"
    printf "  \033[32mdone [ID]\033[0m       - Marks a specific note (by ID) as completed.\n"
    printf "  \033[32mundo [ID]\033[0m       - Unmarks a completed note, returning it to pending.\n"
    printf "  \033[32mdel [ID]\033[0m        - Permanently deletes a specific note.\n"
    printf "  \033[32mclear\033[0m           - Clears ALL notes after security confirmation.\n"
    printf "  \033[32msearch [keyword]\033[0m - Searches for a specific note.\n"
    printf "  \033[32mversion\033[0m         - Shows the current version.\n"
    printf "  \033[32medit [ID]\033[0m            - Edits a task by ID.\n"
    printf "  \033[32mtag add [id] [tag]\033[0m   - Add a tag to a note.\n"
    printf "  \033[32mtag remove [id] [tag]\033[0m       - Remove a tag from a note.\n"
    printf "  \033[32mtag move [id] [old_tag] [new_tag]\033[0m    - Rename/Move a tag on a note.\n"
    printf "  \033[32minteractive \033[0m      - Enter the TUI mode of clilog.\n"
    printf "  \033[32mhelp\033[0m            - Shows this help message.\n\n"

    printf "\033[1mEXAMPLES:\033[0m\n"
    printf "  clilog add \"Learn C\" \n"
    printf "  clilog done 2\n"
    printf "  clilog search \"Jujutsu\"\n\n"
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
    local file
    file="$CLILOG_LOG"
    local line
    line=$(wc -l < "$file")
    [[ ! -f "$CLILOG_LOG" ]] && { echo "No notes found!"; return 1; }
    [[ -z "$id" ]] && { echo "ID not specified, exiting..."; return 1; }
    if (( id > line )); then
	    echo "Error: The id you specified is greater than the number of notes you have, exiting..."
	    return 1
    fi

    awk -v id="$id" 'NR == id { sub(/\[ \]/, "[X]") } { print }' "$CLILOG_LOG" > "$CLILOG_LOG.tmp"

    mv "$CLILOG_LOG.tmp" "$CLILOG_LOG"

    echo "Note $id marked as completed!"
}

_clilog_undo() {
    local id="$1" 
    local file
    file="$CLILOG_LOG"
    local line
    line=$(wc -l < "$file")
    [[ ! -f "$CLILOG_LOG" ]] && { echo "No notes found!"; return 1; }
    [[ -z "$id" ]] && { echo "ID not specified, exiting..."; return 1; }
    if (( id > line )); then
	    echo "Error: The id you specified is greater than the number of notes you have, exiting..."
	    return 1
    fi

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

_clilog_search_notes() {
    local file="$CLILOG_LOG"
    local keyword="$1"

    [[ ! -f "$file" ]] && { echo "No notes found."; return; }

    printf "Resultados da busca por '%s':\n" "$keyword"
    cat -n "$file" | grep -i "$keyword" | awk -v keyword="$keyword" '{
        id = $1 
        
        $1 = ""; 
        line_content = $0
        
        sub(/^  */, "", line_content); 

        gsub(keyword, "\033[36m&\033[0m", line_content)

        if (line_content ~ /^\[X\]/) {
            printf "\033[32m%d. %s\033[0m\n", id, line_content
        } else {
            printf "\033[33m%d. %s\033[0m\n", id, line_content
        }
    }'
    
    if [ ${PIPESTATUS[1]} -ne 0 ]; then
        echo "No notes found for the search."
    fi
}

_clilog_tag_notes() {
    local action="$1"   
    local note_id="$2"
    local tag="$3"    
    local new_tag="$4" 

    [[ ! -f "$CLILOG_LOG" ]] && { echo "No notes found!"; return 1; }
    [[ -z "$note_id" ]] && { echo "Note ID not specified, exiting..."; return 1; }
    [[ ! "$note_id" =~ ^[0-9]+$ ]] && { echo "Note ID must be a number, exiting..."; return 1; }

    local tmpfile
    tmpfile=$(mktemp)

    case "$action" in
        add)
            awk -v id="$note_id" -v tag="$tag" 'NR==id {
                if($0 !~ "#"tag) $0=$0" #"tag
            }1' "$CLILOG_LOG" > "$tmpfile"
            mv "$tmpfile" "$CLILOG_LOG"
            echo "Tag #$tag added to note $note_id."
            ;;
        remove)
            awk -v id="$note_id" -v tag="$tag" 'NR==id {
                gsub("#"tag,"")
            }1' "$CLILOG_LOG" > "$tmpfile"
            mv "$tmpfile" "$CLILOG_LOG"
            echo "Tag #$tag removed from note $note_id."
            ;;
        move)
            [[ -z "$new_tag" ]] && { echo "New tag not specified for move, exiting..."; return 1; }
            awk -v id="$note_id" -v old="$tag" -v new="$new_tag" 'NR==id {
                gsub("#"old,"");
                if($0 !~ "#"new) $0=$0" #"new
            }1' "$CLILOG_LOG" > "$tmpfile"
            mv "$tmpfile" "$CLILOG_LOG"
            echo "Tag #$tag moved to #$new_tag in note $note_id."
            ;;
        *)
            echo "Invalid action! Use add, remove or move."
            rm -f "$tmpfile"
            return 1
            ;;
    esac
}


_clilog_edit_notes() {
	local file="$CLILOG_LOG"
	local line
	line=$(wc -l < "$file")
	local id="$1"
	[[ ! -f "$CLILOG_LOG" ]] && { echo "No notes found!"; return 1; }
	[[ -z "$id" ]] && { echo "Id not specified, exiting..."; return 1; }
	if (( id > line )); then
		echo "Error: The id you specified is greater than the number of notes you have, exiting..."
		return 1
	fi
	echo "Which editor would you like to use?"
	cat <<EOF
	1 = Vim
	2 = Nano
	3 = Neovim
	4 = Emacs
	5 = Vscode
EOF
	read -rp "Your choice: " choice
	if [[ -z "$choice" ]] || [[ ! "$choice" =~ ^[1-5]$ ]]; then
		echo "Error: Your choice must be one of the 5 options, exiting..."
		return 1
	fi
	case $choice in
		1) vim +"$id" "$file" ;;
		2) nano +"$id" "$file" ;;
		3) nvim +"$id" "$file" ;;
		4) emacs +"$id" "$file" ;;
		5) code --goto "$file:$id" ;;
	esac	
}

_clilog_del_line() {
    local id="$1"
    
    [[ ! -f "$CLILOG_LOG" ]] && { echo "No notes found!"; return 1; }
    [[ -z "$id" ]] && { echo "ID not specified, exiting..."; return 1; }

    awk -v id="$id" 'NR != id { print }' "$CLILOG_LOG" > "$CLILOG_LOG.tmp" && \
    mv "$CLILOG_LOG.tmp" "$CLILOG_LOG"

    echo "Note $id deleted!"
}

_clilog_show_version() {
    local version="0.2"
    echo "Clilog | Version: $version"
}

