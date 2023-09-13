script_type="up"
foreign_option_1="dhcp-option DNS 1.23.4.56"
foreign_option_2="dhcp-option DNS 1234:567:89::ab:cdef"
foreign_option_3="dhcp-option DOMAIN example.com"
foreign_option_4="dhcp-option DOMAIN-SEARCH example.org"
foreign_option_5="dhcp-option DOMAIN-ROUTE example.net"
foreign_option_6="dhcp-option DNSSEC yes"

TEST_TITLE="DNS, DNSSEC, Domain, Search, and Route"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DOMAINS="3 example.com false example.org false example.net true"
TEST_BUSCTL_DNSSEC="yes"
TEST_BUSCTL_DNS="2 2 4 1 23 4 56 10 16 18 52 5 103 0 137 0 0 0 0 0 0 0 171 205 239"
