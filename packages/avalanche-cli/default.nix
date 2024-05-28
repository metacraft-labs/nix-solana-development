{pkgs}:
with pkgs;
  buildGoModule rec {
    pname = "avalanche-cli";
    version = "1.5.3";

    src = fetchFromGitHub {
      rev = "v${version}";
      sha256 = "sha256-1SID5Xvg9jQhm5As2oeECH8nRz1HYF2bwVIV7RTqdU8=";
      owner = "ava-labs";
      repo = "avalanche-cli";
    };

    doCheck = false;
    proxyVendor = true;
    vendorHash = "sha256-uj2wopJZO5aA9FPN864R3o0xsYQdzrHziEAFuJB6Rsc=";

    meta = with lib; {
      description = "Avalanche CLI is a command line tool that gives developers access to everything Avalanche.";
      homepage = "https://github.com/ava-labs/avalanche-cli";
      license = licenses.lgpl3;
    };
  }
