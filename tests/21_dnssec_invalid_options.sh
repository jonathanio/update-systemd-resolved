script_type="up"
dev="tun21"

TEST_BUSCTL_CALLED=0
EXPECT_FAILURE=1

declare -a test_options=(
  'Default'
  'TRUE'
  'FALSE'
  'ALLOW-DOWNGRADE'
)

for test_option in "${!test_options[@]}"; do
  TEST_TITLE="DNSSEC Set to $test_option"
  foreign_option_1="dhcp-option DNSSEC $test_option"
  runtest
done
