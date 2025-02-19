{
  rust-bin-2024-08-01,
  craneLib-nightly,
  fetchFromGitHub,
  fetchGitHubFile,
  clang,
  lld,
  cmake,
  ...
}:
let
  commonArgs = rec {
    pname = "zkWasm";
    version = "unstable-2024-10-19";

    nativeBuildInputs = [
      clang
      lld
      cmake
    ];

    src = fetchFromGitHub {
      owner = "DelphinusLab";
      repo = "zkWasm";
      rev = "f5acf8c58c32ac8c6426298be69958a6bea2b89a";
      hash = "sha256-3+ptucjczxmA0oeeokxdVRRSdJLuoRjX31hMk5+FlZM=";
      fetchSubmodules = true;
    };
  };

  craneLib = craneLib-nightly.overrideToolchain (
    rust-bin-2024-08-01.fromRustupToolchainFile (fetchGitHubFile {
      inherit (commonArgs.src) owner repo rev;
      file = "rust-toolchain";
      hash = "sha256-gHLj2AMKnStjvZcowfe9ZdTnwOBUPCRADmv81H7dAak=";
    })
  );

  cargoArtifacts = craneLib.buildDepsOnly commonArgs;
in
craneLib.buildPackage (
  commonArgs
  // rec {
    inherit cargoArtifacts;

    doCheck = false;
  }
)
