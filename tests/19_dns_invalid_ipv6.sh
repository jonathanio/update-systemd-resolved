script_type="up"
dev="tun19"

# busctl should not be called for any test in here
TEST_BUSCTL_CALLED=0

# update-systemd-resolved should exit nonzero for all tests
EXPECT_FAILURE=1

declare -A test_attrs=(
    ["has more than one \`::'"]='1234::567::89:ab'
    ['too long']='1234:567:89:a:b:c:d:e:f'
    ['single 0 shortened']='1234::567:89:ab:c:de:f'
    ['zero-run in wrong location']='1234:0:0:567:89::ab'
    ['compressed run not longest zero-run']='1234:0:0:0:567::89'
)

for test_title in "${!test_attrs[@]}"; do
    TEST_TITLE="DNS IPv6 address $test_title"
    foreign_option_1="dhcp-option DNS ${test_attrs["$test_title"]}"
    runtest
done
