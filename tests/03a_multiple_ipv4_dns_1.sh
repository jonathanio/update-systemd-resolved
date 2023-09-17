script_type="up"

foreign_options=(
  "dhcp-option DNS 1.23.4.56"
  "dhcp-option DNS 5.6.7.89"
)

TEST_TITLE="Multiple IPv4 DNS Servers (Part 1)"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DNS="2 2 4 1 23 4 56 2 4 5 6 7 89"
