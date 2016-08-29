## 1.2.0 (2016.08.29)

NOTES:
Add support for DNSSEC processing, improve logic around `DOMAIN` and
`DOMAIN-SEARCH` handling, add support for `DOMAIN-ROUTE`, and improve
documentation.

BACKWARDS INCOMPATIBILITIES:
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

FEATURES:
- Add support for `DNSSEC` option which allows you to enable or disable (or
  leave to system default) the `DNSSEC` setting for any DNS queries made to the
  DNS servers provided for this link. (@jonathanio)
- Add support for `DOMAIN-ROUTE` which, through `systemd-resolved`, allows you
  to set domain names which should be routed over this link to the DNS servers
  provided. (@jonathanio)

IMPROVEMENTS:
- Correct the logic around the handling of `DOMAIN` and `DOMAIN-SEARCH` to be
  more compatible with previous versions of these handlers. (@jonathanio)

BUG FIXES:
- None.

## 1.1.1 (2016.08.10)

NOTES:
Thanks to the help from @pid1 for this release. The documentation mistakenly
noted to use pre-down for the script now (compared to down originally, which
failed as the tun or tap device would have been removed before the script
ran). However, this should have in fact been down-pre.

FEATURES:
- None.

IMPROVEMENTS:
- None.

BUG FIXES:
- Fix `pre-down` to `down-pre` in the documentation else you'll break your
  OpenVPN configuration. (@pid1)

## 1.1.0 (2016.08.08)

NOTES:
Thanks to the work by @BaxterStockman, the script has been refactored, hopefully
making it easier to read and follow, while additional tests around IPv6
processing have been added.

FEATURES:
- None.

IMPROVEMENTS:
- Refactor the codebase to make it easier to read and expand. (@BaxterStockman)
- Improve run-tests so multiple tests can be run within a file, and can expect
  failures within a test. (@BaxterStockman)
- Add tests for invalid IPv6 addresses. (@BaxterStockman)

BUG FIXES:
- None.

## 1.0.0 (2016.06.23)

NOTES:
First release of `update-systemd-resolved`. Should fully support the three
standard DHCP options in OpenVPN (`DNS`, `DOMAIN`, and `DOMAIN-SEARCH`) with
integration tests around the code to manage and monitor regressions. Also
supports multiple (and combined) IPv4 and IPv6 DNS addresses.
