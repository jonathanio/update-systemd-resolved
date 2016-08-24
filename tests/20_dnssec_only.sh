script_type="up"
dev="tun20"

TEST_BUSCTL_CALLED=1

declare -A test_options=(
  ['default']='""'
  ['Default']='""'
  ['true']='yes'
  ['True']='yes'
  ['yes']='yes'
  ['Yes']='yes'
  ['false']='no'
  ['False']='no'
  ['no']='no'
  ['No']='no'
  ['allow-downgrade']='allow-downgrade'
)

for test_option in "${!test_options[@]}"; do
  TEST_TITLE="DNSSEC Set to $test_option"
  TEST_BUSCTL_DNSSEC="${test_options["$test_option"]}"
  foreign_option_1="dhcp-option DNSSEC $test_option"
  runtest
done
