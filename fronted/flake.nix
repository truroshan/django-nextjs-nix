{
    description = "NextJS Website";
    
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        flake-utils.url = "github:numtide/flake-utils";
    };

    outputs = {self, nixpkgs, flake-utils,...}:
    
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system}; 

        yarnManager = pkgs.callPackage (pkgs.fetchFromGitHub {
            owner = "serokell";
            repo = "nix-npm-buildpackage";
            rev = "881f4bfa68e33cd0fb69e6b739fb92f8d0bbe37e";
            sha256 = "0wqmxijinm9mjcm3n5id13phmapqcxcrxwi106wvg0krca3ki58x";
            }) {};

        nextApp = yarnManager.buildYarnPackage { 
          pname = "nextApp";
          version = "0.1.0";
          src = pkgs.nix-gitignore.gitignoreSourcePure [ ./.gitignore ] ./.;
          buildInputs = with pkgs; [
            pkgs.nodejs
          ];
          yarnBuild = "
          yarn install
          yarn build
          ";

          fixupPhase = "
          mv .next $out/
          ";
        };

        nextAppImage = pkgs.dockerTools.buildImage {
          name = "nextapp";
          tag = "stable";
          copyToRoot = [
            nextApp
            pkgs.bash
          ];
          config = {
            Cmd = [ "yarn" "start" ];
          };
        };

      in rec {

        packages.nextApp = nextApp;
        packages.nextAppImage = nextAppImage;


        devShells.default = pkgs.mkShell {
            packages = [ pkgs.nodejs pkgs.yarn ];
        };

      }
    );
}