# NixOS main configuration, LINK this file to /etc/nixos/configuration.nix

# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
      /etc/nixos/custom-configuration.nix
      ./custom-definition.nix
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
    networkmanager.enable = true;
    proxy = { # Set up proxy (for Clash).
      allProxy = "localhost:9999";
      httpProxy = "localhost:9999";
      httpsProxy = "localhost:9999";
    };
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
      dockerCompat = true; # Create a `docker` alias for podman.
    };
  };

  # Set up some programs' feature.
  programs = {
    fish.enable = true; # Enable fish feature will set up environment shells (/etc/shells) for Account Service.
    vim.defaultEditor = true; # Set up default editor.
    wireshark = {
      enable = true; # Enable wireshark and create wireshark group (Let normal user can use wireshark).
      package = pkgs.wireshark; # Use wireshark-qt as wireshark package (Default package is wireshark-cli).
    };
  };

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    # In NixOS, pip can't install package, set up pip package in configuration.
    (python3.withPackages (p: [p.black p.ansible p.jupyter]))
    # Developer tools
    gcc gdb clang lldb cmake rustup # C/C++/Rust compiler and build tools
    jdk scala android-tools dotnet-sdk # Java and .Net SDK
    git kubectl stack nodejs # Other develop tools
    vscode jetbrains.idea-ultimate # IDE/Editor
    # Normal tools
    aria nmap openssh neofetch p7zip qemu opencc syncthing wine # Service and command line tools
    vlc gparted gimp google-chrome thunderbird goldendict blender # GUI tools
    # Man pages (POSIX API and C++ dev doc)
    man-pages-posix stdmanpages
    # Clash
    nur.repos.linyinfeng.clash-premium # nur.repos.linyinfeng.clash-for-windows
  ] ++ config.custom.extraPackages;

  # Config services.
  services = {
    redis.servers."".enable = true; # Use new options for redis service instead of 'redis-enable'.
    nginx.enable = true;
    postgresql.enable = true;
    mysql = {
      enable = true;
      package = pkgs.mysql80;
    };
    # Enable GUI, config the X11 windowing system.
    xserver = {
      enable = true; # Must enable xserver for desktop environments.
      libinput = {
        enable = true; # Enable touchpad support.
        touchpad.naturalScrolling = true;
      };
    };
  };
  systemd = {
    # Set shutdown max systemd service stop timeout.
    extraConfig = "DefaultTimeoutStopSec=5s";
    # Disable autostart of some service.
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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = pkgs.fish;
    users.dainslef = {
      isNormalUser = true;
      # Enable sudo/network/wireshark permission for normal user.
      extraGroups = ["wheel" "networkmanager" "wireshark"];
    };
  };

  # Execute custom scripts when rebuild NixOS configuration.
  system.activationScripts.text = "
    # Create custom bash symbol link (/bin/bash) for compatibility with most Linux scripts.
    ln -sf /bin/sh /bin/bash
  ";

  # Replace custom nixos channel with TUNA mirror:
  # sudo nix-channel --add https://mirrors.tuna.tsinghua.edu.cn/nix-channels/nixos-unstable
  # or use USTC Mirror:
  # https://mirrors.ustc.edu.cn/nix-channels/nixos-unstable
  nix.settings.substituters = ["https://mirrors.ustc.edu.cn/nix-channels/store"];
  nixpkgs.config.allowUnfree = true;
}
