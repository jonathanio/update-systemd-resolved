{self, ...}: {
  perSystem = perSystem @ {
    config,
    lib,
    pkgs,
    ...
  }: {
    checks.default = config.checks.update-systemd-resolved;

    checks.update-systemd-resolved = let
      # Name of the test script
      name = "update-systemd-resolved";

      # "<name>" in "services.openvpn.servers.<name>"
      instanceName = "${name}-test";

      # "<name>" in "systemd.services.<name>"
      serviceAttrName = "openvpn-${instanceName}";

      # systemd service name
      serviceName = "${serviceAttrName}.service";

      # "dev <name>" in OpenVPN configs
      devName = "tun";

      # OpenVPN interface name
      interface = "${devName}0";

      # "port <num>" in OpenVPN server config
      serverPort = 11194;

      # Addresses assigned to server and client tun interfaces
      serverEndpoint = "10.8.0.1";
      clientEndpoint = "10.8.0.2";

      # "<domain>" in "dhcp-option DOMAIN <domain>".  Also used for various
      # dnsmasq settings.
      vpnDomain = "update.systemd.resolved";

      # RouteDNS listening port
      resolverPort = 5353;

      # Try to infer the IP address assigned to a node in this NixOS test
      # scenario, falling back to the value of "default" if inference failed.
      fetchFirstAddress = {
        node,
        default,
        ifname ? "eth1",
        type ? "ipv4",
      }: let
        addresses = node.networking.interfaces.${ifname}.${type}.addresses or [];
        address =
          if (builtins.length addresses) > 0
          then builtins.head addresses
          else {};
      in
        address.address or default;

      # Generate polkit rules for allowing unprivileged users to perform
      # org.freedesktop.resolve1 actions.
      mkPolkitRules = {
        user ? "openvpn",
        group ? "network",
      }:
        perSystem.config.packages.update-systemd-resolved.mkPolkitRules {
          inherit user group;
        };

      # Wrapper for mkPolkitRules that extracts appropriate arguments from a
      # "systemd.services.<name>" definition
      mkPolkitRulesForService = service: let
        sc = service.serviceConfig;
      in
        mkPolkitRules
        (lib.optionalAttrs (sc ? "User") {user = sc.User;})
        // (lib.optionalAttrs (sc ? "Group") {group = sc.Group;})
        // {inherit pkgs lib;};
    in
      pkgs.nixosTest {
        inherit name;

        nodes = {
          resolver = {
            networking.domain = vpnDomain;

            networking.firewall = {
              allowedTCPPorts = [resolverPort];
              allowedUDPPorts = [resolverPort];
            };

            services.dnsmasq = {
              enable = true;
              resolveLocalQueries = false;
              settings = {
                port = 53;

                log-queries = "extra";
                log-debug = true;

                # Don't read upstream resolvers from /etc/resolv.conf
                no-resolv = true;

                # Only answer to queries from LAN
                local-service = true;

                # Never forward queries for simple names
                domain-needed = true;

                # Add domain (defined with "domain=...") to simple names in
                # /etc/hosts
                expand-hosts = true;

                domain = vpnDomain;
                local = "/${vpnDomain}/";

                # NXDOMAIN reverse lookups that don't resolve to hosts in
                # /etc/hosts or the DHCP leases file
                bogus-priv = true;

                # Some CNAMEs; used for testing successful name resolution in
                # the test script
                cname = [
                  "resolver-cname,resolver-cname.${vpnDomain},resolver"
                  "server-cname,server-cname.${vpnDomain},server"
                  "client-cname,client-cname.${vpnDomain},client"
                ];
              };
            };

            services.routedns = {
              enable = true;

              settings = {
                resolvers = {
                  local-tcp = {
                    address = "127.0.0.1:53";
                    protocol = "tcp";
                  };

                  local-udp = {
                    address = "127.0.0.1:53";
                    protocol = "udp";
                  };
                };

                listeners = let
                  commonConfig = {
                    address = ":${toString resolverPort}";

                    # Generated with `mkcert`.
                    server-crt = ./resolver.crt;
                    server-key = ./resolver.key;
                  };
                in {
                  local-dot = commonConfig // {
                    protocol = "dot";
                    resolver = "local-tcp";
                  };

                  local-dtls = commonConfig // {
                    protocol = "dtls";
                    resolver = "local-udp";
                  };
                };
              };
            };
          };

          server = {nodes, ...}: let
            resolverIP = fetchFirstAddress {
              node = nodes.resolver;
              default = "192.168.1.2";
            };
          in {
            # NOTE -- server push settings appear to be ignored in
            # shared-secret/point-to-point configurations.  Instead of doing
            # (for example):
            #
            #   push "dhcp-option DNS ${resolverIP}"
            #   push "dhcp-option DOMAIN ${vpnDomain}"
            #
            # in the server configuration, we instead put
            #
            #   dhcp-option DNS ${resolverIP}
            #   dhcp-option DOMAIN ${vpnDomain}
            #
            # in the client configuration.
            services.openvpn.servers.${instanceName} = {
              config = ''
                dev ${devName}
                port ${toString serverPort}
                secret ${./openvpn.key.static}
                ifconfig ${serverEndpoint} ${clientEndpoint}
                providers legacy default
              '';
            };

            networking.firewall = {
              trustedInterfaces = [interface];
              allowedUDPPorts = [serverPort];
            };
          };

          client = {
            nodes,
            config,
            lib,
            pkgs,
            ...
          }: let
            resolverIP = fetchFirstAddress {
              node = nodes.resolver;
              default = "192.168.1.2";
            };
            polkitRules = mkPolkitRulesForService config.systemd.services.${serviceAttrName};
          in {
            networking.useNetworkd = true;

            services.resolved = {
              enable = true;
              dnssec = "false";
              extraConfig = ''
                MulticastDNS=no
              '';
            };

            users.users.openvpn = {
              description = "openvpn client user";
              shell = "${pkgs.utillinux}/bin/nologin";
              isSystemUser = true;
              group = "network";
            };

            users.groups.network = {};

            # networking.useDHCP not possible when networking.useNetworkd is in
            # effect
            networking.useDHCP = false;

            systemd.network = {
              enable = true;
              networks.default = {
                # Rely on the fact that these QEMU machines use interfaces
                # named eth*
                name = "eth*";
                DHCP = "yes";
              };
            };

            environment.systemPackages = with pkgs; [
              dnsutils # for "dig"
            ];

            services.openvpn.servers.${instanceName} = {
              config = ''
                remote server
                port ${toString serverPort}
                secret ${./openvpn.key.static}
                dev ${devName}
                ifconfig ${clientEndpoint} ${serverEndpoint}

                providers legacy default

                config ${perSystem.config.packages.update-systemd-resolved}/libexec/openvpn/update-systemd-resolved.conf

                dhcp-option DNS ${resolverIP}:${toString resolverPort}#resolver
                dhcp-option DOMAIN ${vpnDomain}

                dhcp-option FLUSH-CACHES yes
                dhcp-option RESET-SERVER-FEATURES true
                dhcp-option RESET-STATISTICS yes

                dhcp-option DEFAULT-ROUTE yes
                dhcp-option DNS-OVER-TLS yes
                dhcp-option LLMNR resolve
                dhcp-option MULTICAST-DNS default

                dhcp-option DNSSEC opportunistic
                dhcp-option DNSSEC-NEGATIVE-TRUST-ANCHORS ${vpnDomain}
              '';
            };

            # Add our generated ruleset to the system's polkit rules
            environment.etc."polkit-1/rules.d/10-update-systemd-resolved.rules".source = polkitRules;

            # `mkcert` CA
            security.pki.certificateFiles = [./rootCA.pem];

            security.polkit = {
              enable = true;
              debug = true;

              # Log authorization checks.
              extraConfig = ''
                polkit.addRule(function(action, subject) {
                  polkit.log("user " +  subject.user + " is attempting action " + action.id + " from PID " + subject.pid);
                });
              '';
            };

            # Override the openvpn service definition to make it run as the
            # "openvpn" user and "network" group.  Mimic the
            # openvpn-client@.service from Arch Linux in other respects, too.
            # Additionally, make the unit wait on name resolution to be "up" by
            # adding "After = nss-lookup.target"; otherwise, we could hit a
            # race condition where the OpenVPN client service is up and we
            # start attempting to resolve hostnames before systemd-resolved is
            # fully initialized.
            systemd.services.${serviceAttrName} = {
              serviceConfig = let
                capabilities = ''
                  CAP_IPC_LOCK CAP_NET_ADMIN CAP_NET_RAW CAP_SETGID CAP_SETUID CAP_SYS_CHROOT CAP_DAC_OVERRIDE
                '';
              in {
                User = "openvpn";
                Group = "network";

                PrivateTmp = "true";
                AmbientCapabilities = capabilities;
                CapabilityBoundingSet = capabilities;
                LimitNPROC = "10";
                DeviceAllow = [
                  "/dev/null rw"
                  "/dev/net/tun rw"
                ];
                ProtectSystem = "true";
                ProtectHome = "true";
                KillMode = "process";
              };

              after = lib.mkAfter ["nss-lookup.target"];
            };
          };
        };

        testScript = {nodes, ...}: let
          resolverIP = fetchFirstAddress {
            node = nodes.resolver;
            default = "192.168.1.2";
          };
          serverIP = fetchFirstAddress {
            node = nodes.server;
            default = "192.168.1.3";
          };
        in ''
          import shlex

          def wait_for_unit_with_output(machine, unit):
            try:
              machine.wait_for_unit(unit)
            except Exception as e:
              machine.execute('systemctl status -l {0} 1>&2'.format(unit))
              raise(e)

          def dump_resolved_info(machine):
            with machine.nested('printing resolved status and statistics'):
              machine.succeed('resolvectl status 1>&2')
              machine.succeed('resolvectl statistics 1>&2')

          def assert_hostname_match(machine, expected, *args):
            cmd = shlex.join(['dig', '+short', *args])

            # Even after waiting for nss-lookup.target, lookups can still fail for
            # reasons unrelated to any update-systemd-resolved misbehaviour.  Retry
            # name resolution in order to work around race conditions/other issues.
            def hostname_matches(_):
              status, output = machine.execute(cmd)

              if status != 0:
                return False

              for line in output.splitlines():
                if line == expected:
                  return True

              return False

            with machine.nested('checking that hostname resolves to expected address "{0}" from {1}'.format(expected, machine.name)):
              retry(hostname_matches)

          def extract_interface_property(machine, interface, property, *args):
            with machine.nested('extracting property "{0}" of interface "{1}"'.format(property, interface)):
              cmd = shlex.join(['resolvectl', *args, property, interface])
              return machine.succeed("{0} | grep -m1 -Po '(?<=:\s).*'".format(cmd)).rstrip()

          def assert_interface_property(machine, interface, property, expected, *args):
            def interface_property_matches(_):
              actual = extract_interface_property(machine, interface, property, *args)
              machine.log('property "{0}" of interface "{1}" is "{2}"'.format(property, interface, actual))
              if actual == expected:
                return True
              else:
                machine.log('expected property "{0}" of interface "{1}" to be "{2}", but got "{3}"'.format(property, interface, expected, actual))
                return False

            with machine.nested('checking that property "{0}" of interface "{1}" is "{2}"'.format(property, interface, expected)):
              retry(interface_property_matches)

          # Machine.wait_for_open_port only checks ports on localhost
          def wait_for_open_host_port(machine, host, port, extra=[]):
            cmd = shlex.join(['nc'] + extra + ['-z', host, str(port)])

            # `retry` passes an argument to the provided function
            def host_port_is_open(_):
              status, _ = machine.execute(cmd)
              return status == 0

            with machine.nested('checking that host and port "{0}:{1}" are open from the perspective of {2}'.format(host, port, machine.name)):
              retry(host_port_is_open)

          client.succeed('cat /etc/polkit-1/rules.d/10-update-systemd-resolved.rules 1>&2')
          client.succeed('systemctl cat ${serviceName} 1>&2')

          resolver.start()
          wait_for_unit_with_output(resolver, 'dnsmasq')
          wait_for_unit_with_output(resolver, 'routedns')

          server.start()
          wait_for_unit_with_output(server, '${serviceName}')

          client.start()

          wait_for_unit_with_output(client, '${serviceName}')

          # Block until we can reach the resolver (or until we hit the retry
          # timeout).  Pass `-u` flag to check UDP port; also check TCP port.
          wait_for_open_host_port(client, '${resolverIP}', ${toString resolverPort}, extra=['-u'])
          wait_for_open_host_port(client, '${resolverIP}', ${toString resolverPort})

          assert_hostname_match(client, '${resolverIP}', 'resolver-cname.${vpnDomain}')
          assert_hostname_match(client, '${serverIP}', 'server-cname.${vpnDomain}')

          dump_resolved_info(client)

          assert_interface_property(client, '${interface}', 'default-route', 'yes')
          assert_interface_property(client, '${interface}', 'llmnr', 'resolve')
          assert_interface_property(client, '${interface}', 'mdns', 'no')
          assert_interface_property(client, '${interface}', 'dnsovertls', 'yes')
          assert_interface_property(client, '${interface}', 'dnssec', 'opportunistic')

          client.succeed('systemctl restart ${serviceName}')
          wait_for_unit_with_output(client, '${serviceName}')

          dump_resolved_info(client)
        '';
      };
  };
}
