script_type="up"
dev="tun05"
foreign_option_1="dhcp-option DOMAIN-SEARCH example.org"
foreign_option_2="dhcp-option DOMAIN example.co"
foreign_option_3="dhcp-option DOMAIN example.com"
foreign_option_4="dhcp-option DOMAIN-SEARCH example.net"

TEST_TITLE="DNS Dual Domain and Dual Search (with Order Check)"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DOMAINS="4 example.co false example.org false example.com false example.net false"
