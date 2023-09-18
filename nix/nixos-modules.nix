{
  self,
  moduleWithSystem,
  ...
}: {
  flake = {config, ...}: {
    nixosModules.default = config.nixosModules.update-systemd-resolved;

    nixosModules.update-systemd-resolved =
      moduleWithSystem
      (
        perSystem @ {config}: nixos @ {
          config,
          lib,
          pkgs,
          ...
        }: let
          inherit (lib) mkOption mkPackageOption types;

          cfg = config.programs.update-systemd-resolved;

          # Convert to a format systemd understands
          bool2str = bool:
            if bool
            then "yes"
            else "no";

          enumOrBool = enum: types.coercedTo types.bool bool2str (types.enum ((lib.toList enum) ++ ["yes" "no"]));

          mkResolvedConfDesc = name: ''
            See the description of `${name}` in {manpage}`resolved.conf(5)` for
            the meaning of this option and its available values.
          '';

          mkResolvedConfDescWithDefault = name: ''
            ${mkResolvedConfDesc name}

            In addition to the values documented there, this option also
            accepts the value "default", signifying that this link should use
            the global value for `${name}` configured in `resolved.conf`.
          '';

          mkResolvectlDesc = cmd: ''
            See {manpage}`resolvectl(1)`'s coverage of {command}`${cmd}` for a
            description of this feature.
          '';

          dnsModule = types.submodule ({name, ...}: {
            options = {
              address = mkOption {
                type = types.nonEmptyStr;
                default = name;
                description = ''
                  The IPv4 or IPv6 address of the DNS server.
                '';
              };

              port = mkOption {
                type = types.nullOr types.port;
                default = null;
                description = ''
                  The port number of the DNS server.
                '';
              };

              interface = mkOption {
                type = types.nullOr types.nonEmptyStr;
                default = null;
                description = ''
                  Network interface name or index (note that this is as
                  detailed as {manpage}`resolved.conf(5)` gets about the
                  meaning of the interface component of a DNS server
                  specification).
                '';
              };

              sni = mkOption {
                type = types.nullOr types.nonEmptyStr;
                default = null;
                description = ''
                  Server name indication to send when using DNS-over-TLS.
                '';
              };

              __toString = mkOption {
                type = types.functionTo types.str;
                readOnly = true;
                description = ''
                  String representation of the DNS server.
                '';
                default = self: let
                  looksLikeIPv6 = lib.hasInfix ":" self.address;
                  hasPort = self.port != null;
                  address =
                    if looksLikeIPv6 && hasPort
                    then "[${self.address}]"
                    else self.address;
                in
                  lib.concatStrings ([
                      address
                    ]
                    ++ lib.optional hasPort ":${toString self.port}"
                    ++ lib.optional (self.interface != null) "%${self.interface}"
                    ++ lib.optional (self.sni != null) "#${self.sni}");
              };
            };
          });

          dnsType = types.coercedTo types.nonEmptyStr (address: {inherit address;}) dnsModule;
        in {
          options = {
            programs.update-systemd-resolved = {
              package = mkPackageOption perSystem.config.packages "update-systemd-resolved" {};

              servers = mkOption {
                default = {};
                description = ''
                  Attribute set of `update-systemd-resolved` configurations.
                  Intended to be included in
                  {option}`services.openvpn.servers.<name>.config` entries.
                '';
                type = types.attrsOf (types.submodule ({
                  name,
                  config,
                  ...
                }: {
                  options = {
                    openvpnServerName = mkOption {
                      type = types.str;
                      default = name;
                      description = ''
                        `<name>` in
                        {option}`services.openvpn.servers.<name>.config`.
                      '';
                    };

                    includeAutomatically = mkOption {
                      type = types.bool;
                      default = false;
                      description = ''
                        Whether to include the generated configuration in
                        {option}`services.openvpn.servers.<name>.config`.
                      '';
                    };

                    pushSettings = mkOption {
                      type = types.bool;
                      default = false;
                      description = ''
                        Whether to push {command}`update-system-resolved`
                        settings with OpenVPN's {command}`push` directive.
                        Enable this if the target OpenVPN instance is a server;
                        disable it if the target instance is a client.
                      '';
                    };

                    config = mkOption {
                      type = types.lines;
                      readOnly = true;
                      description = ''
                        The configuration text for inclusion in
                        {option}`services.openvpn.servers.<name>.config`.
                      '';
                    };

                    configFile = mkOption {
                      type = types.path;
                      readOnly = true;
                      default = pkgs.writeText "update-systemd-resolved-${name}.conf" config.config;
                      defaultText = "${toString builtins.storeDir}/<hash>-update-systemd-resolved-<name>.conf";
                      description = ''
                        A configuration file containing
                        {option}`programs.update-systemd-resolved.servers.<name>.config`
                        for inclusion in {option}`services.openvpn.servers.<name>.config`
                        via the {command}`config` directive.
                      '';
                    };

                    settings = mkOption {
                      default = {};

                      description = ''
                        DNS-related settings for this VPN's link.
                      '';

                      type = types.submodule ({...}: {
                        options = {
                          # TODO DNS6
                          dns = mkOption {
                            type = types.attrsOf dnsType;
                            default = {};
                            example = {
                              resolver-the-first = {
                                address = "1.2.3.4";
                                port = 5353;
                              };

                              resolver-the-second = "2.3.4.5";

                              "3.4.5.6" = {};
                            };
                            description = ''
                              Attribute set naming DNS servers to configure for
                              this VPN's link.

                              ${mkResolvedConfDesc "DNS"}
                            '';
                          };

                          domain = mkOption {
                            type = types.nullOr types.nonEmptyStr;
                            default = null;
                            description = ''
                              Main domain to configure for this link.

                              ${mkResolvedConfDesc "Domains"}
                            '';
                          };

                          searchDomains = mkOption {
                            type = types.listOf types.nonEmptyStr;
                            default = [];
                            description = ''
                              List of search domains to configure for this
                              link.

                              ${mkResolvedConfDesc "Domains"}
                            '';
                          };

                          routeOnlyDomains = mkOption {
                            type = types.listOf types.nonEmptyStr;
                            default = [];
                            description = ''
                              List of route-only domains to configure for this
                              link.

                              ${mkResolvedConfDesc "Domains"}
                            '';
                          };

                          defaultRoute = mkOption {
                            type = enumOrBool null;
                            default = true;
                            description = ''
                              Whether to use the DNS servers configured for
                              this link to resolve queries for domains not
                              explicitly assigned to the servers on any other
                              link.

                              ${mkResolvectlDesc "default-route"}
                            '';
                          };

                          dnsOverTLS = mkOption {
                            type = enumOrBool [null "default" "opportunistic"];
                            default = null;
                            description = ''
                              Whether to enable DNS-over-TLS for this link.

                              ${mkResolvedConfDescWithDefault "DNSOverTLS"}
                            '';
                          };

                          dnssec = mkOption {
                            type = enumOrBool [null "allow-downgrade" "default"];
                            default = null;
                            description = ''
                              Whether to enable DNSSEC for this link.

                              ${mkResolvedConfDescWithDefault "DNSSEC"}
                            '';
                          };

                          dnssecNegativeTrustAnchors = mkOption {
                            type = types.listOf types.nonEmptyStr;
                            default = [];
                            description = ''
                              DNSSEC negative trust anchors to configure for
                              this link.  See the `NEGATIVE TRUST ANCHORS`
                              section in {manpage}`dnssec-trust-anchors.d` for
                              a description of negative trust anchors and how
                              to specify them.
                            '';
                          };

                          flushCaches = mkOption {
                            type = enumOrBool null;
                            default = null;
                            description = ''
                              Whether to flush `systemd-resolved`'s cache upon
                              starting the VPN.

                              ${mkResolvectlDesc "flush-caches"}
                            '';
                          };

                          llmnr = mkOption {
                            type = enumOrBool [null "default" "resolve"];
                            default = "default";
                            description = ''
                              Whether to enable LLMNR for this link.

                              ${mkResolvedConfDescWithDefault "LLMNR"}
                            '';
                          };

                          multicastDNS = mkOption {
                            type = enumOrBool [null "default" "resolve"];
                            default = "default";
                            description = ''
                              Whether to enable multicast DNS for this link.

                              ${mkResolvedConfDescWithDefault "MulticastDNS"}
                            '';
                          };

                          resetServerFeatures = mkOption {
                            type = enumOrBool null;
                            default = true;
                            description = ''
                              Whether to reset learned server features when
                              bringing up the VPN link.

                              ${mkResolvectlDesc "reset-server-features"}
                            '';
                          };

                          resetStatistics = mkOption {
                            type = enumOrBool null;
                            default = true;
                            description = ''
                              Whether to reset the statistics counters shown in
                              {command}`resolvectl statistics` to zero when
                              bringing up the VPN link.

                              ${mkResolvectlDesc "reset-statistics"}
                            '';
                          };
                        };
                      });
                    };
                  };

                  config = {
                    config = let
                      renderDHCPOption = let
                        client = option: value: let
                          ucOption = lib.toUpper option;
                        in "dhcp-option ${ucOption} ${toString value}";

                        server = option: value: "push \"${client option value}\"";
                      in
                        if config.pushSettings
                        then server
                        else client;

                      maybeRenderDHCPOption = option: value:
                        lib.optionalString (value != null) (renderDHCPOption option value);

                      renderDHCPOptionList = option:
                        lib.concatMapStringsSep "\n" (renderDHCPOption option);
                    in ''
                      config ${cfg.package}/share/doc/openvpn/update-systemd-resolved.conf

                      ${renderDHCPOptionList "dns" (builtins.attrValues config.settings.dns)}

                      ${maybeRenderDHCPOption "domain" config.settings.domain}
                      ${renderDHCPOptionList "domain-route" (config.settings.routeOnlyDomains)}
                      ${renderDHCPOptionList "domain-search" (config.settings.searchDomains)}

                      ${maybeRenderDHCPOption "dnssec" config.settings.dnssec}
                      ${renderDHCPOptionList "dnssec-negative-trust-anchors" config.settings.dnssecNegativeTrustAnchors}

                      ${maybeRenderDHCPOption "default-route" config.settings.defaultRoute}
                      ${maybeRenderDHCPOption "dns-over-tls" config.settings.dnsOverTLS}
                      ${maybeRenderDHCPOption "flush-caches" config.settings.flushCaches}
                      ${maybeRenderDHCPOption "llmnr" config.settings.llmnr}
                      ${maybeRenderDHCPOption "multicast-dns" config.settings.multicastDNS}
                      ${maybeRenderDHCPOption "reset-server-features" config.settings.resetServerFeatures}
                      ${maybeRenderDHCPOption "reset-statistics" config.settings.resetStatistics}
                    '';
                  };
                }));
              };
            };
          };

          config = {
            services.openvpn.servers = lib.mapAttrs' (name: value: {
              name = value.openvpnServerName;
              value = {
                config = lib.mkAfter ''
                  config ${value.configFile}
                '';
              };
            }) (lib.filterAttrs (_: s: s.includeAutomatically) cfg.servers);
          };
        }
      );
  };
}
