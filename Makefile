PREFIX ?= /etc/openvpn/scripts

SRC = update-systemd-resolved
DEST = $(DESTDIR)$(PREFIX)/$(SRC)

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
	@printf '  setenv PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\n  script-security 2\n  up %s\n  down %s\n  down-pre' $(DEST) $(DEST)

test:
	@./run-tests
