source "${BASH_SOURCE[0]%/*}/helpers/ipv4.sh"

script_type="up"
dev="tun19"

# busctl should not be called for any test in here
TEST_BUSCTL_CALLED=0

cases=(
  'nope'
  '192.168.22'
  '1.1.1.1.'
  '.9.9.9.9'
  '1.2.3.999'
  'x.x.x.x'
  '1.2.3.-4'
)

all_ipv4_addresses_invalid() {
  local -a improperly_accepted_ipv4=()
  local -a wrongly_parsed_ipv4=()
  local ipv4 bad status

  for ipv4 in "${cases[@]}"; do
    foreign_option_1="dhcp-option DNS ${ipv4}"

    if source update-systemd-resolved; then
      improperly_accepted_ipv4+=("$ipv4")
    fi

    if ! bad="$(all_ipv4_expansion_implementations "$ipv4")"; then
      wrongly_parsed_ipv4+=("$bad")
    fi
  done

  if (( ${#improperly_accepted_ipv4[@]} > 0 )); then
    printf 1>&2 -- 'improperly accepted the following ipv4 addresses:\n'
    printf 1>&2 -- '  %s\n' "${improperly_accepted_ipv4[@]}"
    status=1
  fi

  if (( ${#wrongly_parsed_ipv4[@]} > 0 )); then
    printf 1>&2 -- 'parse for the following ipv4 addresses wrongly succeeded:\n'

    for bad in "${wrongly_parsed_ipv4[@]}"; do
      printf 1>&2 -- '  %s\n' "$bad"
    done

    status=1
  fi

  return "${status:-0}"
}

TEST_TITLE="Known-bad IPv4 addresses are all rejected"
checktest all_ipv4_addresses_invalid
