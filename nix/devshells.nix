{lib, ...}: {
  perSystem = {
    config,
    pkgs,
    system,
    ...
  }: {
    devshells.default = {
      commands = [
        {
          name = "fmt";
          category = "linting";
          help = "Format this project's code";
          command = ''
            exec ${config.treefmt.build.wrapper}/bin/treefmt "$@"
          '';
        }

        {
          name = "mkdotcert";
          category = "maintenance";
          help = "Generate the DNS-over-TLS keypair for use in system testing";
          command = let
            inherit (config.checks.update-systemd-resolved.nodes) resolver;
          in ''
            export CAROOT="''${PRJ_ROOT:-.}/nix"
            ${pkgs.mkcert}/bin/mkcert -install || exit
            ${pkgs.mkcert}/bin/mkcert \
              -cert-file "''${CAROOT}/resolver.crt" \
              -key-file "''${CAROOT}/resolver.key" \
              ${resolver.networking.hostName} \
              ${resolver.networking.hostName}.${resolver.networking.domain}
          '';
        }

        {
          name = "mkanchor";
          category = "maintenance";
          help = "Fetch DNSSEC root anchors and translate them to dnsmasq format";
          command = let
            unsupported = lib.elem system [
              "armv6l-linux"
              "armv7l-linux"
              "powerpc64le-linux"
              "riscv64-linux"
            ];
          in
            (lib.optionalString (!unsupported) ''
              ${pkgs.xidel}/bin/xidel \
                --input-format xml \
                --output-format json-wrapped \
                -e 'for $kd in //TrustAnchor/KeyDigest return string-join((//TrustAnchor/Zone, $kd/KeyTag, $kd/Algorithm, $kd/DigestType, $kd/Digest), ",")' \
                https://data.iana.org/root-anchors/root-anchors.xml \
              | ${pkgs.jq}/bin/jq flatten > "''${PRJ_ROOT}/nix/trust-anchor.json"
            '')
            + (lib.optionalString unsupported ''
              printf 1>&2 -- '%s: sorry, this command is unsupported on system `%s`\n' \
                "''${0##*/}" ${lib.escapeShellArg system}
              exit 1
            '');
        }
      ];

      devshell = {
        packagesFrom = [config.packages.update-systemd-resolved];
      };
    };

    treefmt = {
      programs.alejandra.enable = true;
      programs.shellcheck.enable = true;

      settings.formatter.shellcheck = {
        includes = [
          "update-systemd-resolved"
          "run-tests"
          "tests"
        ];
      };

      flakeFormatter = true;
      projectRootFile = "flake.nix";
    };
  };
}
