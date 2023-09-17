source "${BASH_SOURCE[0]%/*}/helpers/foreign_options.sh"

script_type="up"

for test_value in true false yes no default allow-downgrade; do
  run_custom_foreign_option_test_with_ip_ifindex DNSSEC "$test_value" "$test_value"
  run_custom_foreign_option_test_with_ip_ifindex DNSSEC "${test_value^}" "$test_value"
done
