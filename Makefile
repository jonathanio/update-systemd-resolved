PREFIX := /etc/openvpn
DESTDIR := $(PREFIX)/scripts

SRC = update-systemd-resolved
DEST = $(DESTDIR)/$(SRC)

.PHONY: all install info

all: install info

install:
	@install -Dm750 $(SRC) $(DEST)

info:
	@printf 'Successfully installed %s to %s.\n' $(SRC) $(DEST)
	@echo
	@echo 'Now would be a good time to update /etc/nsswitch.conf:'
	@echo '  # Use systemd-resolved first, then fall back to /etc/resolv.conf'
	@echo '  hosts: files resolve dns myhostname'
	@echo '  # Use /etc/resolv.conf first, then fall back to systemd-resolved'
	@echo '  hosts: files dns resolve myhostname'
	@echo
	@echo 'You should also update your OpenVPN configuration:'
	@printf '  script-security 2\n  up %s\n  down %s\n' $(DEST) $(DEST)
