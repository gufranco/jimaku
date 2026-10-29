# shellcheck shell=bash
# shellcheck disable=SC2207

_jimaku() {
  local cur prev words
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"
  if [[ "${prev}" == "--language" ]]; then
    COMPREPLY=($(compgen -W "en es pt-BR fr de it pt ru ar ja ko zh" -- "${cur}"))
    return
  fi
  if [[ "${cur}" == -* ]]; then
    COMPREPLY=($(compgen -W "--language --force --no-force --hearing-impaired --no-hearing-impaired --dry-run --json" -- "${cur}"))
    return
  fi
  words="$(compgen -f -- "${cur}" || true)"
  if [[ "${COMP_CWORD}" -eq 1 ]]; then
    words="doctor version help ${words}"
  fi
  COMPREPLY=($(compgen -W "${words}" -- "${cur}"))
}

complete -o filenames -F _jimaku jimaku
