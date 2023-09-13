script_type="up"

foreign_options=(
  "dhcp-option DNS 1.23.4.56"
  "dhcp-option DNS 2.34.56.7"
  "dhcp-option DNS 1234:567:89::ab:cdef"
  "dhcp-option DNS 1234:567:89::ba:cdef"
  "dhcp-option DOMAIN example.com"
  "dhcp-option DOMAIN-SEARCH example.co"
)

TEST_TITLE="DNS IPv4 and IPv6 Servers, plus Domain and Search"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DNS="4 2 4 1 23 4 56 2 4 2 34 56 7 10 16 18 52 5 103 0 137 0 0 0 0 0 0 0 171 205 239 10 16 18 52 5 103 0 137 0 0 0 0 0 0 0 186 205 239"
TEST_BUSCTL_DOMAINS="2 example.com false example.co false"
