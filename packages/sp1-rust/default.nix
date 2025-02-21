{
  stdenv,
  fetchGitHubReleaseAsset,
  autoPatchelfHook,
  zlib,
  ...
}:
stdenv.mkDerivation rec {
  name = "sp1-rust";
  version = "1.82.0";

  nativeBuildInputs = [
    autoPatchelfHook
    stdenv.cc.cc.lib
    zlib
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r ./* $out/
    runHook postInstall
  '';

  src = fetchGitHubReleaseAsset {
    owner = "succinctlabs";
    repo = "rust";
    tag = "v${version}";
    asset = "rust-toolchain-x86_64-unknown-linux-gnu.tar.gz";
    hash = "sha256-3Vs11CLDXaxAJuP/UsWeznJjjsNvVZqKIra5KzldoIk=";
  };
}
