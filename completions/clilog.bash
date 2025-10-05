#!/usr/bin/env bash

_clilog_completions() {
    local cur prev cmds opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    cmds="add list done undo del clear search edit tag export web version help stats interactive"

    case "$prev" in
        clilog)
            COMPREPLY=( $(compgen -W "$cmds" -- "$cur") )
            ;;
        tag)
            COMPREPLY=( $(compgen -W "add remove move" -- "$cur") )
            ;;
        export)
            COMPREPLY=( $(compgen -W "markdown json csv" -- "$cur") )
            ;;
        done|undo|del|edit|tag)
            # Sugere IDs existentes (lendo do notes.log)
            if [[ -f "$HOME/.config/clilog/notes.log" ]]; then
                COMPREPLY=( $(awk -F'. ' '{print $1}' "$HOME/.config/clilog/notes.log") )
            fi
            ;;
    esac
}

complete -F _clilog_completions clilog

