{
  description = "Faraday Linux — Privacy-first NixOS. Tails meets modern Hyprland.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-generators, home-manager, ... }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    # Shared module list — imported by both ISO and VM builds
    faradayModules = [
      ./modules/hardening.nix
      ./modules/networking.nix
      ./modules/desktop.nix
      ./modules/packages.nix
      ./modules/shell.nix        # Terminal environment: kitty, fastfetch, starship, fish/bash
      ./modules/installer.nix
      ./modules/branding.nix

      home-manager.nixosModules.home-manager

      # Base live-session user
      {
        users.users.faraday = {
          isNormalUser = true;
          description = "Faraday User";
          extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
          # No password — autologin for live session
          password = "";
        };

        # Autologin to Hyprland
        services.greetd = {
          enable = true;
          settings.default_session = {
            command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
            user = "faraday";
          };
        };

        # Home-manager config for the live user
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.faraday = import ./home.nix;
        };

        # Let the live user do passwordless sudo (they're on an air-gapped live session)
        security.sudo.extraRules = [{
          users = [ "faraday" ];
          commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }];
        }];

        system.stateVersion = "24.11";
      }
    ];
  in {
    packages.${system} = {
      # --- ISO build (main artifact) ---
      iso = nixos-generators.nixosGenerate {
        inherit system;
        format = "iso";
        modules = faradayModules ++ [{
          isoImage = {
            isoName = "faraday-linux-${self.shortRev or "dev"}.iso";
            squashfsCompression = "zstd -Xcompression-level 19";
            makeEfiBootable = true;
            makeUsbBootable = true;
            appendToMenuLabel = " — Faraday Privacy OS";
          };
        }];
      };

      # --- VM build for local testing (no ISO overhead) ---
      vm = nixos-generators.nixosGenerate {
        inherit system;
        format = "vm";
        modules = faradayModules;
      };
    };

    # --- nixos-rebuild target (for installed systems) ---
    nixosConfigurations.faraday = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = faradayModules;
    };
  };
}
