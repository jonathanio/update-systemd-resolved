# update-systemd-resolved

[![Build Status](https://travis-ci.org/jonathanio/update-systemd-resolved.svg?branch=features%2Funit-tests)](https://travis-ci.org/jonathanio/update-systemd-resolved)

This is a helper script designed to integrate OpenVPN with the `systemd-resolved`
service via DBus instead of trying to override `/etc/resolv.conf`, or manipulate
`systemd-networkd` configuration files.

Since systemd-229, the `systemd-resolved` service has an API available via
DBus which allows directly setting the DNS configuration for a link. This script
makes use of `busctl` from systemd to send DBus messages to `systemd-resolved`
to update the DNS for the link created by OpenVPN.

*NOTE*: This is an beta script. So long as you're using OpenVPN 2.1 or greater,
iproute2, and have at least version 229 of systemd, then it should work.
Nonetheless, if you do come across problems, fork and fix, or raise an issue.
All are most welcome.

## Installation

If you are using a distribution of Linux with access to the Arch User Repository,
the simplest way to install is by using the
[openvpn-update-systemd-resolved](https://aur.archlinux.org/packages/openvpn-update-systemd-resolved/)
AUR package as this will take care of any updates through your package manager.

Alternatively, the package can be manually installed by running the following:

```
git clone https://github.com/jonathanio/update-systemd-resolved.git
cd update-systemd-resolved
make
```

## How to Enable

Make sure that you have `systemd-resolved` enabled and running:

```
systemctl enable systemd-resolved.service
systemctl start systemd-resolved.service
```

Then update your `/etc/nsswitch.conf` file to look up DNS via the `resolve`
service:

```
# Use /etc/resolv.conf first, then fall back to systemd-resolved
hosts: files dns resolve myhostname
# Use systemd-resolved first, then fall back to /etc/resolv.conf
hosts: files resolve dns myhostname
# Don't use /etc/resolv.conf at all
hosts: files resolve myhostname
```

*Note*: If you intend on using this script, the latter two are preferred
otherwise the configuration provided by this script will only work on domains
that cannot be resolved by the currently configured DNS servers (i.e. they must
fall back after trying the ones set by your LAN's DHCP server).

Finally, update your OpenVPN configuration file and set the `up` and `down`
options to point to the script, and `down-pre` to ensure that the script is run
before the device is closed:

```
script-security 2
setenv PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
up /etc/openvpn/scripts/update-systemd-resolved
down /etc/openvpn/scripts/update-systemd-resolved
down-pre
```

Alternatively if you don't want to edit your client configuration, you can add
the following options to your openvpn command:

```
openvpn \
  --script-security 2 \
  --setenv PATH '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' \
  --up /etc/openvpn/scripts/update-systemd-resolved \
  --down /etc/openvpn/scripts/update-systemd-resolved \
  --down-pre
```

## Usage

`update-systemd-resolved` works by processing the `dhcp-option` commands set in
OpenVPN, either through the server, or the client, configuration:

| Option | Examples | Notes |
|--:|---|---|
| `DNS` | `0.0.0.0`<br />`::1` | This sets the DNS servers for the link and can take any IPv4 or IPv6 address. |
| `DOMAIN` or `ADAPTER_DOMAIN_SUFFIX` | `example.com` | The primary domain for this host. If set multiple times, the last provided is used. Will be the primary search domain for bare hostnames. All requests for this domain as well will be routed to the `DNS` servers provided on this link. |
| `DOMAIN-SEARCH` | `example.com` | Secondary domains which will be used to search for bare hostnames (after any `DOMAIN`, if set) and in the order provided. All requests for this domain will be routed to the `DNS` servers provided on this link. |
| `DOMAIN-ROUTE` | `example.com` | All requests for these domains will be routed to the `DNS` servers provided on this link. They will *not* be used to search for bare hostnames, only routed. A `DOMAIN-ROUTE` option for `.` (single period) will instruct `systemd-resolved` to route the entire namespace through to the `DNS` servers configured for this connection (unless a more specifc route has been offered by another connection for a selected name/namespace). This is useful if you wish to prevent DNS leakage. |
| `DNSSEC` | `yes`<br />`no`</br >`allow-downgrade`</br >`default` | Control of DNSSEC should be enabled (`yes`) or disabled (`no`), or `allow-downgrade` to switch off DNSSEC only if the server doesn't support it, for any queries over this link only, or use the system default (`default`). |

*Note*: There are no local or system options to be configured. All configuration
for this script is handled though OpenVPN, including, for example, the name of
the interface to be configured.

### Example

```
push "dhcp-option DNS 10.62.3.2"
push "dhcp-option DNS 10.62.3.3"
push "dhcp-option DNS 2001:db8::a3:c15c:b56e:619a"
push "dhcp-option DNS 2001:db8::a3:ffec:f61c:2e06"
push "dhcp-option DOMAIN example.office"
push "dhcp-option DOMAIN-SEARCH example.com"
push "dhcp-option DOMAIN-ROUTE example.net"
push "dhcp-option DOMAIN-ROUTE example.org"
push "dhcp-option DNSSEC yes"
```

This, added to the OpenVPN server's configuration file will set two IPv4 DNS
servers and two IPv6 and will set the primary domain for the link to be
`example.office`. Therefore if you try to look up the bare address `mail` then
`mail.example.office` will be attempted first. The domain `example.com` is also
added as an additional search domain, so if `mail.example.office` fails, then
`mail.example.com` will be tried next.

Requests for `example.net` and `example.org` will also be routed though to the
four DNS servers listed too, but they will *not* be appended (i.e.
`mail.example.net` will not be attempted, nor `mail.example.org` if
`mail.example.office` or `mail.example.com` do not exist).

Finally, DNSSEC has been enabled for this link (and this link only).

## How to help

If you can help with any of these areas, or have bug fixes, please fork and
raise a Pull Request for me.

I have built a basic test framework around the script which can be used to
monitor and validate the calls made by the script based on the environment
variables available to it at run-time. Please add a test for any new features
you may wish to add, or update any which are wrong, and test your code by
running `./run-tests` from the root of the repository. There are no dependencies
on `run-tests` - it runs 100% bash and doesn't call out ot any other program or
langauge.

TravisCI is enabled on this repository: Click the link at the top of this README
to see the current state of the code and its tests.

## Licence

GPL

## Author

Jonathan Wright <jon@than.io>
