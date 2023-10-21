{
  inputs = {
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    naersk = {
      url = "github:nmattia/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = {
    self,
    fenix,
    flake-utils,
    naersk,
    nixpkgs,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      toolchain = with fenix.packages.${system};
        combine [
          complete.clippy
          complete.llvm-tools-preview
          complete.rust-src
          default.rustfmt
          default.cargo
          default.rustc
          targets."thumbv7em-none-eabihf".latest.rust-std
        ];
    in let
      uf2conv = pkgs.callPackage ./nix/pkgs/uf2conv {};
    in {
      devShell = pkgs.mkShell {
        nativeBuildInputs = [
          pkgs.cargo-binutils
          pkgs.elf2uf2-rs
          pkgs.hidrd
          pkgs.just
          pkgs.rust-analyzer
          pkgs.usbutils
          pkgs.probe-rs
          pkgs.stlink
          toolchain
          uf2conv
        ];
        RUSTC = "${toolchain}/bin/rustc";
        RUST_SRC_PATH = "${toolchain}/lib/rustlib/src";
        CARGO_BUILD_TARGET = "thumbv7em-none-eabihf";
        CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER = "${pkgs.pkgsCross.aarch64-multiplatform.stdenv.cc}/bin/thumbv7em-none-eabihf-gcc";
      };

      packages = let
        stm32f4-bins = [
          "rgoulter-stm32f401-blinky"
        ];
      in rec {
        firmware-stm32f4-elf = let
          target = "thumbv7em-none-eabihf";
        in
          (naersk.lib.${system}.override {
            cargo = toolchain;
            rustc = toolchain;
          })
          .buildPackage {
            src = ./.;
            CARGO_BUILD_TARGET = target;
            CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER = "${pkgs.pkgsCross.aarch64-multiplatform.stdenv.cc}/bin/${target}-gcc";
          };

        firmware-bin = pkgs.runCommand "firmware-bin" {} ''
          mkdir -p $out/bin
          export RUSTC=${toolchain}/bin/rustc

          env PATH=$PATH:${pkgs.cargo-binutils}/bin \
            ${pkgs.gnumake}/bin/make \
              --file ${./Makefile} \
              STM32F4_RELEASE_TARGET_DIR=${firmware-stm32f4-elf}/bin \
              DEST_DIR=$out/bin \
              ${nixpkgs.lib.concatStringsSep " " (map (x: "$out/bin/${x}.bin") stm32f4-bins)}
        '';

        firmware-uf2 = pkgs.runCommand "" {} ''
          mkdir -p $out/bin

          cp ${firmware-bin}/bin/*.bin $out/bin

          env PATH=$PATH:${uf2conv}/bin \
            ${pkgs.gnumake}/bin/make \
              --file ${./Makefile} \
              STM32F4_RELEASE_TARGET_DIR=${firmware-stm32f4-elf}/bin \
              DEST_DIR=$out/bin \
              ${nixpkgs.lib.concatStringsSep " " (map (x: "$out/bin/${x}.uf2") stm32f4-bins)}

          rm $out/bin/*.bin
        '';
      };
    });
}
