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
            vg = self.defaultPackage.${system};
          }
        );

        defaultApp = self.defaultPackage;

        apss = self.packages;

        devShell = forAllSystems (system: self.packages.${system}.vg);
      };
}
