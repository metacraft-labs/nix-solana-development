{
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.flake-parts.flakeModules.easyOverlay
    ./all-packages.nix
  ];
  perSystem =
    {
      self',
      inputs',
      pkgs,
      system,
      ...
    }:
    let
      pkgs-with-rust-overlay =
        let
          rust-overlay = inputs.rust-overlay.overlays.default;
        in
        pkgs.extend rust-overlay;

      rust-stable = pkgs-with-rust-overlay.rust-bin.stable.latest.default.override {
        extensions = [ "rust-src" ];
        targets = [
          "wasm32-wasip1"
          "wasm32-unknown-unknown"
        ];
      };
      rust-nightly = pkgs-with-rust-overlay.rust-bin.nightly.latest.default.override {
        extensions = [ "rust-src" ];
        targets = [
          "wasm32-wasip1"
          "wasm32-unknown-unknown"
        ];
      };

      craneLib-stable = (inputs.crane.mkLib pkgs).overrideToolchain rust-stable;
      craneLib-nightly = (inputs.crane.mkLib pkgs).overrideToolchain rust-nightly;

      cardano-node = builtins.getFlake "github:input-output-hk/cardano-node/f0b4ac897dcbefba9fa0d247b204a24543cf55f6";

      reexportedPackages = {
        ethereum_nix =
          {
            # geth = inputs'.ethereum_nix.packages.geth; # TODO: re-enable when flake show/check passes
          }
          // lib.optionalAttrs (pkgs.hostPlatform.isx86 && pkgs.hostPlatform.isLinux) {
            # nimbus = inputs'.ethereum_nix.packages.nimbus-eth2; # TODO: re-enable when flake show/check passes
          };
        # noir = {
        #   nargo = inputs'.noir.packages.nargo;
        #   noirc_abi_wasm = inputs'.noir.packages.noirc_abi_wasm;
        #   acvm_js = inputs'.noir.packages.acvm_js;
        # };
      };

      disabledPackages = [
        "circ"
        "leap"
        "go-opera"
      ];
    in
    rec {
      packages = self'.legacyPackages.metacraft-labs;

      checks =
        (builtins.removeAttrs self'.legacyPackages.metacraft-labs disabledPackages)
        // reexportedPackages.ethereum_nix;
      # // reexportedPackages.noir;

      overlayAttrs = {
        inherit (self'.legacyPackages) metacraft-labs nix2container noir;
      };

      legacyPackages = {
        inherit (inputs'.nix2container.packages) nix2container;

        inherit (cardano-node.outputs.packages.${system}) cardano-node cardano-cli;

        noir = inputs'.noir.packages;
        ethereum_nix = inputs'.ethereum_nix.packages;

        inherit
          rust-stable
          rust-nightly
          craneLib-stable
          craneLib-nightly
          pkgs-with-rust-overlay
          ;

        rust-bin-2024-08-01 = inputs.rust-overlay-2024-08-01.lib.mkRustBin { } pkgs;

        rustPlatformStable = pkgs.makeRustPlatform {
          rustc = rust-stable;
          cargo = rust-stable;
        };
        rustPlatformNightly = pkgs.makeRustPlatform {
          rustc = rust-nightly;
          cargo = rust-nightly;
        };
      };
    };
}
