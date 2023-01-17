{
  description = "Ema template app";
  # Remove this after GHC 9.2 gets into nixpkgs pkgs.haskellPackages
  nixConfig = {
    extra-substituters = "https://cache.srid.ca";
    extra-trusted-public-keys = "cache.srid.ca:8sQkbPrOIoXktIwI0OucQBXod2e9fDjjoEZWn8OXbdo=";
  };
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    haskell-flake.url = "github:srid/haskell-flake";
    flake-root.url = "github:srid/flake-root";
    proc-flake.url = "github:srid/proc-flake";
    mission-control.url = "github:Platonic-Systems/mission-control";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    # Libs
    org-mode-hs.url = "github:lucasvreis/org-mode-hs";
    org-mode-hs.flake = false;
    multiwalk.url = "github:lucasvreis/multiwalk";
    multiwalk.flake = false;
  };
  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.haskell-flake.flakeModule
        inputs.flake-root.flakeModule
        inputs.treefmt-nix.flakeModule
        inputs.proc-flake.flakeModule
        inputs.mission-control.flakeModule
      ];
      perSystem = { self', config, inputs', pkgs, lib, ... }: {
        # "haskellProjects" comes from https://github.com/srid/haskell-flake
        haskellProjects.main = {
          packages.gro.root = ./.;
          buildTools = hp:
            let
              # Workaround for https://github.com/NixOS/nixpkgs/issues/140774
              fixCyclicReference = drv:
                pkgs.haskell.lib.overrideCabal drv (_: {
                  enableSeparateBinOutput = false;
                });
            in
            {
              inherit (pkgs.haskellPackages)
                tailwind;
              treefmt = config.treefmt.build.wrapper;

              ghcid = fixCyclicReference hp.ghcid;
              haskell-language-server = hp.haskell-language-server.overrideScope (lself: lsuper: {
                ormolu = fixCyclicReference hp.ormolu;
              });
            } // config.treefmt.build.programs;
          overrides = self: super: with pkgs.haskell.lib; {
            slugify = dontCheck (unmarkBroken super.slugify);
            shower = self.callHackage "shower" "0.2.0.3" { };
          };
          source-overrides = {
            inherit (inputs) multiwalk;
            org-parser = inputs.org-mode-hs + /org-parser;
          };
        };
        treefmt.config = {
          inherit (config.flake-root) projectRootFile;
          package = pkgs.treefmt;

          programs.ormolu.enable = true;
          programs.nixpkgs-fmt.enable = true;
          programs.cabal-fmt.enable = true;

          # We use fourmolu
          programs.ormolu.package = pkgs.haskellPackages.fourmolu;
          settings.formatter.ormolu = {
            options = [
              "--ghc-opt"
              "-XImportQualifiedPost"
            ];
          };
        };

        proc.groups.run.processes = {
          haskell.command = "ghcid";
          tailwind.command = "${lib.getExe pkgs.haskellPackages.tailwind} -w -o ./static/tailwind.css './src/**/*.hs'";
        };
        mission-control.scripts = {
          docs = {
            description = "Start Hoogle server for project dependencies";
            exec = ''
              echo http://127.0.0.1:8888
              hoogle serve -p 8888 --local
            '';
            category = "Dev Tools";
          };
          repl = {
            description = "Start the cabal repl";
            exec = ''
              cabal repl "$@"
            '';
            category = "Dev Tools";
          };
          fmt = {
            description = "Auto-format the source tree";
            exec = "${lib.getExe config.treefmt.build.wrapper}";
            category = "Dev Tools";
          };
          run = {
            description = "Run the dev server (ghcid + tailwind)";
            exec = config.proc.groups.run.package;
            category = "Primary";
          };
        };
        packages =
          let
            buildEmaSiteWithTailwind = { baseUrl }:
              pkgs.runCommand "site"
                { }
                ''
                  mkdir -p $out
                  pushd ${self}
                  ${lib.getExe config.packages.main-gro} \
                    --base-url=${baseUrl} gen $out
                  ${lib.getExe pkgs.haskellPackages.tailwind} \
                    -o $out/tailwind.css 'src/**/*.hs'
                '';
          in
          {
            default = config.packages.main-gro;
            #site = buildEmaSiteWithTailwind { baseUrl = "/"; };
            #site-github = buildEmaSiteWithTailwind { baseUrl = "/gro/"; };
          };
        devShells.default = config.mission-control.installToDevShell config.devShells.main;
      };

      # CI configuration
      flake.herculesCI.ciSystems = [ "x86_64-linux" "aarch64-darwin" ];
    };
}
