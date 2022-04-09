#!/usr/bin/env bash

# Assert that a condition holds for all supplied arguments
all() {
  if (( "$#" < 2 )); then
    printf 1>&2 -- 'Usage: %s <command> <arg> [<arg> ...]\n' "${FUNCNAME[0]}"
    return 64 # EX_USAGE
  fi

  local cond="$1"
  shift

  local arg
  for arg in "$@"; do
    "$cond" "$arg" || return
  done
}

# Assert that a binary comparison holds across all pairs within a list
all_pairs() {
  if (( "$#" < 2 )); then
    printf 1>&2 -- 'Usage: %s <command> [<arg> ...]\n' "${FUNCNAME[0]}"
    return 64 # EX_USAGE
  fi

  local all_pairs_cond="$1"
  shift

  # If the list is empty or has only one element, then the comparison condition
  # cannot fail
  if (( "$#" < 2 )); then
    return 0
  fi

  local last

  __all_pairs_cond() {
    if [[ -v last ]]; then
        "$all_pairs_cond" "$last" "${1?internal error}" || return
    fi

    last="$1"
  }

  all __all_pairs_cond "$@"
}

# Assert that the provided arguments are (stringly) equal
equal() {
  if (( "$#" != 2 )); then
    printf 1>&2 -- 'Usage: %s <arg> <arg>\n' "${FUNCNAME[0]}"
    return 64 # EX_USAGE
  fi

  [[ "$1" = "$2" ]]
}

# Assert that all elements in a list are (stringly) equal
all_pairs_equal() {
  all_pairs equal "$@"
}
