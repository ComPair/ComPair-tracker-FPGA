## dacctrl bash completion

_dacctrl-bc () {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    prev2="${COMP_WORDS[COMP_CWORD-2]}"
    prev3="${COMP_WORDS[COMP_CWORD-3]}"
    opts="--set-delay --get-delay --set-counts --get-input"

    if [[ ${prev3} == "--set-counts" ]]; then
        ## Need to set integer value... no bash completion suggestions
        return 0;
    elif [[ ${prev2} == "--set-counts" ]]; then
        ## Trying to set dac type...
        COMPREPLY=( $(compgen -W "cal vthr" -- ${cur}) )
        return 0;
    elif [[ ${prev} == "--set-counts" ]]; then
        COMPREPLY=( $(compgen -W "A B" -- ${cur}) )
        return 0;
    elif [[ ${prev} == "--set-delay" ]]; then
        ## Suggest the default delay value.
        COMPREPLY=( $(compgen -W "250" -- ${cur}) )
        return 0;
    else
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi
}

complete -F _dacctrl-bc dacctrl
