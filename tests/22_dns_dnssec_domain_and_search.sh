script_type="up"
dev="tun22"
foreign_option_1="dhcp-option DOMAIN example.com"
foreign_option_2="dhcp-option DOMAIN-SEARCH example.org"
foreign_option_3="dhcp-option DOMAIN-SEARCH example.net"
foreign_option_4="dhcp-option DNSSEC yes"

TEST_TITLE="DNS, DNSSEC, Domain and Search"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DOMAINS="3 example.com false example.org true example.net true"
TEST_BUSCTL_DNSSEC="yes"
