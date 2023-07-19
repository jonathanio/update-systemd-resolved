source "${BASH_SOURCE[0]%/*}/helpers/ipv6.sh"

script_type="up"
dev="tun19"

TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DNS=SKIP

# update-systemd-resolved should exit nonzero for all tests
EXPECT_FAILURE=0

private=(
  fc00::
  fc01::1234
  fdef::
  fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
)

public=(
  ::abcd:1234
  1::
  2::
  1:1:1:1::
  2001:abcd::
  abcd::
)

loopback=(
  ::1
)

ipv4_mapped=(
  ::ffff:0:0
  ::ffff:0:1234
  ::ffff:1.2.3.4
  ::ffff:ffff:ffff
)

discard=(
  100::
  100::1234
  100:0000:0000:0000:ffff:ffff:ffff:ffff
)

multicast=(
  ff00::
  ffff::
  ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
)

linklocal=(
  fe80::
  fe89::
  febf::
  febf:ffff:ffff:ffff:ffff:ffff:ffff:ffff
)

teredo=(
  2001::
  2001::1234
  2001:0:ffff:ffff:ffff:ffff:ffff:ffff
)

orchid=(
  2001:10::
  2001:10::1234
  2001:001F:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF
)

documentation=(
  2001:db8::
  2001:db8::1234
  2001:0db8:ffff:ffff:ffff:ffff:ffff:ffff
)

other=(
  fd00:ff:0:2:301:64::3

  # omitted; sipcalc does not handle these
  #1:2:3:4:5:6:7::
  #::1:2:3:4:5:6:7
)

cases=(
  "${private[@]}"
  "${public[@]}"
  "${loopback[@]}"
  "${ipv4_mapped[@]}"
  "${discard[@]}"
  "${multicast[@]}"
  "${linklocal[@]}"
  "${teredo[@]}"
  "${orchid[@]}"
  "${documentation[@]}"
  "${other[@]}"
)

all_ipv6_addresses_valid() {
  local -a improperly_rejected_ipv6=()
  local -a wrongly_parsed_ipv6=()
  local ipv6 bad status

  for ipv6 in "${cases[@]}"; do
    foreign_option_1="dhcp-option DNS ${ipv6}"
    {
      if ! source update-systemd-resolved; then
        improperly_rejected_ipv6+=("$ipv6")
      fi

      if ! bad="$(all_ipv6_expansion_implementations "$ipv6")"; then
        wrongly_parsed_ipv6+=("$bad")
      fi
    } 1>/dev/null
  done

  if (( ${#improperly_rejected_ipv6[@]} > 0 )); then
    printf 1>&2 -- 'Improperly rejected the following IPv6 addresses:\n'
    printf 1>&2 -- '  %s\n' "${improperly_rejected_ipv6[@]}"
    status=1
  fi

  if (( ${#wrongly_parsed_ipv6[@]} > 0 )); then
    printf 1>&2 -- 'Parse for the following IPv6 addresses failed:\n'

    for bad in "${wrongly_parsed_ipv6[@]}"; do
      printf 1>&2 -- '  %s\n' "$bad"
    done

    status=1
  fi

  return "${status:-0}"
}

TEST_TITLE="Known-good IPv6 addresses are all accepted"
checktest all_ipv6_addresses_valid
