{pkgs}:
with pkgs;
  buildNpmPackage rec {
    pname = "circom_runtime";
    version = "0.1.25";
    src = fetchFromGitHub {
      owner = "iden3";
      repo = "circom_runtime";
      rev = "v${version}";
      hash = "sha256-l/Zsfbzrj24mKANaKuE3WHBB2G2WC+v+o2LGeQ3SgAQ=";
    };

    npmDepsHash = "sha256-JJuQX5nC59ANvu2S3545HfJB3TSEPKoEjPfpo5Ie06o=";

    nativeBuildInputs = with pkgs; [gtest nodejs];

    buildInputs = with pkgs; [];

    meta = with lib; {
      homepage = "https://github.com/iden3/circom_runtime";
      platforms = with platforms; linux ++ darwin;
    };
  }
