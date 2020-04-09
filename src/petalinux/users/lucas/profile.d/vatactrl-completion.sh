## vatactrl bash completion

asic_list="0 1"

_vatactrl-bc () {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="--set-config --get-config --set-hold --get-hold --get-counters --reset-counters --trigger-enable-bit --trigger-enable-asic --trigger-enable-tm-hit --trigger-enable-tm-ack --trigger-enable-forced --trigger-disable-bit --trigger-disable-asic --trigger-disable-tm-hit --trigger-disable-tm-ack --trigger-disable-forced --get-trigger-ena-mask --set-ack-timeout --get-ack-timeout --get-event-count --reset-event-count --get-n-fifo --single-read-fifo --read-fifo"

    if [[ ${prev} == vatactrl ]]; then
        COMPREPLY=( $(compgen -W "$asic_list" -- ${cur}) )
    elif [[ ${prev} == "--set-config" ]]; then
        COMPREPLY=( $(compgen -f -- ${cur}) )
    elif [[ ${prev} == "--trigger-enable-bit" ]] ||
         [[ ${prev} == "--trigger-disable-bit" ]]; then
        COMPREPLY=( $(compgen -W "0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 all" -- ${cur}) ) 
    elif [[ ${prev} == "--trigger-enable-asic" ]] ||
         [[ ${prev} == "--trigger-disable-asic" ]]; then
        COMPREPLY=( $(compgen -W "$asic_list all" -- ${cur}) ) 
    else
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi
}

complete -F _vatactrl-bc vatactrl
