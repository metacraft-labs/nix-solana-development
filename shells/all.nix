{
  pkgs,
  self',
}:
with pkgs;
let
  example-container = nix2container.buildImage {
    name = "example";
    tag = "latest";
    config = {
      entrypoint = [
        "${pkgs.figlet}/bin/figlet"
        "MCL"
      ];
    };
  };
in
mkShell {
  packages =
    [
      # For priting the direnv banner
      figlet

      # For formatting Nix files
      alejandra

      # Packages defined in this repo
      metacraft-labs.cosmos-theta-testnet
      metacraft-labs.bnb-beacon-node
      metacraft-labs.circom

      metacraft-labs.circ

      metacraft-labs.go-opera

      metacraft-labs.polkadot
      metacraft-labs.polkadot-fast

      # noir
      # self'.legacyPackages.noir.nargo
      # self'.legacyPackages.noir.noirc_abi_wasm
      # self'.legacyPackages.noir.acvm_js

      # ethereum.nix
      self'.legacyPackages.ethereum_nix.geth

      # avalanche cli
      metacraft-labs.avalanche-cli

      # Node.js related
      metacraft-labs.corepack-shims
    ]
    ++ lib.optionals (stdenv.hostPlatform.isx86) [
      metacraft-labs.rapidsnark

      # Cardano
      metacraft-labs.cardano
    ]
    ++ lib.optionals (stdenv.hostPlatform.isx86 && stdenv.isLinux) [
      # Rapidsnark depends on Pistache, which supports only Linux, see
      # https://github.com/pistacheio/pistache/issues/6#issuecomment-242398225
      # for more information
      metacraft-labs.rapidsnark-server

      # Ethereum
      self'.legacyPackages.ethereum_nix.nimbus

      # Test nix2container
      example-container.copyToDockerDaemon
    ]
    ++ lib.optionals (!stdenv.isDarwin) [
      # Solana is still not compatible with macOS on M1
      # metacraft-labs.solana
      metacraft-labs.wasmd

      # Disabled until elrond-go can build with Go >= 1.19
      # Elrond
      # metacraft-labs.cryptography36
      # metacraft-labs.erdpy
      # metacraft-labs.elrond-go
      # metacraft-labs.elrond-proxy-go

      # EOS
      metacraft-labs.leap
      metacraft-labs.eos-vm
      metacraft-labs.cdt

      # py-ecc
      metacraft-labs.py-ecc

      # emscripten
      metacraft-labs.emscripten
    ];

  shellHook = ''
    figlet -w$COLUMNS "nix-blockchain-development"
  '';
}
