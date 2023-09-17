{self, inputs, ...}: {
  perSystem = {
    config,
    pkgs,
    lib,
    system,
    ...
  }: {
    packages.default = config.packages.update-systemd-resolved;

    packages.docs = let
      # Use a full NixOS system rather than (say) the result of
      # `lib.evalModules`.  This is because our NixOS module refers to
      # `services.openvpn`, which may itself refer to any number of other NixOS
      # options, which may themselves... etc.  Without this, then, we'd get an
      # evaluation error generating documentation.
      eval = inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          { system.stateVersion = "23.11"; }
          self.nixosModules.update-systemd-resolved
        ];
      };

      allDocs =  pkgs.nixosOptionsDoc {
        inherit (eval) options;

        # Default is currently "appendix".
        documentType = "none";

        # We only want Markdown
        allowDocBook = false;
        markdownByDefault = true;

        # Only include our own options.
        transformOptions = let
          ourPrefix = "${toString self}/";
          nixosModules = "nix/nixos-modules.nix";
          link = {
            url = "/${nixosModules}";
            name = nixosModules;
          };
        in
          opt: opt // {
            visible = opt.visible && (lib.any (lib.hasPrefix ourPrefix) opt.declarations);
            declarations = map (decl: if lib.hasPrefix ourPrefix decl then link else decl) opt.declarations;
          };
      };
    in allDocs.optionsCommonMark;

    packages.update-systemd-resolved = pkgs.update-systemd-resolved.overrideAttrs (oldAttrs: let
      buildInputs = with pkgs; [coreutils iproute2 systemd util-linux];
    in {
      src = self;

      buildInputs = (oldAttrs.buildInputs or []) ++ buildInputs;
      nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [pkgs.makeWrapper];

      # Run `checkPhase` for `update-systemd-resolved`, which (ultimately) runs
      # `make test`.
      doCheck = true;

      PREFIX = placeholder "out";

      # Rewrite update-systemd-resolved.conf to replace the preset path to
      # update-systemd-resolved with the Nix store path of the
      # update-systemd-resolved script (so that doing "config
      # <nix-store-path-of>/update-systemd-resolved.conf" from within an
      # OpenVPN config file will work properly).
      postInstall = ''
        sed -i -e "
          s|\([[:space:]]\)[^[[:space:]]*\(/update-systemd-resolved\)|\1''${out}/libexec/openvpn\2|
        " "''${out}/share/doc/openvpn/update-systemd-resolved.conf"

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
      # Additionally, update the shebang of `update-systemd-resolved` itself in
      # order to permit running the `--print-polkit-rules` action.
      patchPhase = ''
        patchShebangs ./run-tests ./update-systemd-resolved
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
