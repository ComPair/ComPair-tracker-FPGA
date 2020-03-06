## vatactrl bash completion

_vatactrl-bc () {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="--set-config --get-config --set-hold --get-hold --get-counters --reset-counters --trigger-enable --trigger-disable --get-trigger-ena-mask --force-trigger --set-ack-timeout --get-ack-timeout --get-event-count --reset-event-count --get-n-fifo --single-read-fifo --read-fifo"

    if [[ ${prev} == vatactrl ]]; then
        COMPREPLY=( $(compgen -W "0 1" -- ${cur}) )
    elif [[ ${prev} == "--set-config" ]]; then
        COMPREPLY=( $(compgen -f -- ${cur}) )
    elif [[ ${prev} == "--trigger-enable" ]] ||
         [[ ${prev} == "--trigger-disable" ]]; then
        COMPREPLY=( $(compgen -W "0 1 2 all" -- ${cur}) ) 
    else
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi
}

complete -F _vatactrl-bc vatactrl
