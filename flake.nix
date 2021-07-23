{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-21.05";
  };

  outputs = { nixpkgs, self }:
    let
      supportedSystems = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
      forAllSystems' = systems: fun: nixpkgs.lib.genAttrs systems fun;
      forAllSystems = forAllSystems' supportedSystems;
    in
      with nixpkgs.lib;
      {
        overlays.vg = final: prev:
          {
            vg = final.callPackage ./vg.nix { protobuf = final.protobuf3_13; };
          };

        overlay = self.overlays.vg;

        defaultPackage = forAllSystems (system:
          let
            pkgs = import nixpkgs { inherit system; overlays = [ self.overlays.vg ]; };
          in
            pkgs.vg
        );

        packages = forAllSystems (system:
          {
            vita = self.defaultPackage.${system};
          }
        );

        devShell = forAllSystems (system:
          let
            pkgs = import nixpkgs { inherit system; overlays = mapAttrsToList (_: id) self.overlays; };
          in
            pkgs.mkShell {
              nativeBuildInputs = with pkgs;
                [ git pkg-config protobuf
                  (callPackage ./arch.nix {}) which perl flex
                  cmake automake autoconf bison
                ];
              buildInputs = with pkgs;
                [ ncurses.dev
                  jansson
                  cairo
                  pcre.dev
                  xorg.libpthreadstubs
                  xorg.libXdmcp
                  libtool
                  utillinux
                  curl.dev
                  libxml2
                  libxslt.dev
                  bzip2 lzma zlib.static
                  boost
                ];
            }
        );
      };
}
