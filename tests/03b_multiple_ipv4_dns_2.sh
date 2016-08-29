script_type="up"
dev="tun03"
foreign_option_1="dhcp-option DNS 1.23.4.56"
foreign_option_2="dhcp-option DNS 5.6.7.89"
foreign_option_3="dhcp-option DNS 34.5.67.8"

TEST_TITLE="Multiple IPv4 DNS Servers (Part 2)"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DNS="3 2 4 1 23 4 56 2 4 5 6 7 89 2 4 34 5 67 8"
