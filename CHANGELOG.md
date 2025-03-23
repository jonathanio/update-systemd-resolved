# Changelog

## 2.0.0 (2025.03.23)

### IMPROVEMENTS

- Expose a [Nix flake](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html).
  This flake's outputs include [the `update-systemd-resolved` Nix package](/nix/packages.nix), as
  well as [the `update-systemd-resolved` NixOS module](/nix/nixos-modules.nix)
  (module docs are [here](/docs/nixos-modules.md)).
- Support additional DBus calls `ResetServerFeatures`, `ResetStatistics`,
  `DNSDefaultRoute`, `SetLinkDNSOverTLS`, `SetLinkLLMNR`,
  `SetLinkMulticastDNS`, and `SetLinkNegativeDNSSECTrustAnchors`
  ([#110](https://github.com/jonathanio/update-systemd-resolved/pull/110])).
- Check that the `org.freedesktop.resolve1` endpoint is available and
  short-circuit with an error message if not
  ([#105](https://github.com/jonathanio/update-systemd-resolved/pull/105)).
- Add a `print-polkit-rules` subcommand that generates a polkit rules
  specification allowing the specified users and/or groups to perform the DBus
  call necessary for `update-systemd-resolved`'s proper operation
  ([#100](https://github.com/jonathanio/update-systemd-resolved/pull/100)).
- Support logging without `/dev/log`/`logger`
- ([#115](https://github.com/jonathanio/update-systemd-resolved/pull/115)).
- Avoid doubled log output in the system journal (reported by @VannTen in
  [#81](https://github.com/jonathanio/update-systemd-resolved/issues/81),
  fixed in [#115](https://github.com/jonathanio/update-systemd-resolved/pull/115)).
- Improve FHS compliance by installing `update-systemd-resolved` to
  `/usr/local/bin` by default, rather than to `/usr/local/bin`
  (@bowlofeggs, [#106](https://github.com/jonathanio/update-systemd-resolved/pull/106)).
- Add links to Debian and Ubuntu packages (@perlun,
  [#112](https://github.com/jonathanio/update-systemd-resolved/pull/112)).
- Flush caches with `busctl` rather than with `resolvectl --flush-caches`
  (@cmadamsgit, [#99](https://github.com/jonathanio/update-systemd-resolved/pull/99)).

### BUG FIXES

- `update-systemd-resolved` now accepts IPv6 addresses that do not conform to
  [RFC5952](https://tools.ietf.org/html/rfc5952), rather than complaining and
  bailing out (reported in
  [#76](https://github.com/jonathanio/update-systemd-resolved/pull/76), fixed
  in [#104](https://github.com/jonathanio/update-systemd-resolved/pull/104)).

### BACKWARDS INCOMPATIBILITIES

- The use of `setenv PATH ...` in the example `update-systemd-resolved.conf`
  and elsewhere is now deprecated.  OpenVPN setups that include the example
  configuration file (`config /path/to/example/update-systemd-resolved.conf`)
  may break if they rely on this now-deprecated `PATH` definition.
- The default installation paths have changed.  `update-systemd-resolved` is
  now installed to `/usr/local/libexec/openvpn/update-systemd-resolved`,
  the example `update-systemd-resolved.conf` is installed to
  `/usr/share/doc/openvpn/update-systemd-resolved.conf`.  This reflects, among
  other things, changes to the Makefile variables that influence installation
  paths; for instance, `PREFIX` no longer includes a `/bin` component.  The
  Makefile now additionally defines and uses the variables `EXEC_PREFIX`,
  `LIBEXECDIR`, `DATAROOTDIR`, and `DATADIR`.
- `dhcp-option` invocations are now split on  whitespace (the `[[:space:]]`
  POSIX character class, to be more specific) rather than being split on single
  space characters.
- `dhcp-option` invocations without an argument (that is, `dhcp-option FOO`
  rather than, say, `dhcp-option FOO bar`) are now treated as having the empty
  string as their value; previously, they were treated as having the option
  name as their value (`dhcp-option FOO` == `dhcp-option FOO FOO`).
- `update-systemd-resolved` now requires Bash >= 4.3.
- `update-systemd-resolved` no longer uses the `emerg` log level with the
  for logging with the `logger` command, so certain messages are no longer
  broadcast to `(p|t)ty`s ([#109](https://github.com/jonathanio/update-systemd-resolved/pull/109])).

## 1.3.0 (2019.05.19)

### NOTES

A number of pull-requests and updates added, fixing some bugs and adding new
features.

### IMPROVEMENTS

- Added support for DNS6 option which can take only IPv6 addresses
  (@thecodingrobot)
- Based on some feedback by (@tbaumann), alter the handling of script_type and
  dev within the body in the main() function to allow it to work more
  effectively between the environment and command-line parameters.
- The DNS caches are now flushed when the script as made the configuration
  changes for the link (@Edu4rdSHL)
- Change the handling of DOMAIN to support multiple options, with a change in the
  way the values are processed and added to systemd-resolved (@adq)
- Updated the documentation in a number of areas, including a new section
  specifically on DNS Leakage, links to the DBus commands, NetworkManager and
  DNSSEC issues, and spelling corrections, etc. (Thanks to @bohlstry and
  @dannyk81 for the help with a script for NetworkManager)
- Now recommended using the `up-restart` option in the configuration files to
  ensure that `update-systemd-resolved` is re-run when the connection only
  partially restarts (i.e connection restarts, but not the TUN/TAP device).

### BACKWARDS INCOMPATIBILITIES

- The DOMAIN option now supports multiple calls, and rather than the last
  provided version being the primary domain for the link, the first value is the
  primary domain, and all subsequent calls are added as the equivalent of
  DOMAIN-SEARCH.

## 1.2.7 (2017.11.12)

### NOTES

Following a request by @JoshDobbin, support has been added for passing
`ADAPTER_DOMAIN_SUFFIX` via `dhcp-options` to work with the Microsoft standard.
Also included some additional notes in README.md about using `down` in dropped
privilege situations for clarification.

### IMPROVEMENTS

- Added support for ADAPTER_DOMAIN_SUFFIX (@jonathanio)
- Added notes in README.md about `down` with dropped privileges (@jonathanio)

## 1.2.6 (2017.07.24)

### NOTES

Improvements made to the `logger` command to prevent issues with privilege
dropping under the assistance of @dermarens, @terminalmage, @guruxu, and @benvh.
Updated some documentation for consistency and clarity. Thanks to @flungo and
@dawansv here.

### IMPROVEMENTS

- Updated to include a full list in PATH, including sbin paths. (@jonathanio)
- Updated documentation regarding DNS leakage. (@jonathanio)
- Updated all script locations to be consistent. (@jonathanio)
- Add some installation instructions to README.md. (@flungo)
- Update command-line parameters needed within Makefile/README.md. (@noraj1337)
- Fix script name in command-line path within README.md. (@phR0ze)

## 1.2.5 (2017.03.02)

### IMPROVEMENTS

- Updated to include a full list in PATH, including sbin paths. (@jonathanio)

## 1.2.4 (2017.03.02)

### NOTES

@piotr-dobrogost, @mgu, and @aRkadeFR helped improve the documentation.

### IMPROVEMENTS

- It was noted that the PATH setting used in the documentation doesn't work on
  all systems (sorry, my bad), so it has now been updated so it should now work.
  (@aRkadeFR)

## 1.2.3 (2016.12.25)

### NOTES

@Nauxuron provided a patch to improve DESTDIR and PREFIX handling in Makefile.

### IMPROVEMENTS

- Improve handling of DESTDIR and PREFIX in the Makefile to follow the GNU
  guidelines. (@Nauxuron)

## 1.2.2 (2016.12.13)

### NOTES

This one is a thanks to @mikken and helps support OpenVPN 2.4 as well as fix
an issue with `DNSSEC` handling on the `busctl` call.

### BUG FIXES

- The incorrect usage of `down-pre` which as of OpenVPN 2.4 is now a fatal error
  when you pass it an argument (i.e. the script we were originally thought it
  should be calling). (@mikken)
- Issues with `busctl` and bash properly handling the "empty string" case to use
  the default `DNSSEC` option. (@jonathanio)
- Noise when `busctl` is called on the down case when privileges have been
  dropped in the client. (@mikken)
- Added documentation for `allow-downgrade` support in `DNSSEC` option (which
  was supported, but not documented). (@jonathanio)

## 1.2.1 (2016.10.06)

### NOTES

Thanks for @arjenschol for spotting this one: An error in the AF_INET value
provided to SetLinkDNS prevented IPv6 DNS servers from being added.

### BUG FIXES

- Fix IPv6 DNS by specifying AF_INET6 value (10) insteadof array size (2)
  (@arjenschol)

## 1.2.0 (2016.08.29)

### NOTES

Add support for DNSSEC processing, improve logic around `DOMAIN` and
`DOMAIN-SEARCH` handling, add support for `DOMAIN-ROUTE`, and improve
documentation.

### BACKWARDS INCOMPATIBILITIES

- Due to (probably) an incorrect assumption on my part (@jonathanio) in the
  purpose of `DOMAIN-SEARCH` verses `DOMAIN`, domains added via `DOMAIN` were
  marked as searchable, and so would be appended to bare domain names, while
  those added via `DOMAIN-SEARCH` would not. This was a divergance from how
  older OpenVPN handler scripts (such as `update-resolv-conf` and
  `update-systemd-network`) processed them (i.e. in all cases they were just
  made searchable). Note that both scripts didn't really have the concept of
  `domain` in the same way as `/etc/resolv.conf` understood it. This script now
  (hopefully) properly handles `DOMAIN` and `DOMAIN-SEARCH` (single of the
  former, and is primary, multiple of the latter and secondary).

### FEATURES

- Add support for `DNSSEC` option which allows you to enable or disable (or
  leave to system default) the `DNSSEC` setting for any DNS queries made to the
  DNS servers provided for this link. (@jonathanio)
- Add support for `DOMAIN-ROUTE` which, through `systemd-resolved`, allows you
  to set domain names which should be routed over this link to the DNS servers
  provided. (@jonathanio)

### IMPROVEMENTS

- Correct the logic around the handling of `DOMAIN` and `DOMAIN-SEARCH` to be
  more compatible with previous versions of these handlers. (@jonathanio)

## 1.1.1 (2016.08.10)

### NOTES

Thanks to the help from @pid1 for this release. The documentation mistakenly
noted to use pre-down for the script now (compared to down originally, which
failed as the tun or tap device would have been removed before the script
ran). However, this should have in fact been down-pre.

### BUG FIXES

- Fix `pre-down` to `down-pre` in the documentation else you'll break your
  OpenVPN configuration. (@pid1)

## 1.1.0 (2016.08.08)

### NOTES

Thanks to the work by @BaxterStockman, the script has been refactored, hopefully
making it easier to read and follow, while additional tests around IPv6
processing have been added.

### IMPROVEMENTS

- Refactor the codebase to make it easier to read and expand. (@BaxterStockman)
- Improve run-tests so multiple tests can be run within a file, and can expect
  failures within a test. (@BaxterStockman)
- Add tests for invalid IPv6 addresses. (@BaxterStockman)

## 1.0.0 (2016.06.23)

### NOTES

First release of `update-systemd-resolved`. Should fully support the three
standard DHCP options in OpenVPN (`DNS`, `DOMAIN`, and `DOMAIN-SEARCH`) with
integration tests around the code to manage and monitor regressions. Also
supports multiple (and combined) IPv4 and IPv6 DNS addresses.
