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
pre-down /etc/openvpn/update-systemd-resolved
```

# How to help

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

# Licence

GPL

# Author

Jonathan Wright <jon@than.io>
