script_type="up"

foreign_options=(
  "dhcp-option DNS 1.23.4.56"
  "dhcp-option DNS 2.34.56.7"
  "dhcp-option DOMAIN example.com"
)

TEST_TITLE="DNS IPv4 Servers and Domain"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DNS="2 2 4 1 23 4 56 2 4 2 34 56 7"
TEST_BUSCTL_DOMAINS="1 example.com false"
