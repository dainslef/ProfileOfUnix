# This config provide the custom option definitions
# and custom settings according to the custom option values.

{ lib, pkgs, config, ... }:

with lib; {
  # Use 'options' object to define custom options.
  options = {
    custom = {
      # Use mk* fuctions to define custom options.
      desktop = {
        wm = mkEnableOption "wm";
        kde = mkEnableOption "kde";
        xfce = mkEnableOption "xfce";
        gnome = mkEnableOption "gnome";
        pantheon = mkEnableOption "pantheon";
      };
      platform = {
        amd = mkEnableOption "amd";
        intel = mkEnableOption "intel";
      };
      extraPackages = with types; mkOption {
        type = listOf package;
        default = [];
      };
    };
  };

  # Custom releation configurations.
  config = mkMerge [
    (mkIf config.custom.platform.intel {
      services.xserver = {
        # Intel driver haven't been updated in years.
        videoDrivers = ["modesetting"];
        useGlamor = true;
      };
    })
    (mkIf config.custom.platform.amd {
      # Newer AMD CPU require "amdgpu" kernel module.
      boot.initrd.kernelModules = ["amdgpu"];
      services.xserver.videoDrivers = ["amdgpu"];
    })
    (mkIf (config.custom.desktop.gnome || config.custom.desktop.pantheon) {
      # Set up the input method.
      i18n.inputMethod = {
        # Use ibus for Gnome and Pantheon.
        enabled = "ibus";
        ibus.engines = with pkgs.ibus-engines; [libpinyin mozc];
      };
    })
    (mkIf (!(config.custom.desktop.gnome || config.custom.desktop.pantheon)) {
      services.gnome.gnome-keyring.enable = true; # For syncing VSCode configuration.
      i18n.inputMethod = {
        # Use fcitx5 for most desktop/wm.
        enabled = "fcitx5";
        fcitx5.addons = with pkgs; [fcitx5-chinese-addons fcitx5-mozc];
      };
    })
    (mkIf config.custom.desktop.wm {
      # Csutom packages for window manager.
      custom.extraPackages = with pkgs; [
        xdg-user-dirs picom networkmanagerapplet vte ranger ueberzug flameshot
        brightnessctl # For brightness control.
        dunst # Provide notification (some WM like Qtile and XMonad don't have a built-in notification service).
      ];
      services.xserver = {
        # Start xdg autostart service when only use window manager (No desktop environment).
        desktopManager.runXdgAutostartIfNone = true;
        # Set up display manager.
        displayManager.lightdm.greeters.gtk.extraConfig = "background=/boot/background.jpg";
        windowManager = {
          # Enable Qtile.
          qtile.enable = true;
          # Enable AwesomeWM.
          awesome = {
            enable = true;
            luaModules = [pkgs.luaPackages.vicious];
          };
        };
      };
    })
    (mkIf config.custom.desktop.kde {
      # Custom packages for KDE.
      custom.extraPackages = with pkgs; [
        libsForQt5.yakuake libsForQt5.sddm-kcm
      ];
      services.xserver = {
        displayManager.sddm.enable = true; # Plasma use SDDM as display manager.
        desktopManager.plasma5 = {
          enable = true;
          phononBackend = "vlc"; # Use VLC as media backend.
        };
      };
    })
    (mkIf config.custom.desktop.gnome {
      programs.gnome-terminal.enable = true;
      # Custom packages for GNOME.
      custom.extraPackages = with pkgs.gnome; [
        nautilus file-roller eog gnome-system-monitor
      ];
      services.gnome = {
        core-utilities.enable = false; # Disable useless default Gnome apps.
        chrome-gnome-shell.enable = true;
      };
      services.xserver = {
        displayManager.gdm.enable = true; # Gnome use GDM as display manager.
        desktopManager.gnome.enable = true;
      };
    })
    (mkIf config.custom.desktop.pantheon {
      services.pantheon.apps.enable = false;
      # Custom packages for GNOME.
      custom.extraPackages = with pkgs.pantheon; [
        elementary-terminal elementary-files
      ];
      services.xserver = {
         # Patheon use custom lightdm greeter.
        displayManager.lightdm.greeters.pantheon.enable = true;
        desktopManager.pantheon.enable = true;
      };
    })
    (mkIf config.custom.desktop.xfce {
      # Set the Xfce GTK themes.
      # Other good GTK themes: arc-theme whitesur-gtk-theme
      custom.extraPackages = with pkgs; [ant-theme mojave-gtk-theme];
      services.xserver = {
        desktopManager.xfce.enable = true;
        displayManager.lightdm.greeters.gtk.enable = true;
      };
    })
  ];
}
