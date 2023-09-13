script_type="up"

foreign_options=("dhcp-option DOMAIN-ROUTE example.com")

TEST_TITLE="Single DNS Route"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DOMAINS="1 example.com true"
