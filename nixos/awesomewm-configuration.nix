# NixOS configuration, place this file in /etc/nixos/configuration.nix

# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nixpkgs.config.packageOverrides = pkgs: {
    # Add NUR repo.
    nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
      inherit pkgs;
    };
  };

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_zen;
    # Set boot loader.
    loader = {
      timeout = 999999;
      systemd-boot.enable = true; # Use the default systemd-boot EFI boot loader. (No GRUB UI)
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
    };
  };

  networking = {
    hostName = "MI-AIR12"; # Define your hostname.
    networkmanager.enable = true;
  };

  # Select internationalisation properties.
  i18n.inputMethod = {
    enabled = "fcitx";
    fcitx.engines = with pkgs.fcitx-engines; [anthy];
  };

  # Set your time zone.
  time = {
    timeZone = "Asia/Taipei";
    hardwareClockInLocalTime = true;
  };

  # List packages installed in system profile. To search, run:
  environment.systemPackages = with pkgs; [
    (python3.withPackages (p: [p.black p.ansible p.jupyter])) # In NixOS, pip can't install package
    vte ranger aria scrot nmap openssh neofetch p7zip qemu opencc
    git stack rustup gcc gdb clang scala dotnet-sdk podman
    xorg.xbacklight xdg-user-dirs xcompmgr networkmanagerapplet
    fcitx-configtool vlc gparted vscode google-chrome wireshark
    jetbrains.idea-ultimate syncthing thunderbird goldendict
    nur.repos.linyinfeng.clash-premium # nur.repos.linyinfeng.clash-for-windows
  ];

  # Enable feature
  programs = {
    vim.defaultEditor = true;
    java.enable = true;
    npm.enable = true;
    wireshark = {
      enable = true;
      package = pkgs.wireshark-qt;
    };
  };

  # Enable sound.
  hardware.pulseaudio.enable = true;

  # Config fonts.
  fonts = {
    enableDefaultFonts = true;
    fonts = with pkgs; [wqy_microhei noto-fonts powerline-fonts];
    fontconfig = {
      defaultFonts = {
        serif = ["Noto Sans"];
        sansSerif = ["Noto Sans"];
        monospace = ["Noto Sans Mono"];
      };
    };
  };

  # Config the X11 windowing system.
  services.xserver = {
    enable = true;
    videoDrivers = ["intel"];
    displayManager.lightdm = {
      extraConfig = "[Seat:*]\ngreeter-hide-users=false";
      greeters.gtk.extraConfig = "background=/boot/background.jpg\ntheme-name = Adwaita-dark";
    };
    libinput = {
      enable = true; # Enable touchpad support.
      touchpad.naturalScrolling = true;
    };
    windowManager.awesome = {
      enable = true;
      luaModules = [pkgs.luaPackages.vicious];
    };
  };
  systemd.services = {
    nginx.wantedBy = lib.mkForce [];
    redis.wantedBy = lib.mkForce [];
    mysql.wantedBy = lib.mkForce [];
  };
  services = {
    gnome.gnome-keyring.enable = true; # For syncing VSCode configuration.
    redis.servers."".enable = true; # Use new options for redis service instead of 'redis-enable'
    nginx.enable = true;
    mysql = {
      enable = true;
      package = pkgs.mysql80;
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = pkgs.fish;
    users.dainslef = {
      isNormalUser = true;
      extraGroups = ["wheel" "networkmanager"]; # Enable ‘sudo’ for the user.
    };
  };

  # Replace custom nixos channel:
  # sudo nix-channel --remove nixos
  # sudo nix-channel --add https://mirrors.tuna.tsinghua.edu.cn/nix-channels/nixos-unstable
  nix.settings.substituters = ["https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"];
  nixpkgs.config.allowUnfree = true;
}
