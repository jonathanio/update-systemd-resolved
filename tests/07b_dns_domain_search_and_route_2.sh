script_type="up"
dev="tun07"
foreign_option_1="dhcp-option DOMAIN example.com"
foreign_option_2="dhcp-option DOMAIN-SEARCH example.org"
foreign_option_3="dhcp-option DOMAIN-ROUTE example.net"
foreign_option_4="dhcp-option DOMAIN-SEARCH example.co.uk"
foreign_option_5="dhcp-option DOMAIN example.co"
foreign_option_6="dhcp-option DOMAIN-ROUTE example.uk.com"

TEST_TITLE="DNS Dual Domain, Dual Search, Dual Route (with Order Check)"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DOMAINS="6 example.com false example.org false example.co.uk false example.co false example.net true example.uk.com true"
