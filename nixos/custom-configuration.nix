# COPY this file to /etc/nixos/custom-configuration.nix
# This file is just a sample.
# Change options in this file by need.

{
  networking.hostName = "YOUR-PC-NAME"; # Define your hostname.
  # Set up custom options
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
}
