script_type="up"

foreign_options=(
  "dhcp-option DNS 1.23.4.56"
  "dhcp-option DNS 5.6.7.89"
  "dhcp-option DNS 34.5.67.8"
)

TEST_TITLE="Multiple IPv4 DNS Servers (Part 2)"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DNS="3 2 4 1 23 4 56 2 4 5 6 7 89 2 4 34 5 67 8"
