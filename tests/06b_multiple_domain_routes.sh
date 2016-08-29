script_type="up"
dev="tun06"
foreign_option_1="dhcp-option DOMAIN-ROUTE example.com"
foreign_option_2="dhcp-option DOMAIN-ROUTE example.co"
foreign_option_3="dhcp-option DOMAIN-ROUTE example.co.uk"

TEST_TITLE="Single DNS Route"
TEST_BUSCTL_DOMAINS="3 example.com true example.co true example.co.uk true"
TEST_BUSCTL_CALLED=1
