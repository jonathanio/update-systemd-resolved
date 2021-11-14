PREFIX ?= /usr/local/bin

SRC = update-systemd-resolved
DEST = $(DESTDIR)$(PREFIX)/$(SRC)
RULES = $(DESTDIR)/etc/polkit-1/rules.d/10-$(SRC).rules
RULES_OPTIONS ?= --polkit-allowed-user=openvpn --polkit-allowed-group=network

.PHONY: all install info rules

all: install info

$(DEST): $(SRC)
	@install -Dm750 $< $@

$(DEST).conf: $(SRC).conf
	@install -Dm644 $< $@

$(RULES): $(SRC)
	@mkdir -p $$(dirname $@)
	@./$(SRC) print-polkit-rules $(RULES_OPTIONS) > $@

install: $(DEST) $(DEST).conf $(TEMPLATE_RULES_DEST)

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
	@printf '  setenv PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\n'
	@echo   '  script-security 2'
	@printf '  up %s\n' $(DEST)
	@echo   '  up-restart'
	@printf '  down %s\n' $(DEST)
	@echo   '  down-pre'
	@echo
	@printf 'or pass --config %s.conf\n' $(DEST)
	@echo 'in addition to any other --config arguments to your openvpn command.'

test:
	@./run-tests
