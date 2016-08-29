script_type="up"
dev="tun08"
foreign_option_1="dhcp-option DNS 1.23.4.56"
foreign_option_2="dhcp-option DNS 2.34.5.67"
foreign_option_3="dhcp-option DOMAIN example.co.uk"
foreign_option_4="dhcp-option DOMAIN-SEARCH example.co"
foreign_option_5="dhcp-option DOMAIN-ROUTE example.com"

TEST_TITLE="DNS IPv4 Servers, Domain, Search, and Route"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DNS="2 2 4 1 23 4 56 2 4 2 34 5 67"
TEST_BUSCTL_DOMAINS="3 example.co.uk false example.co false example.com true"
