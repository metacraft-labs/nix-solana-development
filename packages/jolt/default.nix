{
  rust-bin,
  craneLib-nightly,
  fetchFromGitHub,
  fetchGitHubFile,
  installSourceAndCargo,
  pkg-config,
  openssl,
  jolt-guest-rust,
  ...
}:
let
  commonArgs = rec {
    pname = "jolt";
    version = "unstable-2025-02-12";

    nativeBuildInputs = [
      pkg-config
      openssl
    ];

    preBuild = ''
      sed -i 's/%2F/\//g' $CARGO_HOME/config.toml
    '';

    src = fetchFromGitHub {
      owner = "a16z";
      repo = "jolt";
      rev = "783da5d32010e707f85085d59ae0451f6d8a6b25";
      hash = "sha256-G+27L6L7XpuEg2XUrhgsHnW/61Jwye1a4rcXorRxviU=";
      fetchSubmodules = true;
    };
  };

  rust-toolchain = rust-bin.fromRustupToolchainFile (fetchGitHubFile {
    inherit (commonArgs.src) owner repo rev;
    file = "rust-toolchain.toml";
    hash = "sha256-Fyj+Bp/dt3epuTN9kXN+r7Z3gzXYCDrcVEPWTr1sQqk=";
  });
  craneLib = craneLib-nightly.overrideToolchain rust-toolchain;
  cargoArtifacts = craneLib.buildDepsOnly commonArgs;
in
craneLib.buildPackage (
  commonArgs
  // (installSourceAndCargo rust-toolchain)
  // rec {
    inherit cargoArtifacts;

    postPatch = ''
      sed -i 's|package =.*git = "https://github.com/a16z/jolt"|path = "'$out'"|' src/main.rs
      sed -i '44,46d' jolt-core/src/host/toolchain.rs
    '';

    # Different toolchain is used when guest has std features
    # https://github.com/a16z/jolt/blob/fa45507aaddb1815bafd54332e4b14173a7f8699/jolt-core/src/host/mod.rs#L132-L134
    postInstall = ''
      rm $out/bin/cargo
      cat <<EOF > $out/bin/cargo
      #!/bin/sh
      if [ -n "\''${RUSTUP_TOOLCHAIN+x}" ]
      then
          export PATH="${jolt-guest-rust}/rust/build/host/stage2/bin:\$PATH"
      fi
      ${rust-toolchain}/bin/cargo \$@
      EOF
      chmod +x $out/bin/cargo
    '';

    doCheck = false;
  }
)
