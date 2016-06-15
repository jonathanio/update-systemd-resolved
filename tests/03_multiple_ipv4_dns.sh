# Emulate OpenVPN environment
script_type="up"
dev="tun03"
foreign_option_1="dhcp-option DNS 1.23.4.56"
foreign_option_2="dhcp-option DNS 5.6.7.89"

TEST_IFINDEX="$((RANDOM%=64))"
TEST_TITLE="Multiple IPv4 DNS Servers"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DNS="2 2 4 1 23 4 56 2 4 5 6 7 89"
TEST_BUSCTL_DOMAINS=""
