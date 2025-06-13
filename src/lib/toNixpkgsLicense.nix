{lib, ...}:
with lib.licenses;
  addonLicense:
    lib.getAttr addonLicense {
      "CC-BY-3.0" = cc-by-30;
      "MIT" = mit;
      "CC-BY-NC-ND-3.0" = cc-by-nc-nd-30;
      "cc-all-rights-reserved" = unfreeRedistributable;
      "CC-BY-SA-3.0" = cc-by-sa-30;
      "MPL-2.0" = mpl20;
      "CC-BY-NC-SA-3.0" = cc-by-nc-sa-30;
      "GPL-3.0-only" = gpl3Only;
      "BSD-2-Clause" = bsd2;
      "all-rights-reserved" = unfree;
      "CC-BY-NC-3.0" = cc-by-nc-30;
      "LGPL-3.0-only" = lgpl3Only;
      "CC-BY-ND-3.0" = cc-by-nd-30;
      "CC-BY-4.0" = cc-by-40;
      "CC-BY-NC-SA-4.0" = cc-by-nc-sa-40;
      "GPL-2.0-only" = gpl2Only;
      "CC-BY-NC-ND-4.0" = cc-by-nc-nd-40;
      "Apache-2.0" = asl20;
      "CC-BY-NC-4.0" = cc-by-nc-40;
      "MPL-1.1" = mpl11;
      "Unlicense" = unlicense;
      "CC-BY-SA-4.0" = cc-by-sa-40;
      "AGPL-3.0-only" = agpl3Only;
      "LGPL-2.1-only" = lgpl21Only;
      "ISC" = isc;
    }
