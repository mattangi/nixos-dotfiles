{
  description = "Nixos for Kevin";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      # linux specific
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-greeter = {
      # linux specific
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      # community run hardware configurations.  I am using this for thinkpad t14s amd gen4
      url = "github:Nixos/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    superfile = {
      # the latest version of superfile.  cross platform.  linux, nix-darwin
      url = "github:yorukot/superfile";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      superfile,
      ...
    }@inputs:
    {
      nixosConfigurations.thinkpad = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/thinkpad
          inputs.noctalia.nixosModules.default
          inputs.noctalia-greeter.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.mattangi = {
                imports = [
                  inputs.noctalia.homeModules.default
                  ./users/mattangi/home.nix
                ];
              };
              backupFileExtension = "backup";
            };
          }
        ];
      };
    };
}
