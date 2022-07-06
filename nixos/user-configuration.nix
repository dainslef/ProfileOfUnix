# COPY this file to /etc/nixos/user-configuration.nix
# This file is just a sample.
# Change options in this file by need.

{
  # Set user custom options.
  custom = {
    desktop = {
      wm = false;
      kde = false;
      xfce = false;
      gnome = false;
      pantheon = false;
    };
    platform = {
      intel = false;
      amd = false;
    };
  };

  # Set device-specific configurations.
  networking.hostName = "YOUR-PC-NAME"; # Define your hostname.
  boot.loader.systemd-boot.consoleMode = "keep"; # Default is "keep", set value to "max" when device has HDPI.
  hardware.video.hidpi.enable = false; # Enable if device has HDPI.
  services = {
    fprintd.enable = false; # Enable if the device has finger print support.
    xserver.dpi = null; # Set the DPI, the default value is 96.
  };

  # System partitons.
  swapDevices =[{ device = "/dev/xxx"; }];
  fileSystems = {
    # Device path can use deivce block file or uuid.
    "/" = { device = "/dev/disk/by-uuid/xxx"; fsType = "btrfs"; };
    "/boot" = { device = "/dev/xxx"; fsType = "vfat"; };
  };

  # For company environment.
  networking.extraHosts = "x.x.x.x xxx-hostname";
  virtualisation.docker.daemon.settings = {
    insecure-registries = ["x.x.x.x1" "x.x.x.x2"];
  };
}
