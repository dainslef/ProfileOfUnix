# COPY this file to /etc/nixos/custom-configuration.nix
# This file is just a sample.
# Change options in this file by need.

{
  networking.hostName = "MI-AIR12"; # Define your hostname.
  # Set up custom options
  custom = {
    desktop = {
      wm = true;
      kde = false;
      gnome = false;
      pantheon = false;
    };
    platform = {
      intel = true;
      amd = false;
    };
  };
}
