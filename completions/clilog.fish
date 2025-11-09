# === CLILOG.FISH (Completions for fish shell) ===

complete -c clilog -f -a "add list done undo del clear search edit tag export web version help stats interactive"

complete -c clilog -n "__fish_seen_subcommand_from tag" -a "add remove move"
complete -c clilog -n "__fish_seen_subcommand_from export" -a "markdown json csv"
