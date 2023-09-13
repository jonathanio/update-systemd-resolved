script_type="up"

foreign_options=(
  "dhcp-option DNS 1.23.4.56"
  "dhcp-option DNS 1234:567:89::ab:cdef"
  "dhcp-option DOMAIN example.com"
  "dhcp-option DOMAIN-SEARCH example.org"
  "dhcp-option DOMAIN-ROUTE example.net"
  "dhcp-option DNSSEC yes"
)

TEST_TITLE="DNS, DNSSEC, Domain, Search, and Route"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DOMAINS="3 example.com false example.org false example.net true"
TEST_BUSCTL_DNSSEC="yes"
TEST_BUSCTL_DNS="2 2 4 1 23 4 56 10 16 18 52 5 103 0 137 0 0 0 0 0 0 0 171 205 239"
