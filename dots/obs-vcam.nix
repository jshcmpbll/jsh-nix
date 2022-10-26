{ config, ... }:
{
  boot = {
    extraModulePackages = with config.boot.kernelPackages;
      [ v4l2loopback.out ];
    kernelModules = [ "v4l2loopback" ];
    extraModprobeConfig = ''
      options v4l2loopback video_nr=10 exclusive_caps=1 card_label="Camera"
    '';
  };
}
