script_type="up"

TEST_BUSCTL_CALLED=0
EXPECT_FAILURE=1

declare -a test_invalids=(
  '1'
  '0'
  'DOWNGRADE'
)

for test_option in "${test_invalids[@]}"; do
  TEST_TITLE="DNSSEC Set to $test_option"
  foreign_option_1="dhcp-option DNSSEC $test_option"
  runtest
done
