script_type="up"
foreign_option_1="dhcp-option DNS 1.23.4.56"
foreign_option_2="dhcp-option DNS 2.34.56.7"
foreign_option_3="dhcp-option DOMAIN example.com"

TEST_TITLE="DNS IPv4 Servers and Domain"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DNS="2 2 4 1 23 4 56 2 4 2 34 56 7"
TEST_BUSCTL_DOMAINS="1 example.com false"
