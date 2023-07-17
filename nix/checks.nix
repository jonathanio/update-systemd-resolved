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

      # dnsmasq listening port
      resolverPort = 53;

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
            services.dnsmasq = {
              enable = true;
              resolveLocalQueries = false;
              settings = {
                port = resolverPort;

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

            networking.firewall = {
              allowedTCPPorts = [resolverPort];
              allowedUDPPorts = [resolverPort];
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
            services.resolved.enable = true;
            services.resolved.dnssec = "false";

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

                dhcp-option DNS ${resolverIP}
                dhcp-option DOMAIN ${vpnDomain}
              '';
            };

            # Add our generated ruleset to the system's polkit rules
            environment.etc."polkit-1/rules.d/10-update-systemd-resolved.rules".source = polkitRules;

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

          server.start()
          wait_for_unit_with_output(server, '${serviceName}')

          client.start()
          wait_for_unit_with_output(client, '${serviceName}')

          # Block until we can reach the resolver (or until we hit the retry
          # timeout).  Pass `-u` flag to check UDP port; also check TCP port.
          wait_for_open_host_port(client, '${resolverIP}', 53, extra=['-u'])
          wait_for_open_host_port(client, '${resolverIP}', 53)

          assert_hostname_match(client, '${resolverIP}', 'resolver-cname.${vpnDomain}')
          assert_hostname_match(client, '${serverIP}', 'server-cname.${vpnDomain}')
        '';
      };
  };
}
