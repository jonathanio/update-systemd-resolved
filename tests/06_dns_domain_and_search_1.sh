script_type="up"
dev="tun06"
foreign_option_1="dhcp-option DOMAIN example.com"
foreign_option_2="dhcp-option DOMAIN-SEARCH example.org"

TEST_TITLE="DNS Domain and Search (Part 1)"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DNS=""
TEST_BUSCTL_DOMAINS="2 example.com false example.org true"
