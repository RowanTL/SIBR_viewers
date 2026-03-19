{
  description = "SIBR Viewer Flake";

  inputs = {
    # Latest stable Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgsOld.url = "github:nixos/nixpkgs/98bb5b77c8c6666824a4c13d23befa1e07210ef1";
  };

  outputs =
    { self, nixpkgs }:
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
            pkgs = import nixpkgs { inherit system; };
          }
        );
      # cmake322 = fetchGit
    in
    {
      packages = forAllSystems (
        { pkgs, ... }:
        {
          default =
            pkgs.stdenv.mkDerivation {
              name = "SIBR_viewers";
              src = self;
              nativeBuildInputs = with pkgs; [
                glew
                assimp
                boost188
                gtk3
                opencv
                glfw
                ffmpeg
                eigen
                libXxf86vm
                embree
                gcc
                cmake
                pkg-config
              ];
              # https://discourse.nixos.org/t/how-to-add-pkg-config-file-to-a-nix-package/8264
              buildInputs = with pkgs; [ git assimp dbus ] ;
              buildPhase = ''
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
        { pkgs, system }:
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
          };
        }
      );
    };
}
