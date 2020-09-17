{ config, pkgs, lib, ... }:

{
  users.users.jsh = {
    isNormalUser = true;
    extraGroups = [ "wheel" "sudo" ];
    shell = pkgs.zsh;
  };

  security.sudo.configFile = ''
    jsh ALL=(ALL) NOPASSWD:ALL
  '';

  home-manager.users.jsh = {
    programs.home-manager.enable = true;

    programs.zsh = {
      enable = true;
      enableCompletion = true;
    };

    xdg = {
      enable = true;
    
      # Dot Files
      configFile."../.vimrc".source = /.jsh-nix/dots/vimrc;
      configFile."i3/i3status.conf".source = /.jsh-nix/dots/i3/i3status.conf;
      configFile."i3/config".source = /.jsh-nix/dots/i3/config;
      configFile."../.Xresources".source = /.jsh-nix/dots/Xresources;
      configFile."../.tmux.conf".source = /.jsh-nix/dots/tmux.conf;
      configFile."polybar/config.ini".source = /.jsh-nix/dots/polybar/config.ini;
      configFile."polybar/launch.sh".source = /.jsh-nix/dots/polybar/launch.sh;
      configFile."rofi/config".source = /.jsh-nix/dots/rofi/config;
      configFile."nixpkgs/config.nix".source = /.jsh-nix/dots/nixpkgs/config.nix;
      configFile."picom/picom.conf".source = /.jsh-nix/dots/picom/picom.conf;
      configFile."dunst/dunstrc".source = /.jsh-nix/dots/dunst/dunstrc;



      # Scripts
      configFile.".sf-mono/.setup".source = /.jsh-nix/scripts/sf-mono;
      configFile.".brightness".source = /.jsh-nix/scripts/brightness;

    };
  };
} 
