{ config, pkgs, lib, ... }:

{
  users.users.jsh = {
    isNormalUser = true;
    extraGroups = [ "wheel" "sudo" "audio" ];
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
        "edit" = "cd /home/jsh/git/jsh-nix";
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
''
+
''
function gi {
  curl -L -s https://www.gitignore.io/api/$@ ;
}
''
+
''
function extract {
   if [ -z "$1" ]; then
      # display usage if no parameters given
      echo "Usage: extract <path/file_name>.<zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|ex|tar.bz2|tar.gz|tar.xz>"
   else
      if [ -f $1 ] ; then
          # NAME=''${1%.*}
          # mkdir $NAME && cd $NAME
          case $1 in
            *.tar.bz2)   tar xvjf ../$1    ;;
            *.tar.gz)    tar xvzf ../$1    ;;
            *.tar.xz)    tar xvJf ../$1    ;;
            *.lzma)      unlzma ../$1      ;;
            *.bz2)       bunzip2 ../$1     ;;
            *.rar)       unrar x -ad ../$1 ;;
            *.gz)        gunzip ../$1      ;;
            *.tar)       tar xvf ../$1     ;;
            *.tbz2)      tar xvjf ../$1    ;;
            *.tgz)       tar xvzf ../$1    ;;
            *.zip)       unzip ../$1       ;;
            *.Z)         uncompress ../$1  ;;
            *.7z)        7z x ../$1        ;;
            *.xz)        unxz ../$1        ;;
            *.exe)       cabextract ../$1  ;;
            *)           echo "extract: '$1' - unknown archive method" ;;
          esac
      else
          echo "$1 - file does not exist"
      fi
  fi
}
''
+
''
function open {  
  case $1 in
  *.mp3 | *.flac | *.wav)
  	mpv --no-video "$1"
  	;;
  
  *.mp4 | *.mkv | *.webm)
  	mpv "$1"
  	;;
  
  *.png | *.gif | *.jpg | *.jpe | *.jpeg)
  	sxiv "$1"
  	;;
  
  *.pdf | *.epub)
  	zathura "$1"
  	;;

  *)
  	"${EDITOR:=nvim}" "$1"
  	;;
  esac
}
''
+
''
function xc {
  xclip -sel copy
}

function xp {
  xclip -o -sel clip
}
'';
    };

    xdg = {
      enable = true;
    
      # Dot Files
      configFile."../.vimrc".source = /home/jsh/git/jsh-nix/dots/vimrc;
      configFile."i3/i3status.conf".source = /home/jsh/git/jsh-nix/dots/i3/i3status.conf;
      configFile."i3/config".source = /home/jsh/git/jsh-nix/dots/i3/config;
      configFile."../.Xresources".source = /home/jsh/git/jsh-nix/dots/Xresources;
      configFile."../.tmux.conf".source = /home/jsh/git/jsh-nix/dots/tmux.conf;
      configFile."polybar/config.ini".source = /home/jsh/git/jsh-nix/dots/polybar/config.ini;
      configFile."polybar/launch.sh".source = /home/jsh/git/jsh-nix/dots/polybar/launch.sh;
      configFile."rofi/config".source = /home/jsh/git/jsh-nix/dots/rofi/config;
      configFile."nixpkgs/config.nix".source = /home/jsh/git/jsh-nix/dots/nixpkgs/config.nix;
      configFile."picom/picom.conf".source = /home/jsh/git/jsh-nix/dots/picom/picom.conf;
      configFile."dunst/dunstrc".source = /home/jsh/git/jsh-nix/dots/dunst/dunstrc;
      configFile."../.xprofile".source = /home/jsh/git/jsh-nix/dots/Xprofile;
      configFile."zsh/jsh.zsh-theme".source = /home/jsh/git/jsh-nix/dots/zsh/jsh.zsh-theme;
      #configfile."../.aws/cli/alias".source = /home/jsh/git/jsh-nix/dots/aws/cli/alias;

      # Scripts
      configFile.".sf-mono/.setup".source = /home/jsh/git/jsh-nix/scripts/sf-mono;
      configFile.".brightness".source = /home/jsh/git/jsh-nix/scripts/brightness;
      configFile."screenshots/copy-img".source = /home/jsh/git/jsh-nix/scripts/copy-img;
      configFile."../.jumpd".source = /home/jsh/git/jsh-nix/scripts/jumpd;

    };
  };
} 
