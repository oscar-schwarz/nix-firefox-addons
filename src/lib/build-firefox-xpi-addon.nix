# Copied and adapted from https://gitlab.com/rycee/nur-expressions/-/blob/78ce8a0ab9e72a4127472e6343a92a33fbd12691/pkgs/firefox-addons/default.nix
{
  fetchurl,
  stdenv,
  ...
}: {
  guid,
  slug,
  version,
  url,
  hash,
  permissions
}:
stdenv.mkDerivation {
  inherit version;
  pname = slug;

  src = fetchurl {
    inherit url;
    sha256 = builtins.convertHash {
      inherit hash;
      toHashFormat = "sri";
      hashAlgo = "sha256";
    };
  };

  preferLocalBuild = true;
  allowSubstitutes = true;

  buildCommand = ''
    dst="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
    mkdir -p "$dst"
    install -v -m644 "$src" "$dst/${guid}.xpi"
  '';

  meta.mozPermissions = permissions;
}
