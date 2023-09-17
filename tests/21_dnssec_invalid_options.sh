source "${BASH_SOURCE[0]%/*}/helpers/foreign_options.sh"

script_type="up"

TEST_BUSCTL_CALLED=0
EXPECT_FAILURE=1

for test_value in 1 0 DOWNGRADE; do
  run_custom_foreign_option_test_with_ip_ifindex DNSSEC "$test_value" "$test_value"
done
