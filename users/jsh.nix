{ config, pkgs, lib, ... }:

{
  users.users.jsh = {
    isNormalUser = true;
    extraGroups = [ "wheel" "sudo" "audio" "pulse-access" "docker" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB29bu0cfW5fIIISVOycKIfEpfAekl9BDfAvea62QgfL"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINfK7f1WvpQRhhB6UFeTOY5cB5uCzHFgP1DZZMwf75WZ"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM04fFl5hQ7ALKclvE4t/StWeCr2woQxLPd0xqimKPla"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDXVBd7IcaNgtZrAPFiQKQAkTt0uFzbxYBl0qIAHSBlz"
    ];
  };
  security.sudo.wheelNeedsPassword = false;
}
