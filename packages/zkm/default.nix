{
  zkm-rust,
  craneLib-nightly,
  fetchFromGitHub,
  installSourceAndCargo,
  fetchzip,
  pkg-config,
  openssl,
  ...
}:
let
  commonArgs = rec {
    pname = "zkm";
    version = "unstable-2025-02-20";

    nativeBuildInputs = [
      pkg-config
      openssl
    ];

    # https://crane.dev/faq/no-cargo-lock.html
    cargoLock = ./Cargo.lock;

    src = fetchFromGitHub {
      owner = "zkMIPS";
      repo = "zkm";
      rev = "98a1a4e1a0dbb447f8ba4619627ed8888098e4bf";
      hash = "sha256-oNdrN1BD6u2f8oimKEnJnEgHhweh12Hw8yPD3juyQbc=";
    };
  };

  rust-toolchain = zkm-rust;
  craneLib = craneLib-nightly.overrideToolchain rust-toolchain;
  cargoArtifacts = craneLib.buildDepsOnly commonArgs;
in
craneLib.buildPackage (
  commonArgs
  // (installSourceAndCargo rust-toolchain)
  // rec {
    inherit cargoArtifacts;

    postInstall = ''
      rm "$out"/bin/cargo
      cat <<EOF > "$out"/bin/cargo
      #!/usr/bin/env sh
      : \''${RUST_LOG:=info}
      : \''${BASEDIR:='$out'}
      : \''${SEG_SIZE:=65536}
      : \''${ARGS:='2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824 hello'}
      : \''${SEG_OUTPUT:='/tmp/output'}
      : \''${SEG_FILE_DIR:='/tmp/output'}
      LD_LIBRARY_PATH="\''${LD_LIBRARY_PATH-}:${openssl.out}/lib"
      export RUST_LOG BASEDIR SEG_SIZE ARGS SEG_OUTPUT SEG_FILE_DIR LD_LIBRARY_PATH
      ${rust-toolchain}/bin/cargo \$@
      EOF
      chmod +x "$out"/bin/cargo
    '';

    doCheck = false;
  }
)
