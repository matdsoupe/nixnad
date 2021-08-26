{
  description = "nixnad";

  inputs =
    {
      home-manager = {
        url = "github:nix-community/home-manager";
        inputs.nixpkgs.follows = "unstable";
      };
      unstable.url = "github:nixos/nixpkgs/nixos-unstable";
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.05";
      nixpkgs-latest.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
      neomat= {
        url = "github:matdsoupe/neomat";
        flake = false;
      };
      emacs = {
        url = "github:nix-community/emacs-overlay";
        inputs.nixpkgs.follows = "master";
      };
      emacsmat = {
        url = "github:matdsoupe/emacsmat";
        flake = false;
      };
    };

  outputs = inputs@{ self, nixpkgs, nixpkgs-latest, home-manager, neomat, emacs, emacsmat, unstable, ... }:
  with import ./global-config.nix;

  let
    system = "x86_64-linux";
    environment-shell = ''
      function nix-repl {
        nix repl "${rootPath}/repl.nix" "$@"
      }
      export NIXPKGS_ALLOW_UNFREE=1
      export NIX_PATH=nixpkgs=${nixpkgs}:nixpkgs-overlays=${builtins.toString rootPath}/overlay.nix:nixpkgs-latest=${nixpkgs-latest}:home-manager=${home-manager}:nixos-config=${(builtins.toString rootPath) + "/nodes/$HOSTNAME/default.nix"}
    '';

    overlays = [
      (import ./overlay.nix)
      (import "${home-manager}/overlay.nix")
    ];

    pkgs = import nixpkgs-latest {
      inherit overlays system;

      config = {
        allowUnfree = true;
      };
    };
    epkgs = import unstable { system = "x86_64-linux"; overlays = [ self.overlays.emacs ]; };

    rev-module = ({ pkgs, ... }: {
      system.configurationRevision =
        if (self ? rev) then
          builtins.trace "detected flake hash: ${self.rev}" self.rev
        else
          builtins.trace "flake hash not detected!" null;
    });
  in {
    inherit pkgs overlays environment-shell;

    packages."${system}" = {
      emacs = epkgs.emacsGcc;
    };

    nixosConfigurations = {
      acer-nix = unstable.lib.nixosSystem {
	inherit pkgs system;
	modules = [
	  ./nodes/acer-nix
	  home-manager.nixosModules.home-manager {
	    home-manager = {
	      useGlobalPkgs = true;
	      useUserPackages = true;
	      users."${username}" = import ./home;
	    };
	  }
	];
      };
      bootstrap = unstable.lib.nixosSystem {
        inherit pkgs system; 
	modules = [ ./nodes/bootstrap ];
      };
    };

    dev-shell.x86_64-linux = pkgs.mkShell {
      name = "nixnad-shell";
      buildInputs = [];
      shellHook = ''
        ${environment-shell}
        echo '${environment-shell}'
        echo Shell setup complete!
      '';
    };
  };
}