# NixOS configuration, place this file in /etc/nixos/configuration.nix

# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
    ];

  nixpkgs.config.packageOverrides = pkgs: {
    # Add NUR repo.
    nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
      inherit pkgs;
    };
  };

  # Set up boot options.
  boot = {
    # Set the custom linux kernel.
    kernelPackages = pkgs.linuxKernel.packages.linux_zen;
    # Set boot loader.
    loader = {
      timeout = 999999;
      systemd-boot.enable = true; # Use the default systemd-boot EFI boot loader. (No GRUB UI)
      efi.canTouchEfiVariables = true;
    };
  };

  # Set up networking.
  networking = {
    hostName = "MI-AIR12"; # Define your hostname.
    networkmanager.enable = true;
    proxy = { # Set up proxy (for Clash).
      allProxy = "localhost:9999";
      httpProxy = "localhost:9999";
      httpsProxy = "localhost:9999";
    };
  };

  # Config input method.
  i18n.inputMethod = {
    # Use ibus for Gnome, use fcitx5 for other desktop/wm.
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [fcitx5-chinese-addons fcitx5-mozc];
  };

  # Set your time zone.
  time = {
    timeZone = "Asia/Taipei";
    hardwareClockInLocalTime = true;
  };

  # Container and VM.
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true; # Create a `docker` alias for podman
    };
  };

  # Set up some programs' feature.
  programs = {
    vim.defaultEditor = true; # Set up default editor.
    wireshark.enable = true; # Enable wireshark and create wireshark group (Let normal user can use wireshark).
  };

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    # In NixOS, pip can't install package, set up pip package in configuration
    (python3.withPackages (p: [p.black p.ansible p.jupyter]))
    # Developer tools
    git kubectl stack rustup gcc gdb clang lldb scala nodejs dotnet-sdk jdk android-tools
    vscode jetbrains.idea-ultimate
    # Normal tools
    aria nmap openssh neofetch p7zip qemu opencc syncthing
    vlc gparted google-chrome thunderbird goldendict
    nur.repos.linyinfeng.clash-premium # nur.repos.linyinfeng.clash-for-windows
    # For window manager
    xorg.xbacklight xdg-user-dirs picom networkmanagerapplet scrot vte ranger
    dunst # Provide notification (some WM like Qtile and XMonad don't have a built-in notification service)
  ];

  # Config services.
  services = {
    gnome.gnome-keyring.enable = true; # For syncing VSCode configuration.
    redis.servers."".enable = true; # Use new options for redis service instead of 'redis-enable'.
    nginx.enable = true;
    postgresql.enable = true;
    mysql = {
      enable = true;
      package = pkgs.mysql80;
    };
  };
  systemd = {
    extraConfig = "DefaultTimeoutStopSec=5s"; # Set shutdown max systemd service stop timeout.
    # Disable autostart of some service
    services = {
      nginx.wantedBy = lib.mkForce [];
      redis.wantedBy = lib.mkForce [];
      mysql.wantedBy = lib.mkForce [];
      postgresql.wantedBy = lib.mkForce [];
    };
  };

  # Config fonts.
  fonts = {
    enableDefaultFonts = true;
    fonts = with pkgs; [noto-fonts-cjk-sans powerline-fonts];
    fontconfig = {
      defaultFonts = {
        serif = ["Noto Sans"];
        sansSerif = ["Noto Sans"];
        monospace = ["DejaVu Sans Mono"];
      };
    };
  };

  # Enable sound.
  hardware.pulseaudio.enable = true;

  # Enable GUI, config the X11 windowing system.
  services.xserver = {
    enable = true;
    videoDrivers = ["intel"];
    displayManager.lightdm.greeters.gtk.extraConfig = "background=/boot/background.jpg";
    libinput = {
      enable = true; # Enable touchpad support.
      touchpad.naturalScrolling = true;
    };
    # Enable Qtile
    windowManager.qtile.enable = true;
    # Enable AwesomeWM
    windowManager.awesome = {
      enable = true;
      luaModules = [pkgs.luaPackages.vicious];
    };
    # Enable XMonad
    windowManager.xmonad = {
      enable = true;
      enableContribAndExtras = true;
      extraPackages = p: [p.xmobar];
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = pkgs.fish;
    users.dainslef = {
      isNormalUser = true;
      # Enable sudo/network/wireshark permission for normal user.
      extraGroups = ["wheel" "networkmanager" "wireshark"];
    };
  };

  # Replace custom nixos channel with TUNA mirror:
  # sudo nix-channel --add https://mirrors.tuna.tsinghua.edu.cn/nix-channels/nixos-unstable
  # or use USTC Mirror:
  # https://mirrors.ustc.edu.cn/nix-channels/nixos-unstable
  nix.settings.substituters = ["https://mirrors.ustc.edu.cn/nix-channels/store"];
  nixpkgs.config.allowUnfree = true;

  # Execute custom scripts when rebuild NixOS configuration.
  system.activationScripts.text = "
    # Create custom bash symbol link (/bin/bash) for compatibility with most Linux scripts.
    ln -sf /bin/sh /bin/bash
  ";
}
