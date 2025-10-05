#compdef clilog

_arguments \
  '1:command:(add list done undo del clear search edit tag export web version help stats interactive)' \
  '2:subcommand:(add remove move markdown json csv)' \
  '*::arguments:->args'

case $words[1] in
  tag)
    _values 'subcommand' add remove move
    ;;
  export)
    _values 'format' markdown json csv
    ;;
esac

