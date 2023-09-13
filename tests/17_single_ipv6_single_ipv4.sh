script_type="up"
foreign_option_1="dhcp-option DNS 1234:567:89::ab:cdef"
foreign_option_2="dhcp-option DNS 1.23.4.56"
foreign_option_3="dhcp-option DNS 20a0::1"

TEST_TITLE="Single IPv6 and Single IPv4 DNS Servers"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DNS="3 10 16 18 52 5 103 0 137 0 0 0 0 0 0 0 171 205 239 2 4 1 23 4 56 10 16 32 160 0 0 0 0 0 0 0 0 0 0 0 0 0 1"
