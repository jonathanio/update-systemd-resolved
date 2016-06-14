# update-systemd-resolved

This is a script designed to integrate OpenVPN with the `systemd-resolved`
service via DBus instead of trying to override `/etc/resolv.conf` or manipulate
`systemd-networkd` configuration files.

Since `systemd-229`, the `systemd-resolved` service has had an API available via
DBus which allows direct manipulation of the DNS configuration for a link. This
script makes use of `busctl` from `systemd` to send messages to
`systemd-resolved` to update the DNS for the link created by OpenVPN.

# How to use?

Make sure that you have `systemd-resolved` enabled and running:

```
systemctl enable systemd-resolved.service
systemctl start systemd-resolved.service
```

Then update your `/etc/nsswitch.conf` file to look up DNS via the `resolve`
service:

```
# Use systems-resolved first, then fall back to glibc and /etc/resolv.conf
hosts: files resolve dns myhostname
# Use glibc and /etc/resolv.conf first, then fall back to systems-resolved
hosts: files dns resolve myhostname
```

Finally, update your OpenVPN configuration file and set the `up` and `down`
options, and enable `up-restart`:

```
script-security 2
up /etc/openvpn/update-systemd-resolved
down /etc/openvpn/update-systemd-resolved
up-restart
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

# How to help

If you can help with any of these areas, or have bug fixes, please fork and
raise a Pull Request for me.

# Licence

GPL

# Author

Jonathan Wright <jon@than.io>
