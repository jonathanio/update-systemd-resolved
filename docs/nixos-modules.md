## programs\.update-systemd-resolved\.package

The update-systemd-resolved package to use\.



*Type:*
package



*Default:*
` pkgs.update-systemd-resolved `

*Declared by:*
 - [nix/nixos-modules\.nix](/nix/nixos-modules.nix)



## programs\.update-systemd-resolved\.servers



Attribute set of ` update-systemd-resolved ` configurations\.
Intended to be included in
` services.openvpn.servers.<name>.config ` entries\.



*Type:*
attribute set of (submodule)



*Default:*
` { } `

*Declared by:*
 - [nix/nixos-modules\.nix](/nix/nixos-modules.nix)



## programs\.update-systemd-resolved\.servers\.\<name>\.config



The configuration text for inclusion in
` services.openvpn.servers.<name>.config `\.



*Type:*
strings concatenated with “\\n” *(read only)*

*Declared by:*
 - [nix/nixos-modules\.nix](/nix/nixos-modules.nix)



## programs\.update-systemd-resolved\.servers\.\<name>\.configFile



A configuration file containing
` programs.update-systemd-resolved.servers.<name>.config `
for inclusion in ` services.openvpn.servers.<name>.config `
via the ` config ` directive\.



*Type:*
path *(read only)*



*Default:*
` <derivation update-systemd-resolved--name-.conf> `

*Declared by:*
 - [nix/nixos-modules\.nix](/nix/nixos-modules.nix)



## programs\.update-systemd-resolved\.servers\.\<name>\.includeAutomatically



Whether to include the generated configuration in
` services.openvpn.servers.<name>.config `\.



*Type:*
boolean



*Default:*
` false `

*Declared by:*
 - [nix/nixos-modules\.nix](/nix/nixos-modules.nix)



## programs\.update-systemd-resolved\.servers\.\<name>\.openvpnServerName



` <name> ` in
` services.openvpn.servers.<name>.config `\.



*Type:*
string



*Default:*
` "‹name›" `

*Declared by:*
 - [nix/nixos-modules\.nix](/nix/nixos-modules.nix)



## programs\.update-systemd-resolved\.servers\.\<name>\.pushSettings



Whether to push ` update-system-resolved `
settings with OpenVPN’s ` push ` directive\.
Enable this if the target OpenVPN instance is a server;
disable it if the target instance is a client\.



*Type:*
boolean



*Default:*
` false `

*Declared by:*
 - [nix/nixos-modules\.nix](/nix/nixos-modules.nix)



## programs\.update-systemd-resolved\.servers\.\<name>\.settings



DNS-related settings for this VPN’s link\.



*Type:*
submodule



*Default:*
` { } `

*Declared by:*
 - [nix/nixos-modules\.nix](/nix/nixos-modules.nix)



## programs\.update-systemd-resolved\.servers\.\<name>\.settings\.defaultRoute



Whether to use the DNS servers configured for
this link to resolve queries for domains not
explicitly assigned to the servers on any other
link\.

See ` resolvectl(1) `'s coverage of ` default-route ` for a
description of this feature\.



*Type:*
(one of \<null>, “yes”, “no”) or boolean convertible to it



*Default:*
` true `

*Declared by:*
 - [nix/nixos-modules\.nix](/nix/nixos-modules.nix)



## programs\.update-systemd-resolved\.servers\.\<name>\.settings\.dns



Attribute set naming DNS servers to configure for
this VPN’s link\.

See the description of ` DNS ` in ` resolved.conf(5) ` for
the meaning of this option and its available values\.



*Type:*
attribute set of ((submodule) or non-empty string convertible to it)



*Default:*
` { } `



*Example:*

```
{
  "3.4.5.6" = { };
  resolver-the-first = {
    address = "1.2.3.4";
    port = 5353;
  };
  resolver-the-second = "2.3.4.5";
}
```

*Declared by:*
 - [nix/nixos-modules\.nix](/nix/nixos-modules.nix)



## programs\.update-systemd-resolved\.servers\.\<name>\.settings\.dns\.\<name>\.__toString



String representation of the DNS server\.



*Type:*
function that evaluates to a(n) string *(read only)*



*Default:*
` <function> `

*Declared by:*
 - [nix/nixos-modules\.nix](/nix/nixos-modules.nix)



## programs\.update-systemd-resolved\.servers\.\<name>\.settings\.dns\.\<name>\.address



The IPv4 or IPv6 address of the DNS server\.



*Type:*
non-empty string



*Default:*
` "‹name›" `

*Declared by:*
 - [nix/nixos-modules\.nix](/nix/nixos-modules.nix)



## programs\.update-systemd-resolved\.servers\.\<name>\.settings\.dns\.\<name>\.interface



Network interface name or index (note that this is as
detailed as ` resolved.conf(5) ` gets about the
meaning of the interface component of a DNS server
specification)\.



*Type:*
null or non-empty string



*Default:*
` null `

*Declared by:*
 - [nix/nixos-modules\.nix](/nix/nixos-modules.nix)



## programs\.update-systemd-resolved\.servers\.\<name>\.settings\.dns\.\<name>\.port



The port number of the DNS server\.



*Type:*
null or 16 bit unsigned integer; between 0 and 65535 (both inclusive)



*Default:*
` null `

*Declared by:*
 - [nix/nixos-modules\.nix](/nix/nixos-modules.nix)



## programs\.update-systemd-resolved\.servers\.\<name>\.settings\.dns\.\<name>\.sni



Server name indication to send when using DNS-over-TLS\.



*Type:*
null or non-empty string



*Default:*
` null `

*Declared by:*
 - [nix/nixos-modules\.nix](/nix/nixos-modules.nix)



