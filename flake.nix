{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};

        inherit (builtins) convertHash listToAttrs;
        inherit (pkgs.lib) pipe;
        inherit (pkgs) writeShellApplication;

        fromYamlFile = import ./src/lib/from-yaml-file.nix pkgs;
        buildFirefoxXpiAddon = import ./src/lib/build-firefox-xpi-addon.nix pkgs;
        toNixpkgsLicense = import ./src/lib/to-nixpkgs-license.nix pkgs;
      in {
        packages = {
          search-addon = writeShellApplication {
            name = "search-addon";
            runtimeInputs = [pkgs.nushell];
            text = ''nu ${./src/search-addon.nu} "$@"'';
          };
        };

        addons = pipe ./addons.yaml [
          # read all addon data into memory
          fromYamlFile

          # translate api resource to nix package
          (map (addon:
            buildFirefoxXpiAddon {
              guid = addon.g;
              slug = addon.s;
              version = addon.v;
              url = addon.u;
              hash = addon.h;
              permissions = addon.p;
            }))

          # to attrset with name being the addon slug
          (map (pkg: {
            name = pkg.pname;
            value = pkg;
          }))
          listToAttrs
        ];
      }
    );
}
