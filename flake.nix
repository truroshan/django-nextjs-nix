{
    description = "Example Website";
    
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        flake-utils.url = "github:numtide/flake-utils";

        fronted.url = "path:./fronted";
        backend.url = "path:./backend";


    };

    outputs = {self, nixpkgs, flake-utils,fronted,backend,...}:
    
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system}; 
      in rec {

        packages.nextApp              = fronted.packages.${system}.nextApp;
        packages.nextAppImage         = fronted.packages.${system}.nextAppImage;

        packages.djangoApp            = backend.packages.${system}.djangoApp;
        packages.djangoAppImage       = backend.packages.${system}.djangoAppImage;


        devShells.default = pkgs.mkShell {
            packages = [ pkgs.nodejs-18_x ];
        };

      }
    );
}