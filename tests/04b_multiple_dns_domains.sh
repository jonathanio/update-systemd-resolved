script_type="up"

foreign_options=(
  "dhcp-option DOMAIN example.com"
  "dhcp-option DOMAIN example.co"
)

TEST_TITLE="Multiple DNS Domains"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DOMAINS="2 example.com false example.co false"
