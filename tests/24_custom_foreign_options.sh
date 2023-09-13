script_type="up"

run_custom_foreign_option_test() {
  local TEST_TITLE foreign_option_1 suffix varname

  TEST_TITLE="resolved-specific dhcp-option directive: ${1}${2:+ ${2}}"
  foreign_option_1="dhcp-option ${1}${2:+ ${2}}"
  suffix="${1//-/_}"
  varname="TEST_BUSCTL_${suffix^^}"
  declare "${varname}=${3:+${3} }${2}"

  runtest
}

run_custom_foreign_option_test_with_ip_ifindex() {
  run_custom_foreign_option_test "$@" "${ip_ifindex?}"
}

test_valid_custom_foreign_options() {
  local test_option test_value

  for test_option in FLUSH-CACHES RESET-STATISTICS RESET-SERVER-FEATURES; do
    for test_value in true false yes no; do
      run_custom_foreign_option_test "$test_option" "$test_value"
    done
  done

  for test_option in DNS-OVER-TLS DEFAULT-ROUTE LLMNR MULTICAST-DNS; do
    for test_value in true false yes no; do
      run_custom_foreign_option_test_with_ip_ifindex "$test_option" "$test_value"
    done
  done

  for test_option in DNS-OVER-TLS LLMNR MULTICAST-DNS; do
    for test_value in true false yes no; do
      run_custom_foreign_option_test_with_ip_ifindex "$test_option" default
    done
  done

  for test_option in LLMNR MULTICAST-DNS; do
    run_custom_foreign_option_test_with_ip_ifindex "$test_option" resolve
  done

  run_custom_foreign_option_test_with_ip_ifindex DNS-OVER-TLS opportunistic
}

test_invalid_custom_foreign_options() {
  local test_option test_value

  EXPECT_FAILURE=1

  for test_option in FLUSH-CACHES RESET-STATISTICS RESET-SERVER-FEATURES; do
    for test_value in "" nope yessirree; do
      run_custom_foreign_option_test "$test_option" "$test_value"
    done
  done

  for test_option in DNS-OVER-TLS DEFAULT-ROUTE LLMNR MULTICAST-DNS; do
    for test_value in "" nope yessirree; do
      run_custom_foreign_option_test_with_ip_ifindex "$test_option" "$test_value"
    done
  done
}

test_valid_custom_foreign_options
test_invalid_custom_foreign_options
