script_type="up"
dev="tun04"
foreign_option_1="dhcp-option DOMAIN example.com"
foreign_option_2="dhcp-option DOMAIN example.co"

TEST_TITLE="Multiple DNS Domains"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DOMAINS="1 example.co false"
