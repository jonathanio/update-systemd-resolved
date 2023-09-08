# update-systemd-resolved

[![Build Status](https://github.com/jonathanio/update-systemd-resolved/actions/workflows/test.yml/badge.svg)](https://github.com/jonathanio/update-systemd-resolved/actions)

This is a helper script designed to integrate OpenVPN with the
`systemd-resolved` service via DBus instead of trying to override
`/etc/resolv.conf`, or manipulate `systemd-networkd` configuration files.

Since systemd-229, the `systemd-resolved` service has an API available via DBus
which allows directly setting the DNS configuration for a link. This script
makes use of `busctl` from systemd to send DBus messages to `systemd-resolved`
to update the DNS for the link created by OpenVPN.

## NetworkManager

[nm-helper]:https://git.launchpad.net/ubuntu/+source/network-manager-openvpn/tree/src/nm-openvpn-service-openvpn-helper.c?h=debian/sid

This script may not be compatible with certain versions of NetworkManager. It
seems that NetworkManager overrides the `up` command to use its own helper
script ([nm-openvpn-service-openvpn-helper][nm-helper]). The script that ships
with NetworkManager only supports `DNS` and `DOMAIN` options (not `DNS6`,
`DOMAIN-SEARCH` and `DOMAIN-ROUTE`, nor `DNSSEC` overrides). It will also set
the main network interface to route `~.` DNS queries (i.e the whole name-space)
to the LAN or ISP DNS servers, making it difficult to override using `DOMAIN` -
see [DNS Leakage](#dns-leakage) below.

## Prerequisites

This script requires:

- Bash 4.3 or above.
- [coreutils](https://www.gnu.org/software/coreutils/) or
  [busybox](https://www.busybox.net/) (for the `id` command).
- [iproute2](https://wiki.linuxfoundation.org/networking/iproute2) (for the
  `ip` command).
- [systemd](https://systemd.io/) (for the `busctl` and `resolvectl` commands).

Optional dependencies:

### IP Parsing and Validation

- [`python`](https://python.org), **or**
- [`sipcalc`](https://github.com/sii/sipcalc).

If available, these will be used for IP address parsing and
validation;[^iphandling] otherwise `update-systemd-resolved` will use native
Bash routines for this.

[^iphandling]: Required for translating numerical labels like `1.2.3.4` to the
               byte arrays recognized by [the `SetLinkDNS()` function on
               `systemd-resolved`'s `org.freedesktop.resolve1.Manager` D-Bus
               interface][resolved]).

### Logging

- [util-linux](https://en.wikipedia.org/wiki/Util-linux)

If available, the `logger` command included in the `util-linux` distribution
will be used for logging.  Otherwise, all logs will go to standard error using
Bash's `printf` builtin.

### Polkit Rules Generation

- [`jq`](https://jqlang.github.io/jq/), **or**
- [`perl`](https://www.perl.org/), **or**
- [`python`](https://python.org).

If available, these will be used for serializing the [names of the users and
groups allowed to call `systemd-resolved`'s DBus methods](#polkit-rules) to
JSON lists for use within the [generated polkit
rules](#generating-polkit-rules).  Otherwise, `update-systemd-resolved` will
fall back to native Bash routines for generating these lists.

## Installation

[aur]:https://aur.archlinux.org/packages/openvpn-update-systemd-resolved/

If you are using a distribution of Linux with uses the Arch User Repository, the
simplest way to install is by using the [openvpn-update-systemd-resolved][aur]
AUR package as this will take care of any updates through your package manager.
[Debian](https://packages.debian.org/openvpn-systemd-resolved) and
[Ubuntu](https://packages.ubuntu.com/openvpn-systemd-resolved) also provide a
`.deb` package in their distributions.

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

### Polkit Rules

If you run the OpenVPN client as an unprivileged user, you may need to add
polkit rules authorizing that user to perform the various DBus calls that
`update-systemd-resolved` makes.  Some installation methods bundle these rules;
for instance, on Arch Linux, where `openvpn-client@<name>.service` instances
run as the unprivileged `openvpn` user, the
[openvpn-update-systemd-resolved][aur] AUR package ships suitable rules in the
file `/etc/polkit-1/rules.d/10-update-systemd-resolved.rules`.

#### Generating Polkit Rules

> **Note**
> `update-systemd-resolved` strives to generate polkit rules with the smallest
> scope consistent with its proper functioning.  Nonetheless, in order to avoid
> security risks, you are encouraged to review the generated polkit rules
> before installing them.

You can also generate suitable rules with (some variation on) the following
commands:

```shell-session
$ update-systemd-resolved print-polkit-rules --polkit-allowed-user some-user --polkit-allowed-user another-user > ./10-custom-update-systemd-resolved.rules
$ sudo install -Dm0640 ./10-custom-update-systemd-resolved.rules /etc/polkit-1/rules.d/10-custom-update-systemd-resolved.rules
```

This will allow `update-systemd-resolved` to successfully make its DBus calls
when invoked from OpenVPN client services that run as the users `some-user` or
`another-user`.

You can also authorize members of specified groups with:

```shell-session
$ update-systemd-resolved print-polkit-rules --polkit-allowed-group some-group --polkit-allowed-group another-group > ./10-custom-update-systemd-resolved.rules
$ sudo install -Dm0640 ./10-custom-update-systemd-resolved.rules /etc/polkit-1/rules.d/10-custom-update-systemd-resolved.rules
```

This will allow `update-systemd-resolved` to successfully make its DBus calls
when invoked from OpenVPN client services that run under the groups
`some-group` or `another-group`.

Finally, you can generate rules that pull appropriate user and group values
from OpenVPN systemd units with:

```shell-session
$ update-systemd-resolved print-polkit-rules --polkit-systemd-openvpn-unit my-openvpn-client.service
$ sudo install -Dm0640 ./10-custom-update-systemd-resolved.rules /etc/polkit-1/rules.d/10-custom-update-systemd-resolved.rules
```

Given:

```shell-session
$ systemctl show -P User my-openvpn-client.service
myuser
$ systemctl show -P Group my-openvpn-client.service
mygroup
```

The generated `10-custom-update-systemd-resolved.rules` file will contain rules
allowing the `myuser` user and members of the `mygroup` group to perform the
requisite DBus calls.

You can run `update-systemd-resolved print-polkit-rules` with any combination
of `--polkit-allowed-user`, `--polkit-allowed-group`, and
`--polkit-systemd-openvpn-unit`.  If called without options,
`update-systemd-resolved print-polkit-rules` will attempt to derive appropriate
user and group authorizations from a systemd OpenVPN unit matching
`openvpn-client@.service`, the [systemd service
template](https://www.freedesktop.org/software/systemd/man/systemd.service.html#Service%20Templates)
used for OpenVPN client services on distributions including Arch Linux.

### Stub Resolver

The `systemd-resolved` service (since systemd-231) also listens on `127.0.0.53`
via the `lo` interface, providing a stub resolver which any client can call to
request DNS, whether or not it uses the system libraries to resolve DNS, and
you no longer have to worry about trying to manage your `/etc/resolv.conf`
file. This set up can be installed by linking to `stub-resolv.conf`:

```bash
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

### OpenVPN Configuration

Finally, update your OpenVPN configuration file and set the `up` and `down`
options to point to the script, and `down-pre` to ensure that the script is run
before the device is closed:

```conf
script-security 2
setenv PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
up /usr/local/bin/update-systemd-resolved
up-restart
down /usr/local/bin/update-systemd-resolved
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

The `down` and `down-pre` options here may not work as expected where the
`openvpn` daemon drops privileges after establishing the connection (i.e.  when
using the `user` and `group` options). This is because, by default, only the
`root` user will have the privileges required to talk to
`systemd-resolved.service` over DBus. The `openvpn-plugin-down-root.so` plug-in
does provide support for enabling the `down` script to be run as the `root`
user, but this has been known to be unreliable.

You can authorize unprivileged users or groups to revert the OpenVPN link's DNS
settings during the "down" phase using the methods described in the ["Polkit
Rules" section](#polkit-rules).

Ultimately, dropping privileges shouldn't affect normal "down" operation, since
`systemd-resolved.service` will remove all settings associated with the link
(and therefore naturally update `/etc/resolv.conf`, if you have it symlinked)
when the TUN or TAP device is closed. The option for `down` and `down-pre` just
make this step explicit before the device is torn down rather than implicit on
the change in environment.

### Command Line Settings

Alternatively if you don't want to edit your client configuration, you can add
the following options to your `openvpn` command:

```bash
openvpn \
  --script-security 2 \
  --setenv PATH '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' \
  --up /usr/local/bin/update-systemd-resolved --up-restart \
  --down /usr/local/bin/update-systemd-resolved --down-pre
```

Or, you can add the following argument to the command-line arguments of
`openvpn`, which will use the `update-systemd-resolve.conf` file instead:

```bash
openvpn \
  --config /usr/local/bin/update-systemd-resolved.conf
```

## :screwdriver: Usage :wrench:

`update-systemd-resolved` works by processing the `dhcp-option` commands set in
OpenVPN, either through the server, or the client, configuration.  **Note**
that there are no local or system options to be configured. All configuration
for this script is handled through OpenVPN, including, for example, the name of
the interface to be configured.

### :level_slider: Options :control_knobs:

[resolved]:https://www.freedesktop.org/software/systemd/man/org.freedesktop.resolve1.html

#### :gear: `DNS`

<details>

<summary>Setting DNS servers</summary>

##### Examples

- `0.0.0.0`
- `0.0.0.0:5353`
- `0.0.0.0#my.resolver.net`
- `0.0.0.0:5353#my.resolver.net`
- `::1`
- `[::1]:5353`
- `::1#my.resolver.net`
- `[::1]:5353#my.resolver.net`

##### Description

This sets the DNS servers for the link and can take any IPv4 or IPv6 address.

##### DBus call

[SetLinkDNS][resolved], [SetLinkDNSEx][resolved]

</details>

#### :gear: `DNS6`

<details>

<summary>Setting IPv6-only DNS servers</summary>

##### Examples

- `::1`
- `[::1]:5353`
- `::1#my.resolver.net`
- `[::1]:5353#my.resolver.net`

##### Description

This sets the DNS servers for the link and can take only IPv6 addresses.

##### DBus call

[SetLinkDNS][resolved], [SetLinkDNSEx][resolved]

</details>

#### :gear: `DOMAIN` or `ADAPTER_DOMAIN_SUFFIX`

<details>

<summary>Setting the primary domain</summary>

##### Examples

- `example.com`

##### Description

The primary domain for this host. If set multiple times, the first provided is
used as the primary search domain for bare hostnames. Any subsequent `DOMAIN`
options will be added as the equivalent of `DOMAIN-SEARCH` options. All
requests for this domain as well will be routed to the `DNS` servers provided
on this link.

##### DBus call

[SetLinkDomains][resolved]

</details>

#### :gear: `DOMAIN-SEARCH`

<details>

<summary>Setting secondary domains</summary>

##### Examples

- `example.com`

##### Description

Secondary domains which will be used to search for bare hostnames (after any
`DOMAIN`, if set) and in the order provided. All requests for this domain will
be routed to the `DNS` servers provided on this link.

##### DBus call

[SetLinkDomains][resolved]

</details>

#### :gear: `DOMAIN-ROUTE`

<details>

<summary>Routing DNS queries</summary>

##### Examples

- `example.com`

##### Description

All requests for these domains will be routed to the `DNS` servers provided on
this link. They will *not* be used to search for bare hostnames, only routed. A
`DOMAIN-ROUTE` option for `.` (single period) will instruct `systemd-resolved`
to route the entire DNS name-space through to the `DNS` servers configured for
this connection (unless a more specific route has been offered by another
connection for a selected name/name-space). This is useful if you wish to
prevent [DNS leakage](#dns-leakage).

##### DBus call

[SetLinkDomains][resolved]

</details>

#### :gear: `DNSSEC`

<details>

<summary>Enabling DNSSEC</summary>

##### Examples

- `yes`, `true`
- `no`, `false`
- `default`
- `allow-downgrade`

##### Description

Control of DNSSEC should be enabled (`yes`, `true`) or disabled (`no`,
`false`), or `allow-downgrade` to switch off DNSSEC only if the server doesn't
support it, for any queries over this link only, or use the system default
(`default`).

##### DBus call

[DNSSEC][resolved]

</details>

#### :gear: `FLUSH-CACHES`

<details>

<summary>Flushing DNS caches</summary>

##### Examples

- `yes`, `true`
- `no`, `false`

##### Description

Whether or not to flush all local DNS caches.  Enabled by default.

##### DBus call

[FlushCaches][resolved]

</details>

#### :gear: `RESET-SERVER-FEATURES`

<details>

<summary>Resetting learnt DNS server feature levels</summary>

##### Examples

- `yes`, `true`
- `no`, `false`

##### Description

Whether or not to forget learnt DNS server feature levels.

##### DBus call

[ResetServerFeatures][resolved]

</details>

#### :gear: `RESET-STATISTICS`

<details>

<summary>Resetting resolver statistics</summary>

##### Examples

- `yes`, `true`
- `no`, `false`

##### Description

Whether or not to reset resolver statistics.

##### DBus call

[ResetStatistics][resolved]

</details>

#### :gear: `DEFAULT-ROUTE`

<details>

<summary>Default DNS query routing</summary>

##### Examples

- `yes`, `true`
- `no`, `false`

##### Description

If true, this link's configured DNS servers are used for resolving domain names
that do not match any link's configured `Domains=` setting. If false, this
link's configured DNS servers are never used for such domains, and are
exclusively used for resolving names that match at least one of the domains
configured on this link.

##### DBus call

[DNSDefaultRoute][resolved]

</details>

#### :gear: `DNS-OVER-TLS`

<details>

<summary>Enabling DNS-over-TLS</summary>

##### Examples

- `yes`, `true`
- `no`, `false` • `opportunistic` • `default`

##### Description

If true all connections to the server will be encrypted. Note that this mode
requires a DNS server that supports DNS-over-TLS and has a valid certificate.
If the hostname was specified in `DNS=` by using the format
`address#server_name` it is used to validate its certificate and also to enable
Server Name Indication (SNI) when opening a TLS connection. Otherwise the
certificate is checked against the server's IP. If the DNS server does not
support DNS-over-TLS all DNS requests will fail. When set to `opportunistic`
DNS request are attempted to send encrypted with DNS-over-TLS. If the DNS
server does not support TLS, DNS-over-TLS is disabled. Note that this mode
makes DNS-over-TLS vulnerable to "downgrade" attacks, where an attacker might
be able to trigger a downgrade to non-encrypted mode by synthesizing a response
that suggests DNS-over-TLS was not supported. If set to false, DNS lookups are
send over UDP. If set to `default`, uses the system default.

##### DBus call

[SetLinkDNSOverTLS][resolved]

</details>

#### :gear: `LLMNR`

<details>

<summary>Enabling Link-Local Multicast Name Resolution</summary>

##### Examples

- `yes`, `true`
- `no`, `false` • `resolve` • `default`

##### Description

When true, enables Link-Local Multicast Name Resolution on the link. When set
to `resolve`, only resolution is enabled, but not host registration and
announcement. If set to `default`, uses the system default.

##### DBus call

[SetLinkLLMNR][resolved]

</details>

#### :gear: `MULTICAST-DNS`

<details>

<summary>Enabling Multicast DNS</summary>

##### Examples

- `yes`, `true`
- `no`, `false` • `resolve` • `default`

##### Description

When true, enables Multicast DNS support on the link. When set to `resolve`,
only resolution is enabled, but not host or service registration and
announcement. If set to `default`, uses the system default.

##### DBus call

[SetLinkMulticastDNS][resolved]

</details>

#### :gear: `DNSSEC-NEGATIVE-TRUST-ANCHORS`

<details>

<summary>Configuring DNSSEC Negative Trust Anchors</summary>

##### Examples

- `trusted.org`

##### Description

If specified and DNSSEC is enabled, look-ups done via the interface's DNS
server will be subject to the list of negative trust anchors, and not require
authentication for the specified domains, or anything below it. Use this to
disable DNSSEC authentication for specific private domains, that cannot be
proven valid using the Internet DNS hierarchy. By default,
`update-systemd-resolved` does not set any negative trust anchors.

##### DBus call

[SetLinkDNSSECNegativeTrustAnchors][resolved]

</details>

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

[resolved-vpns]: https://systemd.io/RESOLVED-VPNS

> **Note**
> Required reading: [`systemd-resolved.service` and VPNs][resolved-vpns].  This
> document includes, among other things, an overview of search domains, routing
> domains, and `systemd-resolved`'s `default-route` boolean.  Understanding
> these concepts will help you configure your local `systemd-resolved` instance
> to ensure that DNS queries go where you want them to go.

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

[LP1671606]:https://bugs.launchpad.net/ubuntu/+source/network-manager/+bug/1671606
[LP1688018]:https://bugs.launchpad.net/ubuntu/+source/network-manager/+bug/1688018

There is a regression with versions of NetworkManager 1.2.6 through 1.26.4 (see
[LP#1671606][LP1671606] and [LP#1688018][LP1688018]) which means that it will
automatically set all normal network interfaces with `~.` for DNS routing.
This means that even if you set `dhcp-option DOMAIN-ROUTE .` for your VPN
connection, you will still leak DNS queries over potentially insecure networks.

[issue-59]:https://github.com/jonathanio/update-systemd-resolved/issues/59

If you are concerned by potentially leaking DNS on systems which use
NetworkManager, you may need to configure an [additional script][issue-59]
into NetworkManager which change the domain routing settings on all non-VPN
interfaces.

[fix-1.26.6]:https://gitlab.freedesktop.org/NetworkManager/NetworkManager/-/blob/nm-1-26/NEWS#L23-24

This issue was [fixed in NetworkManager version 1.26.6][fix-1.26.6]; now,
NetworkManager only enables the `DefaultRoute` option on managed interfaces.

### DNSSEC Issues

```shell
$ resolvectl query eu-central-1.console.aws.amazon.com
eu-central-1.console.aws.amazon.com: resolve call failed: DNSSEC validation failed: no-signature
# or
$ resolvectl query eu-central-1.console.aws.amazon.com
eu-central-1.console.aws.amazon.com: resolve call failed: DNSSEC validation failed: incompatible-server
```

If you are seeing failed queries in your logs due to DNSSEC issues, support may be
partially or fully enabled and you are now working with a server which does not
support this extension. You may therefore need to set `DNSSEC` to `no` (or
maybe just `allow-downgrade`) in your VPN configuration.

```
dhcp-option DNSSEC allow-downgrade
```

### Issues with Ubuntu and Fedora

#### Ubuntu

[LP1685045]:https://bugs.launchpad.net/ubuntu/+source/systemd/+bug/1685045

The NSS interface for `systemd-resolved` may be deprecated and has already been
flagged for deprecation in Ubuntu (see [LP#1685045][LP1685045] for details). In
this case, you should use the [Stub Resolver](#stub-resolver) method now.

#### Fedora

[authselect]:https://github.com/authselect/authselect

Fedora 28 makes use of `authselect` to manage the NSS settings on the system.
Directly editing `nsswitch.conf` is not recommended as it may be overwritten at
any time if `authselect` is run. Proper overrides may not yet be possible - see
[the authselect project repository][authselect] for details. However, like
Ubuntu, the [Stub Resolver](#stub-resolver) method is recommended here too.

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

GitHub Actions are enabled on this repository: Click the link at the top of this
README to see the current state of the code and its tests.

## Development notes

Please see [`HACKING.md`](./HACKING.md) for notes on developing
`update-systemd-resolved`.

## Licence

GPL

## Author

Jonathan Wright <jon@than.io>
