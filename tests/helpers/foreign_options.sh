# Convenience function for testing the behaviour of `update-systemd-resolved`'s
# custom foreign option.  Defines a number of variables recognized by
# `run-test` and its `busctl` mock function.
run_custom_foreign_option_test() {
  local directive="$1"
  shift

  local args="$1"
  shift

  # If we're here, we expect `busctl` to be called (unless told otherwise).
  TEST_BUSCTL_CALLED="${TEST_BUSCTL_CALLED:-1}"

  local dhcp_option="${directive}${args:+ ${args}}"
  local TEST_TITLE="resolved-specific dhcp-option directive: ${directive}${args:+ ${args}}"
  local foreign_option_1="dhcp-option ${dhcp_option}"
  local suffix="${directive//-/_}"
  local varname="TEST_BUSCTL_${suffix^^}"
  declare "${varname}=$*"

  runtest
}

# `run_custom_foreign_option_test` convenience wrapper that injects the
# interface index as the first argument in the list of expected arguments.
run_custom_foreign_option_test_with_ip_ifindex() {
  local directive="$1"
  shift

  local args="$1"
  shift

  run_custom_foreign_option_test "$directive" "$args" "${ip_ifindex?}" "$@"
}
