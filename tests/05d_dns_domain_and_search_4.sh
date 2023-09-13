script_type="up"

foreign_options=(
  "dhcp-option DOMAIN-SEARCH example.org"
  "dhcp-option DOMAIN example.co"
  "dhcp-option DOMAIN example.com"
  "dhcp-option DOMAIN-SEARCH example.net"
)

TEST_TITLE="DNS Dual Domain and Dual Search (with Order Check)"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DOMAINS="4 example.co false example.org false example.com false example.net false"
