# Similar to the directory variables specified here:
# https://www.gnu.org/prep/standards/html_node/Directory-Variables.html
PREFIX ?= /usr/local
EXEC_PREFIX ?= $(PREFIX)
LIBEXECDIR ?= $(EXEC_PREFIX)/libexec
DATAROOTDIR ?= $(PREFIX)/share
DATADIR ?= $(DATAROOTDIR)

SRC = update-systemd-resolved
DEST = $(DESTDIR)/$(LIBEXECDIR)/openvpn/$(SRC)
CONF = $(DESTDIR)/$(DATADIR)/doc/openvpn/$(SRC).conf
RULES = $(DESTDIR)/$(DATADIR)/polkit-1/rules.d/10-$(SRC).rules
RULES_OPTIONS ?= --polkit-allowed-user=openvpn --polkit-allowed-group=network

.PHONY: all install info rules

all: install info

$(DEST): $(SRC)
	@install -Dm750 $< $@

$(CONF): $(SRC).conf
	@install -Dm644 $< $@

$(RULES): $(SRC)
	@mkdir -p $$(dirname $@)
	@./$(SRC) print-polkit-rules $(RULES_OPTIONS) > $@

install: $(DEST) $(CONF) $(RULES)

rules: $(RULES)

info:
	@printf 'Successfully installed %s to %s.\n' $(SRC) $(DEST)
	@echo
	@echo   'Now would be a good time to update /etc/nsswitch.conf:'
	@echo
	@echo   '  # Use systemd-resolved first, then fall back to /etc/resolv.conf'
	@echo   '  hosts: files resolve dns myhostname'
	@echo   '  # Use /etc/resolv.conf first, then fall back to systemd-resolved'
	@echo   '  hosts: files dns resolve myhostname'
	@echo
	@echo   'You should also update your OpenVPN configuration:'
	@echo
	@echo   '  script-security 2'
	@printf '  up %s\n' $(DEST)
	@echo   '  up-restart'
	@printf '  down %s\n' $(DEST)
	@echo   '  down-pre'
	@echo
	@echo   '  # If needed, to permit `update-systemd-resolved` to find utilities it depends'
	@echo   '  # on.  Adjust to suit your system.'
	@echo   '  #setenv PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
	@echo
	@printf 'or pass --config %s\n' $(CONF)
	@echo	'in addition to any other --config arguments to your openvpn command.'
	@echo
	@printf 'Please also consider putting the polkit rules %s in /etc/polkit-1/rules.d.\n' $(RULES)

test:
	@./run-tests

nixos-test:
	@nix build -L ".#checks.$$(nix eval --impure --raw --expr builtins.currentSystem).update-systemd-resolved"

# Enter a console with NixOS test machines available
nixos-test-driver:
	@$$(nix-build --no-out-link -A update-systemd-resolved.nixosTest.driver ./nix)/bin/nixos-test-driver --keep-vm-state
