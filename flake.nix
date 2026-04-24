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
        arm = pkgs.pkgsCross.arm-embedded.buildPackages;
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            stm32cubeide
            stlink
            openocd
            clang-tools
            bear
            usbutils

            arm.gdb
            arm.binutils
            arm.gcc

            (pkgs.writeShellScriptBin "debug" ''
              openocd -f interface/stlink.cfg -f target/stm32f4x.cfg &
              sleep 1
              arm-none-eabi-gdb -ex "target extended-remote localhost:3333" "$1"
              pkill openocd
            '')
            (pkgs.writeShellScriptBin "flash" ''
              CUBE_DIR=${stm32cubeide}
              PLUGIN_DIR="$CUBE_DIR/share/stm32cubeide/plugins"
              TOOLCHAIN_DIR=$(ls -d $PLUGIN_DIR/com.st.stm32cube.ide.mcu.externaltools.gnu-tools-for-stm32.*/tools/bin 2>/dev/null | head -1)
              if [ -z "$TOOLCHAIN_DIR" ]; then
                echo "ST toolchain not found inside $PLUGIN_DIR"
                exit 1
              fi
              export PATH="$TOOLCHAIN_DIR:$PATH"
              pushd led/Debug
              # find . -type f -exec sed -i 's/-fcyclomatic-complexity//g' {} \;
              make clean
              make -j12 all
              openocd -f interface/stlink.cfg -f target/stm32f4x.cfg -c "program led.elf verify reset exit"
              popd
            '')
          ];
        };
      };
    };
}
