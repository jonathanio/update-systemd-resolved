script_type="up"

foreign_options=(
  "dhcp-option DOMAIN-ROUTE example.com"
  "dhcp-option DOMAIN-ROUTE example.co"
  "dhcp-option DOMAIN-ROUTE example.co.uk"
)

TEST_TITLE="Single DNS Route"
TEST_BUSCTL_DOMAINS="3 example.com true example.co true example.co.uk true"
TEST_BUSCTL_CALLED=1
