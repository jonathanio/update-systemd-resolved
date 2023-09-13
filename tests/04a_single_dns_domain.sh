script_type="up"

foreign_options=("dhcp-option DOMAIN example.com")

TEST_TITLE="Single DNS Domain"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DOMAINS="1 example.com false"
