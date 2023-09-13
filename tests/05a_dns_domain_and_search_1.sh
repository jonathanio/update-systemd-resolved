script_type="up"

foreign_options=(
  "dhcp-option DOMAIN example.com"
  "dhcp-option DOMAIN-SEARCH example.org"
)

TEST_TITLE="DNS Single Domain and Single Search"
TEST_BUSCTL_CALLED=1
TEST_BUSCTL_DOMAINS="2 example.com false example.org false"
