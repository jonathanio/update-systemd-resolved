script_type="up"

foreign_options=(
  "dhcp-option DNS 1.23.4.56"
  "dhcp-option DNS 2.34.5.67"
  "dhcp-option DOMAIN example.co.uk"
  "dhcp-option DOMAIN-SEARCH example.co"
  "dhcp-option DOMAIN-SEARCH example.com"
)

TEST_TITLE="DNS IPv4 Servers, Domain, and Search"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DNS="2 2 4 1 23 4 56 2 4 2 34 5 67"
TEST_BUSCTL_DOMAINS="3 example.co.uk false example.co false example.com false"
