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
    local note_content=""
    local due_date="-" # Padrão: Sem data de vencimento
    
    while [[ $# -gt 0 ]]; do
        key="$1"
        case "$key" in
            --due)
                if [ -n "$2" ] && date -d "$2" "+%Y-%m-%d" &> /dev/null; then
                    due_date=$(date -d "$2" "+%Y-%m-%d")
                    shift # Consome o --due
                    shift # Consome o valor da data
                else
                    echo "Error: Invalid or missing date after --due. Use YYYY-MM-DD."
                    return 1
                fi
                ;;
            *)
                note_content+="$1 "
                shift
                ;;
        esac
    done

    note_content=$(echo "$note_content" | xargs)

    if [ -z "$note_content" ]; then
        echo "Error: Note content cannot be empty."
        return 1
    fi

    local timestamp=$(date +"%Y-%m-%d %H:%M")
    
    local new_line="[ ] | Due: $due_date | ($timestamp) $note_content"
    
    local next_id=$(wc -l < "$CLILOG_LOG" | awk '{print $1 + 1}')
    
    echo "$next_id. $new_line" >> "$CLILOG_LOG"
    echo "Note $next_id added. Due: $due_date"
}

_clilog_show_help() {
    printf "\n\033[1;36mClilog - CLI Task Manager \033[0m\n"
    printf "\033[90mVersion:\033[0m 0.3\n\n"
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
    printf "  \033[32mexport [file] [format]\033[0m - Export notes to file (markdown, json, csv).\n"
    printf "  \033[32mweb\033[0m -  Starts the new clilog web mode (made with python).\n"
    printf "  \033[32madd [TASK] --due YYYY-MM-DD\033[0m - Add a new note/task with Expiration date.\n"
    printf "  \033[32mhelp\033[0m            - Shows this help message.\n\n"

    printf "\033[1mEXAMPLES:\033[0m\n"
    printf "  clilog add \"Learn C\" \n"
    printf "  clilog done 2\n"
    printf "  clilog search \"Jujutsu\"\n\n"
}

_clilog_list_notes() {

    [[ ! -f "$CLILOG_LOG" ]] && { echo "No notes found!"; return; }

    awk '{
        if ($2 == "[X]") {
            # Green Color (Completed tasks)
            printf "\033[32m%s\033[0m\n", $0
        } else {
            # Yellow Color (Pending tasks)
            printf "\033[33m%s\033[0m\n", $0
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
    grep -i "$keyword" "$file" | awk -v keyword="$keyword" '{
        
        line_content = $0
        
        gsub(keyword, "\033[36m&\033[0m", line_content)

        if ($2 == "[X]") {
            printf "\033[32m%s\033[0m\n", line_content
        } else {
            printf "\033[33m%s\033[0m\n", line_content
        }
    }'
    
    if [ ${PIPESTATUS[0]} -ne 0 ] && [ ${PIPESTATUS[1]} -ne 0 ]; then
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


_clilog_export() {
    local output_file="$1"
    local format="$2"
    local notes_file="$CLILOG_LOG"

    [[ ! -f "$notes_file" ]] && { echo "No notes found!"; return 1; }
    [[ ! -s "$notes_file" ]] && { echo "No notes to export!"; return 1; }

    case "${format:-markdown}" in
        markdown|md)
            _clilog_export_md "$output_file"
            ;;
        json)
            _clilog_export_json "$output_file"
            ;;
        csv)
            _clilog_export_csv "$output_file"
            ;;
        *)
            echo "Error: Format '$format' not supported. Use: markdown, json, csv"
            return 1
            ;;
    esac
}

