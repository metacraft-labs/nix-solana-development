{
  sp1-rust,
  craneLib-nightly,
  fetchFromGitHub,
  fetchGitHubFile,
  installSourceAndCargo,
  pkg-config,
  openssl,
  ...
}:
let
  commonArgs = rec {
    pname = "sp1";
    version = "unstable-2025-02-19";

    nativeBuildInputs = [
      pkg-config
      openssl
    ];

    src = fetchFromGitHub {
      owner = "succinctlabs";
      repo = "sp1";
      rev = "7864c6637d1e4c472d8c58ebf6e3b62c801d3ebe";
      hash = "sha256-El3Z/YjIKn1VPELQAO9sjGpF2qxmjjE9ywMtUaiiYvs=";
      fetchSubmodules = true;
    };
  };

  rust-toolchain = sp1-rust;
  craneLib = craneLib-nightly.overrideToolchain rust-toolchain;
  cargoArtifacts = craneLib.buildDepsOnly commonArgs;
in
craneLib.buildPackage (
  commonArgs
  // (installSourceAndCargo rust-toolchain)
  // rec {
    inherit cargoArtifacts;

    cargoBuildCommand = "cargo build --release -p sp1-cli";

    doCheck = false;
  }
)
