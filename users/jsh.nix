{ config, pkgs, lib, ... }:

{
  users.users.jsh = {
    isNormalUser = true;
    extraGroups = [ "wheel" "sudo" "audio" "docker" ];
    shell = pkgs.zsh;
  };

  security.sudo.configFile = ''
    jsh ALL=(ALL) NOPASSWD:ALL
  '';

  home-manager.users.jsh = {

    programs = {

      home-manager.enable = true;

      vim = {
        enable = true;
        plugins = with pkgs.vimPlugins; [
          vimtex
          #ultisnips
          goyo-vim
          vim-surround
          limelight-vim
        ];
        extraConfig = (lib.strings.fileContents /home/jsh/.config/vimrc);
      };

      zsh = {
        enable = true;
        enableCompletion = true;
        #enableAutosuggestions = true;
        autocd = true;
        history = {
          extended = true;
          ignoreDups = true;
          save = 1000000;
          size = 1000000;
        };
        oh-my-zsh = {
          enable = true;
          plugins = [
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
            *.[mM][pP]3 | *.[fF][lL][aA][cC] | *.[wW][aA][vV])
            # mp3 flac wav
              mpv --no-video "$1"
              ;;
  
            *.[mM][pP]4 | *.[mM][kK][vV] | *.[wW][eE][bB][mM] | *.[mM][oO][vV])
            # mp4 mkv webm mov
              mpv "$1"
              ;;
  
            *.[pP][nN][gG] | *.[gG][iI][fF] | *.[jJ][pP][gG] | *.[jJ][pP][eE] | *.[jJ][pP][eE][gG])
            # png gif jpg jpe jpeg
              sxiv "$1"
              ;;
  
            *.[pP][dD][fF] | *.[eE][pP][uU][bB])
            # pdf epub
              zathura "$1"
              ;;

            *.[hH][tT][mM][lL])
            # html
              chromium "$1"
              ;;

            *[mM][dD])
            # md
              grip -b "$1"
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
        ''
        +
        ''
          function xp {
            xclip -o -sel clip
          }
        ''
        +
        ''
          function gp {
            CURRENT=$(git rev-parse --abbrev-ref HEAD)
            DEFAULT=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)
            if [ $CURRENT = $DEFAULT ] ; then
              git pull --rebase
            else
              git checkout $DEFAULT; git pull --rebase; git checkout $CURRENT; git rebase $DEFAULT; git rebase $DEFAULT; echo "Recommend running: git push origin $CURRENT -f"
              echo "git push origin $CURRENT -f" >> $HISTFILE
            fi
          }
        ''
        +
        ''
          function gc {
            git commit -m "$1"
          }
        ''
        +
        ''
          function gr {
          git rebase -i HEAD~$1
          }
        ''
        +
        ''
          function gs {
          git status
          }
        ''
        +
        ''
          function gf {
          git add .
          git commit -m "f"
          git rebase -i HEAD~$1
          }
        ''
        +
        ''
          function geoloc {
          curl -s "https://geo.ipify.org/api/v1?apiKey=at_q1SwFLqdSx2d0BHZLP5RuxVJCqJeq&ipAddress=$1" | jq
          }
        ''
        +
        ''
          function mm {
            echo "See you soon love!"
            while true; do
              i3-msg workspace 9 -q
              sleep $(( $RANDOM % 240 + 40 ))
              i3-msg workspace 1 -q
              sleep $(( $RANDOM % 240 + 40 ))
            done
          }
        '';
      };
    };

    xdg = {
      enable = true;

      # Dot Files
      configFile."vimrc".source = /home/jsh/git/jsh-nix/dots/vimrc;
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
