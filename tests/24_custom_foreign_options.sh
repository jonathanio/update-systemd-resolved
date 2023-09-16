source "${BASH_SOURCE[0]%/*}/helpers/foreign_options.sh"

script_type="up"

test_valid_custom_foreign_options() {
  local test_option test_value

  for test_option in FLUSH-CACHES RESET-STATISTICS RESET-SERVER-FEATURES; do
    for test_value in true false yes no; do
      run_custom_foreign_option_test "$test_option" "$test_value"
      run_custom_foreign_option_test "$test_option" "${test_value^}"
    done
  done

  for test_option in DNS-OVER-TLS DEFAULT-ROUTE LLMNR MULTICAST-DNS; do
    for test_value in true false yes no; do
      run_custom_foreign_option_test_with_ip_ifindex "$test_option" "$test_value" "$test_value"
      run_custom_foreign_option_test_with_ip_ifindex "$test_option" "${test_value^}" "$test_value"
    done
  done

  for test_option in DNS-OVER-TLS LLMNR MULTICAST-DNS; do
    run_custom_foreign_option_test_with_ip_ifindex "$test_option" default default
    run_custom_foreign_option_test_with_ip_ifindex "$test_option" Default default
  done

  for test_option in LLMNR MULTICAST-DNS; do
    run_custom_foreign_option_test_with_ip_ifindex "$test_option" resolve resolve
  done

  run_custom_foreign_option_test_with_ip_ifindex DNS-OVER-TLS opportunistic opportunistic
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
      run_custom_foreign_option_test_with_ip_ifindex "$test_option" "$test_value" "$test_value"
    done
  done
}

test_valid_custom_foreign_options
test_invalid_custom_foreign_options
