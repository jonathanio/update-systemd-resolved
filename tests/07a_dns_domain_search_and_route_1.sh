script_type="up"
foreign_option_1="dhcp-option DOMAIN example.com"
foreign_option_2="dhcp-option DOMAIN-SEARCH example.org"
foreign_option_3="dhcp-option DOMAIN-SEARCH example.co.uk"
foreign_option_4="dhcp-option DOMAIN-ROUTE example.net"

TEST_TITLE="DNS Single Domain, Dual Search, Single Route"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DOMAINS="4 example.com false example.org false example.co.uk false example.net true"
