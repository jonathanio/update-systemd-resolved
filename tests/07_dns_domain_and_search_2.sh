script_type="up"
dev="tun07"
foreign_option_1="dhcp-option DOMAIN example.com"
foreign_option_2="dhcp-option DOMAIN-SEARCH example.org"
foreign_option_3="dhcp-option DOMAIN-SEARCH example.net"

TEST_TITLE="DNS Domain and Search (Part 2)"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DNS=""
TEST_BUSCTL_DOMAINS="3 example.com false example.org true example.net true"
