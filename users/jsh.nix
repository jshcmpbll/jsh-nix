{ config, pkgs, lib, ... }:

{
  users.users.jsh = {
    uid = 1000; # setting for x11vnc auth
    isNormalUser = true;
    extraGroups = [ "wheel" "sudo" "audio" "pulse-access" "docker" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB29bu0cfW5fIIISVOycKIfEpfAekl9BDfAvea62QgfL"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINfK7f1WvpQRhhB6UFeTOY5cB5uCzHFgP1DZZMwf75WZ"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM04fFl5hQ7ALKclvE4t/StWeCr2woQxLPd0xqimKPla"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDXVBd7IcaNgtZrAPFiQKQAkTt0uFzbxYBl0qIAHSBlz"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICF/mh2HQ/a/n0z5tCa/8F67unG/wYJfuj/jAFGijnYA" # Mobile
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICpO6ZQcBd/Hq3qJDKePcdYDEmXqQf6V7DcCXnK0tC+2" # Mobile Shortcuts
    ];
  };
  security.sudo.wheelNeedsPassword = false;
}
