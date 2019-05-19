# update-systemd-resolved

[![Build Status](https://travis-ci.org/jonathanio/update-systemd-resolved.svg?branch=features%2Funit-tests)](https://travis-ci.org/jonathanio/update-systemd-resolved)

This is a helper script designed to integrate OpenVPN with the
`systemd-resolved` service via DBus instead of trying to override
`/etc/resolv.conf`, or manipulate `systemd-networkd` configuration files.

Since systemd-229, the `systemd-resolved` service has an API available via DBus
which allows directly setting the DNS configuration for a link. This script
makes use of `busctl` from systemd to send DBus messages to `systemd-resolved`
to update the DNS for the link created by OpenVPN.

*NOTE*: This is a beta script. So long as you're using OpenVPN 2.1 or greater,
iproute2, and have at least version 229 of systemd, then it should work.
Nonetheless, if you do come across problems, fork and fix, or raise an issue.
All are most welcome.

## Installation

[aur]:https://aur.archlinux.org/packages/openvpn-update-systemd-resolved/

If you are using a distribution of Linux with uses the Arch User Repository, the
simplest way to install is by using the [openvpn-update-systemd-resolved][aur]
AUR package as this will take care of any updates through your package manager.

Alternatively, the package can be manually installed by running the following:

```bash
git clone https://github.com/jonathanio/update-systemd-resolved.git
cd update-systemd-resolved
make
```

## How to Enable

Make sure that you have `systemd-resolved` enabled and running. First, make sure
that `systemd-resolved.service` is enabled and started:

```bash
systemctl enable systemd-resolved.service
systemctl start systemd-resolved.service
```

Next, you can either configure the system libraries to talk to it using NSS, or
you can override the `resolv.conf` file to use `systemd-resolved` as a stub
resolver (or both):

### NSS and nssswitch.conf

Update your `/etc/nsswitch.conf` file to look up DNS via the `resolve` service
(you may need to install the NSS library which connects libnss to
`systemd-resolved`):

```conf
# Use /etc/resolv.conf first, then fall back to systemd-resolved
hosts: files dns resolve myhostname
# Use systemd-resolved first, then fall back to /etc/resolv.conf
hosts: files resolve dns myhostname
# Don't use /etc/resolv.conf at all
hosts: files resolve myhostname
```

The changes will be applied as soon as the file is saved.

### Stub Resolver

The `systemd-resolved` service (since systemd-231) also listens on `127.0.0.53`
via the `lo` interface, providing a stub resolver which any client can call to
request DNS, whether or not it uses the system libraries to resolve DNS, and
you no longer have to worry about trying to manage your `/etc/resolv.conf`
file. This set up can be installed by linking to `stub-resolv.conf`:

```bash
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

### Usage and Ubuntu and Fedora

#### Ubuntu

[LP1685045]:https://bugs.launchpad.net/ubuntu/+source/systemd/+bug/1685045

The NSS interface for `systemd-resolved` may be deprecated and has
already been flagged for deprecation in Ubuntu (see [LP#1685045][LP1685045] for
details). In this case, you should use the Stub Resolver method now.

#### Fedora

[authselect]:https://github.com/pbrezina/authselect

Fedora 28 makes use of `authselect` to manage the NSS settings on the system.
Directly editing `nsswitch.conf` is not recommended as it may be overwritten at
any time if `authselect` is run. Proper overrides may not yet be possible - see
[pbrezina/authselect][authselect] for details. However, like Ubuntu, the [Stub
Resolver](#stub-resolver) method is recommended here too.

### OpenVPN Configuration

Finally, update your OpenVPN configuration file and set the `up` and `down`
options to point to the script, and `down-pre` to ensure that the script is run
before the device is closed:

```conf
script-security 2
setenv PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
up /etc/openvpn/scripts/update-systemd-resolved
up-restart
down /etc/openvpn/scripts/update-systemd-resolved
down-pre
```

#### up-restart

It is recommended to use `up-restart` in your configuration to ensure that
`upate-systemd-resolved` is run on restarts - where the connection is
re-established but the TUN/TAP device remained open (for example, where the
original connection has timed out and `persist-tun` is enabled). If you do not
have `persist-tun` set, or you use `ping-exit` instead of `ping-timeout`, you
most likely will not need this.

#### down/pre-down with user/group

The `down` and `down-pre` options here will not work as expected where the
`openvpn` daemon drops privileges after establishing the connection (i.e.  when
using the `user` and `group` options). This is because only the `root` user
will have the privileges required to talk to `systemd-resolved.service` over
DBus. The `openvpn-plugin-down-root.so` plug-in does provide support for
enabling the `down` script to be run as the `root` user, but this has been
known to be unreliable.

Ultimately this shouldn't affect normal operation as `systemd-resolved.service`
will remove all settings associated with the link (and therefore naturally
update `/etc/resolv.conf`, if you have it symlinked) when the TUN or TAP device
is closed. The option for `down` and `down-pre` just make this step explicit
before the device is torn down rather than implicit on the change in
environment.

### Command Line Settings

Alternatively if you don't want to edit your client configuration, you can add
the following options to your `openvpn` command:

```bash
openvpn \
  --script-security 2 \
  --setenv PATH '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' \
  --up /etc/openvpn/scripts/update-systemd-resolved --up-restart \
  --down /etc/openvpn/scripts/update-systemd-resolved --down-pre
```

Or, you can add the following argument to the command-line arguments of
`openvpn`, which will use the `update-systemd-resolve.conf` file instead:

```bash
openvpn \
  --config /etc/openvpn/scripts/update-systemd-resolved.conf
```

## Usage

`update-systemd-resolved` works by processing the `dhcp-option` commands set in
OpenVPN, either through the server, or the client, configuration:

[resolved]:https://www.freedesktop.org/wiki/Software/systemd/resolved/

| Option | Examples | Notes | DBus Call |
|--:|---|---|---|
| `DNS` | `0.0.0.0`<br />`::1` | This sets the DNS servers for the link and can take any IPv4 or IPv6 address. | [SetLinkDNS][resolved] |
| `DNS6` | `::1` | This sets the DNS servers for the link and can take only IPv6 addresses. | [SetLinkDNS][resolved] |
| `DOMAIN` or `ADAPTER_DOMAIN_SUFFIX` | `example.com` | The primary domain for this host. If set multiple times, the first provided is used as the primary search domain for bare hostnames. Any subsequent `DOMAIN` options will be added as the equivalent of `DOMAIN-SEARCH` options. All requests for this domain as well will be routed to the `DNS` servers provided on this link. | [SetLinkDomains][resolved] |
| `DOMAIN-SEARCH` | `example.com` | Secondary domains which will be used to search for bare hostnames (after any `DOMAIN`, if set) and in the order provided. All requests for this domain will be routed to the `DNS` servers provided on this link. | [SetLinkDomains][resolved] |
| `DOMAIN-ROUTE` | `example.com` | All requests for these domains will be routed to the `DNS` servers provided on this link. They will *not* be used to search for bare hostnames, only routed. A `DOMAIN-ROUTE` option for `.` (single period) will instruct `systemd-resolved` to route the entire DNS name-space through to the `DNS` servers configured for this connection (unless a more specific route has been offered by another connection for a selected name/name-space). This is useful if you wish to prevent [DNS leakage](#dns-leakage). | [SetLinkDomains][resolved] |
| `DNSSEC` | `yes`</br >`default` | Control of DNSSEC should be enabled (`yes`) or disabled (`no`), or `allow-downgrade` to switch off DNSSEC only if the server doesn't support it, for any queries over this link only, or use the system default (`default`). | [SetLinkDNSSEC][resolved] |

**Note**: There are no local or system options to be configured. All configuration
for this script is handled through OpenVPN, including, for example, the name of
the interface to be configured.

### Example

```conf
push "dhcp-option DNS 10.62.3.2"
push "dhcp-option DNS 10.62.3.3"
push "dhcp-option DNS6 2001:db8::a3:c15c:b56e:619a"
push "dhcp-option DNS6 2001:db8::a3:ffec:f61c:2e06"
push "dhcp-option DOMAIN example.office"
push "dhcp-option DOMAIN example.lan"
push "dhcp-option DOMAIN-SEARCH example.com"
push "dhcp-option DOMAIN-ROUTE example.net"
push "dhcp-option DOMAIN-ROUTE example.org"
push "dhcp-option DNSSEC yes"
```

This, added to the OpenVPN server's configuration file will set two IPv4 DNS
servers and two IPv6 and will set the primary domain for the link to be
`example.office`. Therefore if you try to look up the bare address `mail` then
`mail.example.office` will be attempted first. The domains `example.lan` and
`example.com` are also added as an additional search domain, so if
`mail.example.office` fails, then `mail.example.lan` will be tried next,
followed by `mail.example.com`.

Requests for `example.net` and `example.org` will also be routed through to the
four DNS servers listed, but they will *not* be appended (i.e.
`mail.example.net` will not be attempted, nor `mail.example.org`, if
`mail.example.office` or `mail.example.com` do not exist).

Finally, DNSSEC has been enabled for this link (and this link only).

## DNS Leakage

DNS Leakage is something to be careful of when using any VPN or untrusted
network, and it can heavily depend on how you configure your normal DNS
settings as well as how you configure the DNS on your VPN connection.

By default, `systemd-resolved` will send **all** DNS queries to at least one
DNS server on **every** link configured with DNS servers. The first to reply
back with a valid query is the one returned to the client, and the last to
return back a failure (assuming all other queries also failed) will also be
returned to the client.

The changes in this handling come in when you start using the `DOMAIN`,
`DOMAIN-SEARCH` and `DOMAIN-ROUTE` options.  The three differ in how domains
are treated for searching bare domains, but all three work exactly the same
when it comes to how it routes domains to specific DNS servers.

Any domain added using `DOMAIN`, `DOMAIN-SEARCH`, or `DOMAIN-ROUTE` will be
added explicitly to the VPN link and therefore any queries for domain suffixes
which match these will be routed through this link, and only this link.  Any
other domains which do not match these will revert back to distributing the
queries across all links.

There are two ways to override this:

### Preventing Leakage in on untrusted networks

If you want to prevent DNS queries leaking over untrusted networks (for
example, over public WiFi hotspots), then you need to tell `systemd-resolved`
to send **all** DNS queries over the VPN link. To do this, add the following to
your server or client VPN configurations respectively:

```
# Server Configuration
push "dhcp-option DOMAIN-ROUTE ."
```

```
# Client Configuration
dhcp-option DOMAIN-ROUTE .
```

All DNS queries (which do not match a more explicit entry on another link) will
now be routed over the VPN only.

### Preventing Leakage to Corporate networks

In an alternate situation, you may want to have DNS queries specifically routed
over the VPN for corporate or private network access, but you don't want your
general DNS queries to be visible to anyone who has access to the logs of the
corporate DNS servers.

This option cannot be directly managed by `update-systemd-resolved` as you need
to configure the network settings of other links to send all queries by default
to your nominated DNS server (e.g. over `ens0` or `wlp2s0` for your Ethernet or
Wireless network cards). This needs to be configured under the `[Network]`
section of your `.network` file for your interface in `/etc/systemd/network`.
For example:

```
[Network]
DHCP=yes
DNS=8.8.8.8
DNS=8.8.4.4
Domains=.
```

When you connect, all domains except those explicitly listed using the `DOMAIN`,
`DOMAIN-SEARCH`, or `DOMAIN-ROUTE` options of your VPN link will be sent to the
DNS server of your nominated link.

### Concurrent Configuration

Note that these two options are mutually exclusive, as if you establish a VPN
link with `DOMAIN-ROUTE` set to `.` while you have also configured it inside a
`.network` file via `systemd-networkd`, then you will have two links
responsible for routing all queries, and so both links will get all requests.

How to manage the DNS settings of other links while the VPN is operational is
outside the scope of this script at this time.

## Known Issues

There are a number of known issues relating to some third-party servers and
services:

### NetworkManager

LP1671606:https://bugs.launchpad.net/ubuntu/+source/network-manager/+bug/1671606
LP1688018:https://bugs.launchpad.net/ubuntu/+source/network-manager/+bug/1688018

There is currently a regression with versions of NetworkManager 1.2.6 or later
(see [LP#1671606][LP1671606] and [LP#1688018][LP1688018]) which means that it
will automatically set all normal network interfaces with `~.` for DNS routing.
This means that even if you set `dhcp-option DOMAIN-ROUTE .` for your VPN
connection, you will still leak DNS queries over potentially insecure networks.

issue-59:https://github.com/jonathanio/update-systemd-resolved/issues/59

If you are concerned by potentially leaking DNS on systems which use
NetworkManager, you may need to configure an [additional script][issue-59]
into NetworkManager which change the domain routing settings on all non-VPN
interfaces.

### DNSSEC Issues

```shell
$ systemd-resolve eu-central-1.console.aws.amazon.com
eu-central-1.console.aws.amazon.com: resolve call failed: DNSSEC validation failed: no-signature
# or
$ systemd-resolve eu-central-1.console.aws.amazon.com
eu-central-1.console.aws.amazon.com: resolve call failed: DNSSEC validation failed: incompatible-server
```

If you are seeing failed queries in your logs due to DNSSEC issues, support may be
partially or fully enabled and you are now working with a server which does not
support this extension. You may therefore need to set `DNSSEC` to `no` (or
maybe just `allow-downgrade`) in your VPN configuration.

```
dhcp-option DNSSEC allow-downgrade
```

## How to help

If you can help with any of these areas, or have bug fixes, please fork and
raise a Pull Request for me.

I have built a basic test framework around the script which can be used to
monitor and validate the calls made by the script based on the environment
variables available to it at run-time. Please add a test for any new features
you may wish to add, or update any which are wrong, and test your code by
running `./run-tests` from the root of the repository. There are no dependencies
on `run-tests` - it runs 100% bash and doesn't call out to any other program or
language.

TravisCI is enabled on this repository: Click the link at the top of this README
to see the current state of the code and its tests.

## Licence

GPL

## Author

Jonathan Wright <jon@than.io>
