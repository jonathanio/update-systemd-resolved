source "${BASH_SOURCE[0]%/*}/helpers/ipv6.sh"

script_type="up"

# busctl should not be called for any test in here
TEST_BUSCTL_CALLED=0

cases=(
  # More than one \`::'
  1234::567::89:ab
  1:::8

  # Too long
  1234:567:89:a:b:c:d:e:f

  # Also too long
  1234:567:89:0::c:d:e:f

  # Leading colon
  :1234:567:89:a:b:c:d:e

  # Trailing colon
  1234:567:89:a:b:c:d:e:

  # Not hexadecimal
  ::zzzz

  # Bad embedded IPv4
  ::ffff:999.999.999.999

  # Embedded IPv4 in wrong location
  1.2.3.4::ffff

  # Leading garbage
  @--@::1

  # Plain garbage
  :
  :::
)

all_ipv6_addresses_invalid() {
  local -a improperly_accepted_ipv6=()
  local -a wrongly_parsed_ipv6=()
  local ipv6 bad status

  for ipv6 in "${cases[@]}"; do
    foreign_option_1="dhcp-option DNS ${ipv6}"

    if source update-systemd-resolved; then
      improperly_accepted_ipv6+=("$ipv6")
    fi

    if ! bad="$(all_ipv6_expansion_implementations "$ipv6")"; then
      wrongly_parsed_ipv6+=("$bad")
    fi
  done

  if (( ${#improperly_accepted_ipv6[@]} > 0 )); then
    printf 1>&2 -- 'improperly accepted the following IPv6 addresses:\n'
    printf 1>&2 -- '  %s\n' "${improperly_accepted_ipv6[@]}"
    status=1
  fi

  if (( ${#wrongly_parsed_ipv6[@]} > 0 )); then
    printf 1>&2 -- 'parse for the following IPv6 addresses wrongly succeeded:\n'

    for bad in "${wrongly_parsed_ipv6[@]}"; do
      printf 1>&2 -- '  %s\n' "$bad"
    done

    status=1
  fi

  return "${status:-0}"
}

TEST_TITLE="Known-bad IPv6 addresses are all rejected"
checktest all_ipv6_addresses_invalid
