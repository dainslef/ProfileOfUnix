# NixOS main configuration, LINK this file to /etc/nixos/configuration.nix

# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include other configurations.
      ./custom-configuration.nix
      /etc/nixos/user-configuration.nix
      # Include system generate hardware configurations.
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
    # kernelPackages = pkgs.linuxPackages_zen;
    kernelPackages = pkgs.linuxPackages_latest;
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
      allProxy = "127.0.0.1:9999";
      httpProxy = "http://127.0.0.1:9999";
      httpsProxy = "http://127.0.0.1:9999";
    };
    # NixOS enabled firewall by default, so need to allow some ports.
    firewall.allowedTCPPorts = [
      9999 # For Clash service.
      8384 # For Syncthing WEB UI.
      22000 # For Syncthing data transmission.
    ];
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
    (python3.withPackages (p: [p.black p.jupyter p.ansible-core]))
    # Developer tools
    binutils gcc gdb clang lldb rustup cmake gnumake # C/C++/Rust compiler and build tools
    jdk scala visualvm dotnet-sdk # Java and .Net SDK
    git stack nodejs kubectl # Other develop tools
    vscode jetbrains.idea-ultimate # IDE/Editor
    # Android Tools
    android-tools android-file-transfer
    # Normal tools
    file tree usbutils pciutils btop # Base CLI tools
    nmap openssh neofetch p7zip qemu opencc syncthing # Service and command line tools
    vlc gparted gimp google-chrome thunderbird goldendict blender bottles # GUI tools
    # Man pages (POSIX API and C++ dev doc)
    man-pages-posix stdmanpages
    # Clash
    nur.repos.linyinfeng.clash-premium # nur.repos.linyinfeng.clash-for-windows
    # Wechat
    nur.repos.xddxdd.wechat-uos
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
    # Setup user service.
    user.services.clash = {
      # Define a custom clash service.
      wantedBy = ["default.target"];
      after = ["network.target"];
      description = "Start clash service";
      serviceConfig = {
        ExecStart = "/run/current-system/sw/bin/clash-premium &";
        ExecStop = "/run/current-system/sw/bin/kill -9 clash-premium";
      };
    };
  };

  # Config fonts.
  fonts = {
    enableDefaultFonts = true;
    fonts = with pkgs; [cascadia-code noto-fonts noto-fonts-cjk-sans];
    fontconfig = {
      defaultFonts = {
        serif = ["Noto Sans"];
        sansSerif = ["Noto Sans"];
        monospace = ["Cascadia Code PL"];
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

  system = {
    # Set up system.stateVersion to avoid config not set warning.
    # Use default system.stateVersion config will get warning since this commit https://github.com/NixOS/nixpkgs/commit/e2703d269756d27cff92ecb61c6da9d68ad8fdf8.
    stateVersion = config.system.nixos.release;
    # Execute custom scripts when rebuild NixOS configuration.
    activationScripts.text = "
      # Create custom bash symbol link (/bin/bash) for compatibility with most Linux scripts.
      ln -sf /bin/sh /bin/bash
    ";
  };

  nixpkgs.config.allowUnfree = true; # Allow some unfree software (like vscode and chrome).
  nix = {
    autoOptimiseStore = true; # Enable nix store auto optimise.
    # Replace custom nixos channel with TUNA mirror:
    # sudo nix-channel --add https://mirrors.tuna.tsinghua.edu.cn/nix-channels/nixos-unstable
    # or use USTC Mirror:
    # https://mirrors.ustc.edu.cn/nix-channels/nixos-unstable
    settings.substituters = [ # Binary Cache Mirror
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    ];
  };
}
