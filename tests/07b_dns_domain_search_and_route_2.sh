script_type="up"

foreign_options=(
  "dhcp-option DOMAIN example.com"
  "dhcp-option DOMAIN-SEARCH example.org"
  "dhcp-option DOMAIN-ROUTE example.net"
  "dhcp-option DOMAIN-SEARCH example.co.uk"
  "dhcp-option DOMAIN example.co"
  "dhcp-option DOMAIN-ROUTE example.uk.com"
)

TEST_TITLE="DNS Dual Domain, Dual Search, Dual Route (with Order Check)"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DOMAINS="6 example.com false example.org false example.co.uk false example.co false example.net true example.uk.com true"
