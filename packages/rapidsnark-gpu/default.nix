{
  lib,
  cudaPackages,
  stdenv,
  ffiasm,
  zqfield-bn254,
  nlohmann_json,
  gmp,
  libsodium,
  cmake,
  fetchFromGitHub,
  pkg-config,
}: let
  ffiasm-c = "${ffiasm}/lib/node_modules/ffiasm/c";
in
  stdenv.mkDerivation rec {
    pname = "rapidsnark-gpu";
    version = "2023-04-08";

    src = fetchFromGitHub {
      owner = "Orbiter-Finance";
      repo = "rapidsnark";
      rev = "77016322808ac58a3acd25a6235510b55172f967";
      hash = "sha256-8vy+iXkSINFregve+rej1rXyXdWxm0n1wvYfoy/0idk=";
    };

    nativeBuildInputs = [pkg-config];
    buildInputs = [nlohmann_json gmp libsodium cudaPackages.cudatoolkit] ++ ffiasm.passthru.openmp;

    buildPhase = ''
      mkdir -p $out/bin
      c++ \
        -I{${ffiasm-c},${zqfield-bn254}/lib} \
        ./src/{main_prover,binfile_utils,zkey_utils,wtns_utils,logger}.cpp \
        ${ffiasm-c}/{alt_bn128,misc,naf,splitparstr}.cpp \
        ${zqfield-bn254}/lib/{fq,fr}.{cpp,o} \
        $(pkg-config --cflags --libs libsodium gmp nlohmann_json) \
        -std=c++17 -pthread -O3 -fopenmp \
        -o $out/bin/prover
    '';

    installPhase = ''
      # Already done in buildPhase
    '';

    meta = {
      homepage = "https://github.com/iden3/rapidsnark";
      platforms = with lib.platforms; linux ++ darwin;
    };
  }
