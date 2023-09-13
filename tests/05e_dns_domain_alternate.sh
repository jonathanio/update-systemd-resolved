script_type="up"

foreign_options=("dhcp-option ADAPTER_DOMAIN_SUFFIX example.org")

TEST_TITLE="DNS Doamin using ADAPTER_DOMAIN_SUFFIX"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DOMAINS="1 example.org false"
