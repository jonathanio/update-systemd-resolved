{self, ...}: {
  perSystem = {
    config,
    pkgs,
    lib,
    ...
  }: {
    packages.default = config.packages.update-systemd-resolved;

    packages.update-systemd-resolved = pkgs.update-systemd-resolved.overrideAttrs (oldAttrs: let
      buildInputs = with pkgs; [iproute2 systemd util-linux];
    in {
      src = self;

      buildInputs = (oldAttrs.buildInputs or []) ++ buildInputs;
      nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [pkgs.makeWrapper];

      # Run `checkPhase` for `update-systemd-resolved`, which (ultimately) runs
      # `make test`.
      doCheck = true;

      # Rewrite update-systemd-resolved.conf to:
      #   1. Remove "setenv PATH ..." (setting PATH is unnecessary here, where
      #      nixpkgs' update-systemd-resolved derivation builder replaces
      #      update-systemd-resolved with a wrapper script that defines a PATH
      #      that makes all of update-systemd-resolved's dependencies
      #      available), and
      #   2. Replace the preset path to update-systemd-resolved with the Nix
      #      store path of the update-systemd-resolved script (so that doing
      #      "config <nix-store-path-of>/update-systemd-resolved.conf" from
      #      within an OpenVPN config file will work properly).
      postInstall = ''
        ${oldAttrs.postInstall or ""}

        sed -i -e "
          /^setenv[[:space:]]\+PATH/d
          s|\([[:space:]]\)[^[[:space:]]*\(/update-systemd-resolved\)|\1''${out}/libexec/openvpn\2|
        " "''${out}/libexec/openvpn/update-systemd-resolved.conf"

        wrapProgram "''${out}/libexec/openvpn/update-systemd-resolved" \
          --suffix PATH : ${lib.makeBinPath buildInputs}
      '';

      patches = [];

      # Rewrite the test script's shebang to use a Bash that lives somewhere
      # in the Nix store, rather than using `#!/usr/bin/env bash`.  Without
      # this, the test suite will fail with an error like:
      #
      #   /nix/store/<...>/bin/bash: line 1: ./run-tests: cannot execute: required file not found
      #
      patchPhase = ''
        patchShebangs ./run-tests
      '';

      passthru = {
        # Note that we write the rules to a file with the extension ".js";
        # "node --check" bails out if provided a file that ends with the
        # ".rules" extension.
        mkPolkitRules = {
          user,
          group,
          rules ? "10-update-systemd-resolved.rules",
        }:
          pkgs.runCommand rules {}
          ''
            case "$out" in
              *.rules)
                rules="$out"
                ;;
              *)
                rules="''${out}.rules"
            esac

            case "$rules" in
              */*)
                mkdir -p "$(dirname "$rules")"
                ;;
            esac

            js="''${rules}.js"

            ${config.packages.update-systemd-resolved}/libexec/openvpn/update-systemd-resolved print-polkit-rules \
              --polkit-allowed-user ${user} \
              --polkit-allowed-group ${group} \
              > "$js"

            ${pkgs.nodejs}/bin/node --check "$js"
            mv -f "$js" "$rules"
          '';

        tests = {
          inherit (config.checks) update-systemd-resolved;

          polkit-rules = config.packages.update-systemd-resolved.mkPolkitRules {
            user = "foo";
            group = "bar";
          };
        };
      };
    });
  };
}
