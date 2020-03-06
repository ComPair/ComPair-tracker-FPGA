## calctrl bash completion

_calctrl-bc () {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="--cal-pulse-disable --vata-trigger-enable --fast-or-disable --pulse-width --trigger-delay --repeat-delay --start --stop --n-pulses"

    if [[ ${prev} != "--pulse-width" ]] && 
       [[ ${prev} != "--trigger-delay" ]] &&
       [[ ${prev} != "--repeat-delay" ]] &&
       [[ ${prev} != "--n-pulses" ]]; then
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi
}

complete -F _calctrl-bc calctrl
