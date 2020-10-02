{ config, pkgs, lib, ... }:

{
  users.users.jsh = {
    isNormalUser = true;
    extraGroups = [ "wheel" "sudo" "docker" ];
    shell = pkgs.zsh;
  };

  virtualisation.docker.enable = true;

  security.sudo.configFile = ''
    jsh ALL=(ALL) NOPASSWD:ALL
  '';

  home-manager.users.jsh = {
    programs.home-manager.enable = true;

    programs.zsh = {
      enable = true;
      enableCompletion = true;
      #enableAutosuggestions = true;
      autocd = true;
      history = {
        extended = true;
        ignoreDups = true;
        save = 10000;
        size = 10000;
      };
      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "z"
        ];
      };
      shellAliases = {
        "x" = "exit";
        "celar" = "clear";
        "tf" = "terraform";
        "kubeclt" = "kubectl";
        "edit" = "cd /.jsh-nix";
      };
      initExtra = ''
ZSH_THEME_GIT_PROMPT_PREFIX="%{$reset_color%}%{$fg[white]%}["
ZSH_THEME_GIT_PROMPT_SUFFIX=""
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[red]%}●%{$fg[white]%}]%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_CLEAN="]%{$reset_color%} "
ZSH_THEME_SVN_PROMPT_PREFIX=$ZSH_THEME_GIT_PROMPT_PREFIX
ZSH_THEME_SVN_PROMPT_SUFFIX=$ZSH_THEME_GIT_PROMPT_SUFFIX
ZSH_THEME_SVN_PROMPT_DIRTY=$ZSH_THEME_GIT_PROMPT_DIRTY
ZSH_THEME_SVN_PROMPT_CLEAN=$ZSH_THEME_GIT_PROMPT_CLEAN
ZSH_THEME_HG_PROMPT_PREFIX=$ZSH_THEME_GIT_PROMPT_PREFIX
ZSH_THEME_HG_PROMPT_SUFFIX=$ZSH_THEME_GIT_PROMPT_SUFFIX
ZSH_THEME_HG_PROMPT_DIRTY=$ZSH_THEME_GIT_PROMPT_DIRTY
ZSH_THEME_HG_PROMPT_CLEAN=$ZSH_THEME_GIT_PROMPT_CLEAN

vcs_status() {
    if [[ $(whence in_svn) != "" ]] && in_svn; then
        svn_prompt_info
    elif [[ $(whence in_hg) != "" ]] && in_hg; then
        hg_prompt_info
    else
        git_prompt_info
    fi
}

PROMPT='%2~ $(vcs_status)'
'';
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
      configFile."../.xprofile".source = /.jsh-nix/dots/Xprofile;
      configFile."zsh/jsh.zsh-theme".source = /.jsh-nix/dots/zsh/jsh.zsh-theme;

      # Scripts
      configFile.".sf-mono/.setup".source = /.jsh-nix/scripts/sf-mono;
      configFile.".brightness".source = /.jsh-nix/scripts/brightness;

    };
  };
} 
