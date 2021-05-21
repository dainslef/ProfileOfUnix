# NixOS configuration, place this file in /etc/nixos/configuration.nix

# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Set boot loader.
  boot.loader = {
    # systemd-boot.enable = true; # Use the default systemd-boot EFI boot loader. (No GRUB UI)
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
    grub = {
      efiSupport = true;
      useOSProber = true;
      device = "nodev";
    };
  };

  networking = {
    hostName = "MI-AIR12"; # Define your hostname.
    networkmanager.enable = true;
    # wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    # proxy.default = "http://user:password@proxy:port/";  # Configure network proxy if necessary
    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";
    # useDHCP = false;
    # interfaces.wlp1s0.useDHCP = true;
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
    dotnet-sdk ntfs3g xorg.xbacklight xcompmgr
    openssh neofetch stack rustup git gcc gdb p7zip scala fcitx-configtool
    gnome2.vte ranger aria scrot
    vlc vscode google-chrome
    haskellPackages.xmobar
    jetbrains.idea-ultimate
  ];

  # Enable feature
  programs = {
    java.enable = true;
    npm.enable = true;
    wireshark = {
      enable = true;
      package = pkgs.wireshark-qt;
    };
    vim.defaultEditor = true;
  };

  # Enable sound.
  hardware.pulseaudio.enable = true;

  # Enable the X11 windowing system.
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable the X11 windowing system.
  # Enable Desktop Environment.
  services.xserver = {
    enable = true;
    libinput = {
      enable = true; # Enable touchpad support.
      touchpad.naturalScrolling = true;
    };
    # displayManager.lightdm.autoLogin = {
    #  enable = true;
    #  user = "dainslef";
    # };
    videoDrivers = ["intel"];
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
      extraGroups = ["wheel" "networkmanager"]; # Enable ‘sudo’ for the user.
    };
  };

  # This value determines the NixOS release from which the default settings for stateful data.
  # system.stateVersion = "20.03"; # Did you read the comment?

  nixpkgs.config.allowUnfree = true;
  nix.binaryCaches = ["https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"];
}
