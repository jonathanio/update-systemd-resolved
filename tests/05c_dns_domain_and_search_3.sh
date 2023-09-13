script_type="up"

foreign_options=(
  "dhcp-option DOMAIN-SEARCH example.org"
  "dhcp-option DOMAIN example.com"
  "dhcp-option DOMAIN-SEARCH example.net"
)

TEST_TITLE="DNS Single Domain and Dual Search (with Order Check)"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DOMAINS="3 example.com false example.org false example.net false"
