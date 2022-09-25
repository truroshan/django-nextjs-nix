{
    description = "Django Website";
    
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        flake-utils.url = "github:numtide/flake-utils";
    };

    outputs = {self, nixpkgs, flake-utils,...}:
    
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system}; 

        poetryManager = pkgs.poetry.overrideAttrs ( oldAttrs: rec {
            projectDir = src;
            python = pkgs.python39;
            src = pkgs.fetchFromGitHub {
                owner = "python-poetry";
                repo = "poetry";
                rev = "1.1.15";
                sha256 = "sha256-BRWBgCn3a8AmD3i5edAIwRahLuN2uI0pb15WvGuLXAY=";
            };
        }
        );

        djangoEnv = pkgs.poetry2nix.mkPoetryEnv {   
            projectDir = ./.;
            python = pkgs.python39;
            };
        djangoBuild = pkgs.stdenv.mkDerivation {
            name = "django-example";
            src = ./.;
            buildInputs = [  djangoEnv pkgs.postgresql ];
            installPhase = ''
              python manage.py migrate
              python manage.py collectstatic
              cp -r . $out
            '';
          };
      
        djangoApp = pkgs.buildEnv {
                name ="django-example";
                paths = [
                    pkgs.bash
                    pkgs.postgresql
                    djangoEnv
                    djangoBuild
                ];
            };

        djangoAppImage = pkgs.dockerTools.buildImage {
                name = "djangoapp";
                tag = "stable";
                copyToRoot = [
                    djangoApp
                ];
                config = {
                    Cmd = [
                        "gunicorn"
                        "--bind" 
                        "0.0.0.0:8080"
                        "--env" 
                        "DJANGO_SETTINGS_MODULE=core.settings" 
                        "core.wsgi:application" ];
                };
            };

      
      in rec {

        packages.djangoApp = djangoApp;
        packages.djangoAppImage = djangoAppImage;

        devShells.default = pkgs.mkShell {
            packages = [ poetryManager ];
        };
      }
    );
}