{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-21.05";
  };

  outputs = { nixpkgs, self }:
    let
      supportedSystems = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
      forAllSystems' = systems: fun: nixpkgs.lib.genAttrs systems fun;
      forAllSystems = forAllSystems' supportedSystems;
      pkgsForSystem = system:
        import nixpkgs { inherit system; overlays = [ self.overlays.vg ]; };
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
            pkgs = pkgsForSystem system;
          in
            pkgs.vg
        );

        packages = forAllSystems (system:
          {
            vg = self.defaultPackage.${system};
          }
        );

        apps = mapAttrs (_: v:
          mapAttrs (_: a:
            {
              type = "app";
              program = a;
            }
          ) v
        ) self.packages;

        defaultApp = mapAttrs (_: v:
          v.trydiffoscope
        ) self.apps;

        devShell = forAllSystems (system: self.packages.${system}.vg);

        hydraJobs = forAllSystems (system:
          let
            pkgs = pkgsForSystem system;
            vg = self.defaultPackage.${system};
          in
            {
              build = self.defaultPackage.${system};
              test = pkgs.runCommandNoCC "vg-test" {}
                ''
                  ${vg}/bin/vg test
                  touch $out
                '';
            }
        );
      };
}
