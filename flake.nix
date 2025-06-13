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
        fromYamlFile = import ./src/lib/fromYamlFile.nix pkgs;
        buildFirefoxXpiAddon = import ./src/lib/buildFirefoxXpiAddon.nix pkgs;
        toNixpkgsLicense = import ./src/lib/toNixpkgsLicense.nix pkgs;
      in {
        addons = pipe ./addons.yaml [
          # read all addon data into memory
          fromYamlFile

          # translate api resource to nix package
          (map (addonDetail:
            buildFirefoxXpiAddon {
              inherit (addonDetail) guid;
              pname = addonDetail.slug;
              version = addonDetail.current_version.version;

              url = addonDetail.current_version.file.url;
              sha256 = convertHash {
                inherit (addonDetail.current_version.file) hash;
                toHashFormat = "sri";
                hashAlgo = "sha256";
              };

              meta = {
                mozPersmissions = addonDetail.current_version.file.permissions or [];
                license = toNixpkgsLicense addonDetail.current_version.license.slug;
              };
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
