# COPY this file to /etc/nixos/custom-configuration.nix
# This file is just a sample.

{
  # Set up custom options
  custom = {
    desktop.wm = true;
    platform.intel = true;
  };
}
