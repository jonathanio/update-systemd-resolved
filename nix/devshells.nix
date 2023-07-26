{
  perSystem = {
    config,
    pkgs,
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
      ];

      devshell = {
        packagesFrom = [config.packages.update-systemd-resolved];
      };
    };

    treefmt = {
      programs.alejandra.enable = true;
      flakeFormatter = true;
      projectRootFile = "flake.nix";
    };
  };
}