_clilog_export_json() {
    local output_file="$1"
    local notes_file="$CLILOG_LOG"
    
    echo "[" > "$output_file"
    
    awk '
    function escape_string(str) {
        gsub(/"/, "\\\"", str)
        gsub(/\//, "\\/", str)
        gsub(/\t/, "\\t", str)
        gsub(/\n/, "\\n", str)
        gsub(/\r/, "\\r", str)
        return str
    }
    
    {
        status = ($1 == "[X]") ? "completed" : "pending"
        
        gsub(/^\[X\] |^\[ \] /, "")
        
        # Extrai timestamp (formato: (YYYY-MM-DD HH:MM))
        timestamp = ""
        if (match($0, /\([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}\)/)) {
            timestamp = substr($0, RSTART+1, RLENGTH-2)
            # Remove o timestamp do conteúdo principal
            $0 = substr($0, 1, RSTART-1) substr($0, RSTART+RLENGTH)
        }
        
        tag_count = 0
        delete tags
        original_line = $0
        while (match(original_line, /#([a-zA-Z0-9_]+)/)) {
            tag = substr(original_line, RSTART+1, RLENGTH-1)
            tags[++tag_count] = tag
            # Remove esta tag da string para a próxima iteração
            original_line = substr(original_line, 1, RSTART-1) substr(original_line, RSTART+RLENGTH)
        }
        
        content = $0
        gsub(/\s+$/, "", content)          
        printf "  {\n"
        printf "    \"id\": %d,\n", NR
        printf "    \"status\": \"%s\",\n", status
        printf "    \"timestamp\": \"%s\",\n", timestamp
        printf "    \"content\": \"%s\",\n", escape_string(content)
        printf "    \"tags\": ["
        for (i = 1; i <= tag_count; i++) {
            if (i > 1) printf ", "
            printf "\"%s\"", tags[i]
        }
        printf "]\n"
        printf "  }%s\n", (NR == total) ? "" : ","
    }
    ' total=$(wc -l < "$notes_file") "$notes_file" >> "$output_file"
    
    echo "]" >> "$output_file"
    
    echo "📁 Exported to JSON: $output_file"
    echo "📊 Total notes: $(wc -l < "$notes_file")"
}

_clilog_export_md() {
    local output_file="${1:-clilog_export.md}"
    local notes_file="$CLILOG_LOG"

    [[ ! -f "$notes_file" ]] && { echo "No notes found!"; return 1; }
    [[ ! -s "$notes_file" ]] && { echo "No notes to export!"; return 1; }

    local total_notes completed pending
    total_notes=$(wc -l < "$notes_file")
    completed=$(grep -c "^\[X\]" "$notes_file" || true)
    pending=$((total_notes - completed))

    {
        echo "# 🧠 Clilog Tasks Export"
        echo ""
        echo "**Export Date:** $(date '+%Y-%m-%d %H:%M')"
        echo "**Total Tasks:** $total_notes"
        echo "**Completed:** $completed • **Pending:** $pending"
        echo "**Completion:** $((total_notes > 0 ? (completed * 100) / total_notes : 0))%"
        echo ""
        
        if (( completed > 0 )); then
            echo "## ✅ Completed Tasks ($completed)"
            grep "^\[X\]" "$notes_file" | while read -r line; do
                local processed_line=$(echo "$line" | sed '
                    s/^\[X\]/(✅)/;
                    s/#\([a-zA-Z0-9_]*\)/`#\1`/g;
                    s/(\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} [0-9]\{2\}:[0-9]\{2\}\))/**\1**/
                ')
                echo "- $processed_line"
            done
            echo ""
        fi

        if (( pending > 0 )); then
            echo "## 🕐 Pending Tasks ($pending)"
            grep "^\[ \]" "$notes_file" | while read -r line; do
                local processed_line=$(echo "$line" | sed '
                    s/^\[ \]/(⏳)/;
                    s/#\([a-zA-Z0-9_]*\)/`#\1`/g;
                    s/(\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} [0-9]\{2\}:[0-9]\{2\}\))/**\1**/
                ')
                echo "- $processed_line"
            done
            echo ""
        fi

        echo "## 🏷️ Tags Summary"
        local tags
        tags=$(grep -o '#[a-zA-Z0-9_]*' "$notes_file" | sort | uniq -c | sort -nr | head -10)
        if [[ -n "$tags" ]]; then
            echo "$tags" | while read -r count tag; do
                echo "- **$tag**: $count tasks"
            done
        else
            echo "No tags found."
        fi
        
        echo ""
        echo "---"
        echo "*Generated by [clilog](https://github.com/simeulinuxkaliaiwr/clilog)*"

    } > "$output_file"

    echo "Exported $total_notes tasks to $output_file"
    echo "Stats: $completed completed, $pending pending"
}

_clilog_export_csv() {
    local output_file="$1"
    local notes_file="$CLILOG_LOG"
    
    echo "id,status,timestamp,content,tags" > "$output_file"
    awk '
    {
        status = ($1 == "[X]") ? "completed" : "pending"
        gsub(/^\[X\] |^\[ \] /, "")
        
        # Extrai timestamp
        if (match($0, /\([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}\)/)) {
            timestamp = substr($0, RSTART+1, RLENGTH-2)
            $0 = substr($0, 1, RSTART-1) substr($0, RSTART+RLENGTH)
        }
        
        # Extrai tags
        tags = ""
        while (match($0, /#([a-zA-Z0-9_]+)/)) {
            if (tags != "") tags = tags ";"
            tags = tags substr($0, RSTART+1, RLENGTH-1)
            $0 = substr($0, 1, RSTART-1) substr($0, RSTART+RLENGTH)
        }
        
        gsub(/"/, "\"\"", $0)
        printf "%d,%s,\"%s\",\"%s\",\"%s\"\n", NR, status, timestamp, $0, tags
    }
    ' "$notes_file" >> "$output_file"
    
    echo "📊 Exported to CSV: $output_file"
}

_clilog_show_version() {
    local version="0.3"
    echo "Clilog | Version: $version"
}

_clilog_list_due_notes() {
    local file="$CLILOG_LOG"
    local current_date=$(date +%Y-%m-%d)

    grep -E '^([0-9]+\. )?\[ \].* \| Due: ' "$file" | \

    sort -t'|' -k2 | \

    awk -v current_date="$current_date" '
        BEGIN {
            FS = "|";
            OFS = " | ";
            print "\n-----------------------------------------------------"
            print "ID | Status | Due Date   | Note"
            print "---|--------|------------|----------------------------"
            count = 1; 
        }

        {

            status_raw = $1;
            sub(/^[0-9]+\. /, "", status_raw);
            gsub(/^[ \t]+|[ \t]+$/, "", status_raw); # Limpa espaços

            due_field = $2;
            gsub(/^[ \t]+|[ \t]+$/, "", due_field); # Limpa espaços
            sub(/^Due: /, "", due_field); 
            due_date = due_field; 

            note_content = $3;
            gsub(/^[ \t]+|[ \t]+$/, "", note_content); # Limpa espaços

            color_reset = "\033[0m"
            color = color_reset

            if (due_date < current_date && due_date != "-") {
                color = "\033[1;31m"; # Vermelho (Atrasado)
            } else if (due_date == current_date) {
                color = "\033[1;33m"; # Amarelo (Hoje)
            }

            printf "%2d %s %s %s %s%s%s\n", count, status_raw, color, due_date, color_reset, OFS, note_content;
            count++;
        }

    '
}
