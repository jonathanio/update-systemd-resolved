script_type="up"
dev="tun16"
foreign_option_1="dhcp-option DNS6 1234:567:89::ab:cdef"
foreign_option_2="dhcp-option DNS 1.23.4.56"

TEST_TITLE="Single IPv6 and Single IPv4 DNS Servers (DNS6)"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DNS="2 10 16 18 52 5 103 0 137 0 0 0 0 0 0 0 171 205 239 2 4 1 23 4 56"
