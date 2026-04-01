{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    stm32cubeide-src.url = "git+https://git.sr.ht/~shelvacu/stm32cubeide-nix";
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    stm32cubeide-src,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];

      perSystem = {system, ...}: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            stm32cubeide-src.overlays.default
            (final: prev: {
              stm32cubeide = prev.stm32cubeide.overrideAttrs (old: {
                buildInputs =
                  (old.buildInputs or [])
                  ++ [
                    final.qt6.qtwayland
                    final.qt6.qtbase
                    final.libxkbcommon
                  ];

                autoPatchelfIgnoreMissingDeps =
                  (old.autoPatchelfIgnoreMissingDeps or [])
                  ++ [
                    "libQt6WaylandEglClientHwIntegration.so.6"
                    "libxerces-c-3.2.so"
                    "libavcodec-ffmpeg.so.56"
                    "libavformat-ffmpeg.so.56"
                    "libavcodec.so.54"
                    "libavformat.so.54"
                    "libavcodec.so.56"
                    "libavformat.so.56"
                    "libavcodec.so.57"
                    "libavformat.so.57"
                    "libavcodec.so.59"
                    "libavformat.so.59"
                  ];
              });
            })
          ];
        };
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            stm32cubeide
            clang-tools
            bear
          ];
        };
      };
    };
}
