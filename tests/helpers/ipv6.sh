source "${BASH_SOURCE[0]%/*}/assertions.sh"

source update-systemd-resolved

declare -a ipv6_expansion_implementations

add_available_ipv6_expansion_implementations() {
  if (( "$2" == 1 )); then
    ipv6_expansion_implementations+=("$1")
  else
    warning "IPv6 expansion implementation '$1' is not available"
  fi

  # Returning 0 short-circuits each_ip_expansion
  return 1
}

each_ip_expansion_func add_available_ipv6_expansion_implementations IPv6 || exit

all_ipv6_expansion_implementations() {
  local -a expansions=()
  local description="Address: ${1?}"
  local expansion
  local implementation_func

  for implementation_func in "${ipv6_expansion_implementations[@]}"; do
    expansion="$("$implementation_func" "${1?}")" || :
    expansion="${expansion:-<error>}"
    expansions+=("$expansion")
    description="${description:+${description} | }$(printf -- '%s: %s' "$implementation_func" "$expansion")"
  done

  if ! all_pairs_equal "${expansions[@]}"; then
    printf -- '%s\n' "$description"
    return 1
  fi
}
