{
  description = "nix-blockchain-development";

  nixConfig = {
    extra-substituters = [
      "https://mcl-blockchain-packages.cachix.org"
      "https://nix-blockchain-development.cachix.org"
      "https://cache.iog.io"
    ];
    extra-trusted-public-keys = [
      "mcl-blockchain-packages.cachix.org-1:qoEiUyBgNXmgJTThjbjO//XA9/6tCmx/OohHHt9hWVY="
      "nix-blockchain-development.cachix.org-1:Ekei3RuW3Se+P/UIo6Q/oAgor/fVhFuuuX5jR8K/cdg="
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
    ];
  };

  inputs = {
    nixos-modules.url = "github:metacraft-labs/nixos-modules";

    nixpkgs.follows = "nixos-modules/nixpkgs";
    nixpkgs-unstable.follows = "nixos-modules/nixpkgs-unstable";
    flake-parts.follows = "nixos-modules/flake-parts";
    flake-utils.follows = "nixos-modules/flake-utils";
    flake-compat.follows = "nixos-modules/flake-compat";
    nix2container.follows = "nixos-modules/nix2container";
    crane.follows = "nixos-modules/crane";
    fenix.follows = "nixos-modules/fenix";
    ethereum_nix.follows = "nixos-modules/ethereum-nix";
    treefmt-nix.follows = "nixos-modules/treefmt-nix";
    devenv.follows = "nixos-modules/devenv";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay-2024-08-01 = {
      url = "github:oxalica/rust-overlay?ref=snapshot/2024-08-01";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, nixos-modules, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      imports = [
        nixos-modules.modules.flake.git-hooks
        ./packages
      ];
      perSystem =
        {
          final,
          self',
          config,
          ...
        }:
        {
          devShells.default = import ./shells/all.nix {
            pkgs = final;
            inherit self';
          };
          devShells.ci = import ./shells/ci.nix {
            pkgs = final;
            inherit config;
          };
          devShells.nexus = import ./shells/nexus.nix { pkgs = final; };
          devShells.jolt = import ./shells/jolt.nix { pkgs = final; };
          devShells.zkm = import ./shells/zkm.nix { pkgs = final; };
          devShells.zkwasm = import ./shells/zkwasm.nix { pkgs = final; };
          devShells.sp1 = import ./shells/sp1.nix { pkgs = final; };
          devShells.risc0 = import ./shells/risc0.nix { pkgs = final; };
        };
    };
}
