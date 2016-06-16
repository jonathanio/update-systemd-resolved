script_type="up"
dev="tun18"
foreign_option_1="dhcp-option DNS 1.23.4.56"
foreign_option_2="dhcp-option DNS 2.34.56.7"
foreign_option_3="dhcp-option DNS 1234:567:89::ab:cdef"
foreign_option_4="dhcp-option DNS 1234:567:89::ba:cdef"
foreign_option_5="dhcp-option DOMAIN example.com"
foreign_option_6="dhcp-option DOMAIN-SEARCH example.co"

TEST_TITLE="DNS IPv4 and IPv6 Servers, plus Domain and Search"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DNS="4 2 4 1 23 4 56 2 4 2 34 56 7 2 16 18 52 5 103 0 137 0 0 0 0 0 0 0 171 205 239 2 16 18 52 5 103 0 137 0 0 0 0 0 0 0 186 205 239"
TEST_BUSCTL_DOMAINS="2 example.com false example.co true"
