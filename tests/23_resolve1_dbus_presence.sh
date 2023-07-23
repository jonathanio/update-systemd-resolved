script_type="up"
dev="tun23"

TEST_TITLE='Error if "busctl status org.freedesktop.resolve1" fails'
TEST_BUSCTL_CALLED=1

# Mocked-up busctl function will return exit code 1 upon "busctl status <...>"
TEST_BUSCTL_STATUS_RC=1
EXPECT_FAILURE=1
