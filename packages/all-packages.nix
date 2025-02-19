{ ... }:
{
  perSystem =
    {
      pkgs,
      self',
      ...
    }:
    let
      inherit (pkgs)
        lib
        darwin
        hostPlatform
        symlinkJoin
        fetchFromGitHub
        ;
      inherit (pkgs.lib) optionalAttrs callPackageWith;
      inherit (self'.legacyPackages)
        rustPlatformStable
        craneLib-stable
        craneLib-nightly
        cardano-node
        cardano-cli
        pkgs-with-rust-overlay
        rust-bin-2024-08-01
        ;
      python3Packages = pkgs.python3Packages;

      callPackage = callPackageWith (pkgs // { rustPlatform = rustPlatformStable; });
      darwinPkgs = {
        inherit (darwin.apple_sdk.frameworks)
          CoreFoundation
          Foundation
          Security
          SystemConfiguration
          ;
      };

      # RapidSnark
      ffiasm-src = callPackage ./ffiasm-src/default.nix { };
      zqfield = callPackage ./ffiasm/zqfield.nix {
        inherit ffiasm-src;
      };
      # Pairing Groups on BN-254, aka alt_bn128
      # Source:
      # https://zips.z.cash/protocol/protocol.pdf (section 5.4.9.1)
      # See also:
      # https://eips.ethereum.org/EIPS/eip-196
      # https://eips.ethereum.org/EIPS/eip-197
      # https://hackmd.io/@aztec-network/ByzgNxBfd
      # https://hackmd.io/@jpw/bn254
      zqfield-bn254 = symlinkJoin {
        name = "zqfield-bn254";
        paths = [
          (zqfield {
            primeNumber = "21888242871839275222246405745257275088696311157297823662689037894645226208583";
            name = "Fq";
          })
          (zqfield {
            primeNumber = "21888242871839275222246405745257275088548364400416034343698204186575808495617";
            name = "Fr";
          })
        ];
      };
      ffiasm = callPackage ./ffiasm/default.nix {
        inherit ffiasm-src zqfield-bn254;
      };
      rapidsnark = callPackage ./rapidsnark/default.nix {
        inherit ffiasm zqfield-bn254;
      };

      # Elrond / MultiversX
      # copied from https://github.com/NixOS/nixpkgs/blob/8df7949791250b580220eb266e72e77211bedad9/pkgs/development/python-modules/cryptography/default.nix
      cattrs22-2 = pkgs.python3Packages.cattrs.overrideAttrs (
        finalAttrs: previousAttrs: {
          version = "22.2.0";

          src = fetchFromGitHub {
            owner = "python-attrs";
            repo = "cattrs";
            rev = "v22.2.0";
            hash = "sha256-Qnrq/mIA/t0mur6IAen4vTmMIhILWS6v5nuf+Via2hA=";
          };

          patches = [ ];
        }
      );
      cryptography36 = callPackage ./python-modules/cryptography36/default.nix { };

      py-ecc = callPackage ./python-modules/py-ecc/default.nix {
        inherit (python3Packages)
          buildPythonPackage
          cached-property
          eth-typing
          eth-utils
          mypy-extensions
          pytestCheckHook
          pythonOlder
          ;
      };

      ledgercomm = callPackage ./python-modules/ledgercomm/default.nix { };
      requests-cache = callPackage ./python-modules/requests-cache/default.nix { inherit cattrs22-2; };

      corepack-shims = callPackage ./corepack-shims/default.nix { };

      erdpy = callPackage ./erdpy/default.nix {
        inherit
          cryptography36
          elrond-go
          elrond-proxy-go
          ledgercomm
          requests-cache
          ;
      };
      elrond-go = callPackage ./elrond-go/default.nix { };
      elrond-proxy-go = callPackage ./elrond-proxy-go/default.nix { };

      graphql = callPackage ./graphql/default.nix { inherit cardano-cli cardano-node; };
      cardano = callPackage ./cardano/default.nix { inherit cardano-cli cardano-node graphql; };

      polkadot-generic = callPackage ./polkadot/default.nix {
        craneLib = craneLib-stable;
        inherit (darwin) libiconv;
        inherit (darwinPkgs)
          CoreFoundation
          Security
          SystemConfiguration
          ;
      };
      polkadot = polkadot-generic { };
      polkadot-fast = polkadot-generic { enableFastRuntime = true; };

      fetchGitHubFile =
        {
          owner,
          repo,
          rev,
          file,
          hash,
        }:
        pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/${owner}/${repo}/${rev}/${file}";
          inherit hash;
        };

      fetchGitHubReleaseAsset =
        {
          owner,
          repo,
          tag,
          asset,
          hash,
        }:
        pkgs.fetchzip {
          url = "https://github.com/${owner}/${repo}/releases/download/${tag}/${asset}";
          inherit hash;
          stripRoot = false;
        };

      installSourceAndCargo = rust-toolchain: rec {
        installPhaseCommand = ''
          mkdir -p "$out"/bin
          # Install source code
          cp -r /build/source/. "$out"
          # Install cargo commands
          ln -s "${rust-toolchain}"/bin/* "$out"/bin/
          # Install binaries
          for result in target/release/*
          do
            [ "''${result:15:5}" != 'crane' -a -f "$result" -a -x "$result" ] \
              && ln -s "$out/$result" "$out"/bin/
          done
        '';
      };

      args-zkVM = {
        inherit (pkgs-with-rust-overlay) rust-bin;
        inherit craneLib-nightly;
        inherit fetchGitHubFile;
        inherit installSourceAndCargo;
        inherit rust-bin-2024-08-01;
      };

      args-zkVM-rust = {
        inherit fetchGitHubReleaseAsset;
      };
    in
    {
      legacyPackages.metacraft-labs =
        rec {
          gaiad = callPackage ./gaiad { };
          cosmos-theta-testnet = callPackage ./cosmos-theta-testnet { inherit gaiad; };
          blst = callPackage ./blst { };
          bnb-beacon-node = callPackage ./bnb-beacon-node { };

          circom = callPackage ./circom/default.nix { craneLib = craneLib-stable; };
          circ = callPackage ./circ/default.nix { craneLib = craneLib-stable; };

          emscripten = pkgs.emscripten.overrideAttrs (_old: {
            postInstall = ''
              pushd $TMPDIR
              echo 'int __main_argc_argv( int a, int b ) { return 42; }' >test.c
              for MEM in "-s ALLOW_MEMORY_GROWTH" ""; do
                for LTO in -flto ""; do
                  # FIXME: change to the following, once binaryen is updated to
                  # >= v119 in Nixpkgs:
                  # for OPT in "-O2" "-O3" "-Oz" "-Os"; do
                  for OPT in "-O2"; do
                    $out/bin/emcc $MEM $LTO $OPT -s WASM=1 -s STANDALONE_WASM test.c
                  done
                done
              done
            '';
          });

          go-opera = callPackage ./go-opera/default.nix { };

          circom_runtime = callPackage ./circom_runtime/default.nix { };

          # Polkadot
          inherit polkadot polkadot-fast;

          avalanche-cli = callPackage ./avalanche-cli/default.nix {
            inherit blst;
          };

          inherit corepack-shims;
        }
        // lib.optionalAttrs hostPlatform.isLinux rec {
          kurtosis = callPackage ./kurtosis/default.nix { };

          wasmd = callPackage ./wasmd/default.nix { };

          # Solana
          # solana-validator = callPackage ./solana-validator {};

          # inherit cryptography36;

          inherit py-ecc;
          # inherit erdpy elrond-go elrond-proxy-go;

          # EOS / Antelope
          leap = callPackage ./leap/default.nix { };
          eos-vm = callPackage ./eos-vm/default.nix { };
          cdt = callPackage ./cdt/default.nix { };

          zkwasm = callPackage ./zkwasm/default.nix args-zkVM;
          jolt-guest-rust = callPackage ./jolt-guest-rust/default.nix args-zkVM-rust;
          jolt = callPackage ./jolt/default.nix (args-zkVM // { inherit jolt-guest-rust; });
          zkm-rust = callPackage ./zkm-rust/default.nix args-zkVM-rust;
          zkm = callPackage ./zkm/default.nix (args-zkVM // { inherit zkm-rust; });
          nexus = callPackage ./nexus/default.nix args-zkVM;
          sp1-rust = callPackage ./sp1-rust/default.nix args-zkVM-rust;
          sp1 = callPackage ./sp1/default.nix (args-zkVM // { inherit sp1-rust; });
          risc0-rust = callPackage ./risc0-rust/default.nix args-zkVM-rust;
          risc0 = callPackage ./risc0/default.nix (args-zkVM // { inherit risc0-rust; });
        }
        // lib.optionalAttrs hostPlatform.isx86 rec {
          inherit
            zqfield-bn254
            ffiasm
            ffiasm-src
            rapidsnark
            ;

          inherit cardano graphql;
        }
        // lib.optionalAttrs (hostPlatform.isx86 && hostPlatform.isLinux) rec {
          pistache = callPackage ./pistache/default.nix { };
          inherit zqfield-bn254;
          rapidsnark-server = callPackage ./rapidsnark-server/default.nix {
            inherit
              ffiasm
              zqfield-bn254
              rapidsnark
              pistache
              ;
          };
        };
    };
}