## programs\.update-systemd-resolved\.servers\.\<name>\.settings\.dnsOverTLS



Whether to enable DNS-over-TLS for this link\.

See the description of ` DNSOverTLS ` in ` resolved.conf(5) ` for
the meaning of this option and its available values\.

In addition to the values documented there, this option also
accepts the value “default”, signifying that this link should use
the global value for ` DNSOverTLS ` configured in ` resolved.conf `\.



*Type:*
(one of \<null>, “default”, “opportunistic”, “yes”, “no”) or boolean convertible to it



*Default:*
` null `

*Declared by:*
 - [nix/nixos-modules\.nix](/nix/nixos-modules.nix)



## programs\.update-systemd-resolved\.servers\.\<name>\.settings\.dnssec



Whether to enable DNSSEC for this link\.

See the description of ` DNSSEC ` in ` resolved.conf(5) ` for
the meaning of this option and its available values\.

In addition to the values documented there, this option also
accepts the value “default”, signifying that this link should use
the global value for ` DNSSEC ` configured in ` resolved.conf `\.



*Type:*
(one of \<null>, “allow-downgrade”, “default”, “yes”, “no”) or boolean convertible to it



*Default:*
` null `

*Declared by:*
 - [nix/nixos-modules\.nix](/nix/nixos-modules.nix)



## programs\.update-systemd-resolved\.servers\.\<name>\.settings\.dnssecNegativeTrustAnchors



DNSSEC negative trust anchors to configure for
this link\.  See the ` NEGATIVE TRUST ANCHORS `
section in ` dnssec-trust-anchors.d ` for
a description of negative trust anchors and how
to specify them\.



*Type:*
list of non-empty string



*Default:*
` [ ] `

*Declared by:*
 - [nix/nixos-modules\.nix](/nix/nixos-modules.nix)



## programs\.update-systemd-resolved\.servers\.\<name>\.settings\.domain



Main domain to configure for this link\.

See the description of ` Domains ` in ` resolved.conf(5) ` for
the meaning of this option and its available values\.



*Type:*
null or non-empty string



*Default:*
` null `

*Declared by:*
 - [nix/nixos-modules\.nix](/nix/nixos-modules.nix)



## programs\.update-systemd-resolved\.servers\.\<name>\.settings\.flushCaches



Whether to flush ` systemd-resolved `’s cache upon
starting the VPN\.

See ` resolvectl(1) `'s coverage of ` flush-caches ` for a
description of this feature\.



*Type:*
(one of \<null>, “yes”, “no”) or boolean convertible to it



*Default:*
` null `

*Declared by:*
 - [nix/nixos-modules\.nix](/nix/nixos-modules.nix)



## programs\.update-systemd-resolved\.servers\.\<name>\.settings\.llmnr



Whether to enable LLMNR for this link\.

See the description of ` LLMNR ` in ` resolved.conf(5) ` for
the meaning of this option and its available values\.

In addition to the values documented there, this option also
accepts the value “default”, signifying that this link should use
the global value for ` LLMNR ` configured in ` resolved.conf `\.



*Type:*
(one of \<null>, “default”, “resolve”, “yes”, “no”) or boolean convertible to it



*Default:*
` "default" `

*Declared by:*
 - [nix/nixos-modules\.nix](/nix/nixos-modules.nix)



## programs\.update-systemd-resolved\.servers\.\<name>\.settings\.multicastDNS



Whether to enable multicast DNS for this link\.

See the description of ` MulticastDNS ` in ` resolved.conf(5) ` for
the meaning of this option and its available values\.

In addition to the values documented there, this option also
accepts the value “default”, signifying that this link should use
the global value for ` MulticastDNS ` configured in ` resolved.conf `\.



*Type:*
(one of \<null>, “default”, “resolve”, “yes”, “no”) or boolean convertible to it



*Default:*
` "default" `

*Declared by:*
 - [nix/nixos-modules\.nix](/nix/nixos-modules.nix)



## programs\.update-systemd-resolved\.servers\.\<name>\.settings\.resetServerFeatures



Whether to reset learned server features when
bringing up the VPN link\.

See ` resolvectl(1) `'s coverage of ` reset-server-features ` for a
description of this feature\.



*Type:*
(one of \<null>, “yes”, “no”) or boolean convertible to it



*Default:*
` true `

*Declared by:*
 - [nix/nixos-modules\.nix](/nix/nixos-modules.nix)



## programs\.update-systemd-resolved\.servers\.\<name>\.settings\.resetStatistics



Whether to reset the statistics counters shown in
` resolvectl statistics ` to zero when
bringing up the VPN link\.

See ` resolvectl(1) `'s coverage of ` reset-statistics ` for a
description of this feature\.



*Type:*
(one of \<null>, “yes”, “no”) or boolean convertible to it



*Default:*
` true `

*Declared by:*
 - [nix/nixos-modules\.nix](/nix/nixos-modules.nix)



## programs\.update-systemd-resolved\.servers\.\<name>\.settings\.routeOnlyDomains



List of route-only domains to configure for this
link\.

See the description of ` Domains ` in ` resolved.conf(5) ` for
the meaning of this option and its available values\.



*Type:*
list of non-empty string



*Default:*
` [ ] `

*Declared by:*
 - [nix/nixos-modules\.nix](/nix/nixos-modules.nix)



## programs\.update-systemd-resolved\.servers\.\<name>\.settings\.searchDomains



List of search domains to configure for this
link\.

See the description of ` Domains ` in ` resolved.conf(5) ` for
the meaning of this option and its available values\.



*Type:*
list of non-empty string



*Default:*
` [ ] `

*Declared by:*
 - [nix/nixos-modules\.nix](/nix/nixos-modules.nix)


