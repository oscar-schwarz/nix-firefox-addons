# Copied and adapted from https://gitlab.com/rycee/nur-expressions/-/blob/78ce8a0ab9e72a4127472e6343a92a33fbd12691/pkgs/firefox-addons/default.nix
{
  fetchurl,
  stdenv,
  ...
}: {
  pname,
  version,
  guid,
  url,
  sha256,
  meta,
}:
stdenv.mkDerivation {
  inherit pname;
  name = "${pname}-${version}";

  inherit meta;

  src = fetchurl {inherit url sha256;};

  preferLocalBuild = true;
  allowSubstitutes = true;

  buildCommand = ''
    dst="$out/share/mozilla/extensions"
    mkdir -p "$dst"
    install -v -m644 "$src" "$dst/${guid}.xpi"
  '';
}
