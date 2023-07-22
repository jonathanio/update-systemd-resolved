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
