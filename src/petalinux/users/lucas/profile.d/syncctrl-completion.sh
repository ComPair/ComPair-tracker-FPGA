## syncctrl bash completion

_syncctrl-bc () {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="--counter-reset --get-counter --force-trigger --get-global-hit-enable --global-hit-enable --global-hit-disable --asic-hit-enable --asic-hit-disable --asic-hit-disable-mask"

    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
}

complete -F _syncctrl-bc syncctrl
