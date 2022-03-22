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
        gnome = mkEnableOption "gnome";
        pantheon = mkEnableOption "pantheon";
      };
      platform = {
        amd = mkEnableOption "amd";
        intel = mkEnableOption "intel";
      };
      extraPackages = with types; mkOption { type = listOf package; };
    };
  };

  # Custom releation configurations.
  config = mkMerge [
    (mkIf config.custom.platform.intel {
      services.xserver.videoDrivers = ["intel"];
    })
    (mkIf config.custom.platform.amd {
      boot.initrd.kernelModules = ["amdgpu"];
      services.xserver.videoDrivers = ["amdgpu"];
    })
    (mkIf (config.custom.desktop.gnome || config.custom.desktop.pantheon) {
      # Config input method.
      i18n.inputMethod = {
        # Use ibus for Gnome and Pantheon
        enabled = "ibus";
        ibus.engines = with pkgs.ibus-engines; [libpinyin mozc];
      };
    })
    (mkIf (!(config.custom.desktop.gnome || config.custom.desktop.pantheon)) {
      services.gnome.gnome-keyring.enable = true; # For syncing VSCode configuration.
      # Config input method.
      i18n.inputMethod = {
        # Use fcitx5 for most desktop/wm.
        enabled = "fcitx5";
        fcitx5.addons = with pkgs; [fcitx5-chinese-addons fcitx5-mozc];
      };
    })
    (mkIf config.custom.desktop.wm {
      custom.extraPackages = with pkgs; [
        # For window manager
        xorg.xbacklight xdg-user-dirs picom networkmanagerapplet scrot vte ranger ueberzug
        dunst # Provide notification (some WM like Qtile and XMonad don't have a built-in notification service)
      ];
      services.xserver = {
        # Set up display manager
        displayManager.lightdm.greeters.gtk.extraConfig = "background=/boot/background.jpg";
        # Enable Qtile
        windowManager.qtile.enable = true;
        # Enable AwesomeWM
        windowManager.awesome = {
          enable = true;
          luaModules = [pkgs.luaPackages.vicious];
        };
      };
    })
  ];
}
