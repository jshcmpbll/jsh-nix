{ config, pkgs, lib, ... }:
{
  networking.firewall.checkReversePath = "loose";
  networking.nftables.enable = true;
  networking.interfaces.${config.services.tailscale.interfaceName}.useDHCP = false;
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
    # disableTaildrop = true; Future setting
    interfaceName = "tailsacle0";
  };
}
