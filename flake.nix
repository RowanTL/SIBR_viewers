{
  description = "SIBR Viewer Flake";

  inputs = {
    # Latest stable Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgsOld.url = "github:nixos/nixpkgs/98bb5b77c8c6666824a4c13d23befa1e07210ef1";
  };

  outputs =
    { self, nixpkgs, nixpkgsOld }:
    let
      # Systems supported
      allSystems = [
        "x86_64-linux" # 64-bit Intel/AMD Linux
        # "aarch64-linux" # 64-bit ARM Linux
        # "x86_64-darwin" # 64-bit Intel macOS
        # "aarch64-darwin" # 64-bit ARM macOS
      ];

      # Helper to provide system-specific attributes
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs allSystems (
          system:
          f {
            inherit system;
            pkgs = import nixpkgs { inherit system; config = { allowUnfree = true; }; };
            pkgsOld = import nixpkgsOld { inherit system; };
          }
        );
    in
    {
      packages = forAllSystems (
        { pkgs, pkgsOld, ... }:
        {
          default =
            pkgs.stdenv.mkDerivation {
              name = "SIBR_viewers";
              src = self;
              nativeBuildInputs = with pkgs; [
                pkgsOld.cmake
                cudatoolkit
                git gitRepo gnupg autoconf curl procps gnumake util-linux m4 gperf unzip binutils pkg-config
              ];
              # https://nixos.wiki/wiki/Packaging/Quirks_and_Caveats
              buildInputs = with pkgs; [
                eigen glew assimp boost180 gtk3 opencv glfw ffmpeg_4-full libXxf86vm pkgsOld.embree
                linuxPackages.nvidia_x11 libGLU libGL freeglut zlib ncurses5 libxcb
                xorg.libXi xorg.libXmu xorg.libXext xorg.libX11 xorg.libXv xorg.libXrandr
              ];
              buildPhase = ''
                export CUDA_PATH=${pkgs.cudatoolkit}

                cmake -Bbuild . -DCMAKE_BUILD_TYPE=Release
                cmake --build build -j24 --target install
              '';
              installPhase = ''
                mkdir -p $out/bin
                cp SIBR_remoteGaussian_app $out/bin/
                cp SIBR_gaussianViewer_app $out/bin/
              '';
            };
        }
      );
      devShells = forAllSystems (
        { pkgs, pkgsOld, system }:
        {
          default = pkgs.mkShell {
            # inputsFrom automatically pulls in dependencies from your derivation
            inputsFrom = [ self.packages.${system}.default ];

            # Add extra tools here that you only need for development (not building)
            packages = with pkgs; [
              clang-tools
              gdb
              dbus
              # ccache # Optional, but often great for speeding up local C++ builds
            ];

            NIX_CFLAGS_COMPILE = "-isystem ${pkgs.eigen}/include/eigen3";

            shellHook = ''
              export CUDA_PATH=${pkgs.cudatoolkit}
            '';
          };
        }
      );
    };
}
