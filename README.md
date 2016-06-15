# update-systemd-resolved

This is a helper script designed to integrate OpenVPN with the `systemd-resolved`
service via DBus instead of trying to override `/etc/resolv.conf`, or manipulate
`systemd-networkd` configuration files.

Since systemd-229, the `systemd-resolved` service has an API available via
DBus which allows directly setting the DNS configuration for a link. This script
makes use of `busctl` from systemd to send DBus messages to `systemd-resolved`
to update the DNS for the link created by OpenVPN.

*NOTE*: This is an alpha script. So long as you're using OpenVPN 2.1 or greater,
iproute2, and have at least version 229 of systemd, then it should work.
Nonetheless, if you do come across problems, fork and fix, or raise an issue.

# How to use?

Make sure that you have `systemd-resolved` enabled and running:

```
systemctl enable systemd-resolved.service
systemctl start systemd-resolved.service
```

Then update your `/etc/nsswitch.conf` file to look up DNS via the `resolve`
service:

```
# Use systemd-resolved first, then fall back to /etc/resolv.conf
hosts: files resolve dns myhostname
# Use /etc/resolv.conf first, then fall back to systemd-resolved
hosts: files dns resolve myhostname
```

Finally, update your OpenVPN configuration file and set the `up` and `down`
options:

```
script-security 2
up /etc/openvpn/update-systemd-resolved
down /etc/openvpn/update-systemd-resolved
```

# Notes

This is an early release having managed to get it to successfully run. However
there are a number of areas this still needs work on, including:

- [x] Set of one or more IPv4 DNS servers on the link
- [ ] Set the DNS domain for the link
- [ ] Set one or more DNS search domains for the link
- [ ] Set of one or more IPv6 DNS servers on the link
  - [ ] Full IPv6 processing inside Bash? Need to convert any format of address into a 16-byte array
- [ ] Manage the priority of the DNS settings for default routes?
- [ ] Add error handling around `busctl` calls
- [x] Revert the link settings on down state

# How to help

If you can help with any of these areas, or have bug fixes, please fork and
raise a Pull Request for me.

# Licence

GPL

# Author

Jonathan Wright <jon@than.io>
