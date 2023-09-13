script_type="up"

foreign_options=(
  "dhcp-option DOMAIN example.com"
  "dhcp-option DOMAIN-SEARCH example.org"
  "dhcp-option DOMAIN-SEARCH example.co.uk"
  "dhcp-option DOMAIN-ROUTE example.net"
)

TEST_TITLE="DNS Single Domain, Dual Search, Single Route"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DOMAINS="4 example.com false example.org false example.co.uk false example.net true"
