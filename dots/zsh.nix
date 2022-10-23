{ pkgs, ... }:
{
  users.extraUsers.root.shell = pkgs.zsh;
  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      histSize = 1000000;
      ohMyZsh = {
        enable = true;
        plugins = [
          "z"
          "1password"
          "ag"
          "branch"
          "aws"
          "kubectl"
          "kubectx"
        ];
      };
      shellAliases = {
        "x" = "exit";
        "celar" = "clear";
        "tf" = "terraform";
        "kubeclt" = "kubectl";
        "edit" = "cd /home/jsh/git/jsh-nix/";
        "nixfmt" = "nixpkgs-fmt";
        "osbuild" = "nix build .#nixosConfigurations.$(hostname).config.system.build.toplevel";
        "osinstall" = "./result/bin/switch-to-configuration switch";
        "osup" = "osbuild;osinstall";
      };
      shellInit = ''
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
          *[hH][eE][lL][pP])
          # help menu
            which open 
            ;;
          *)
            "${"EDITOR:=nvim"}" "$1"
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
        if [ $1 == 1 ]; then
          git commit --amend
        else
          git rebase -i HEAD~$1
        fi
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
      ''
      +
      ''
        function gsaml2aws {
          docker run -it -v ~/.aws/credentials:/root/.aws/credentials gsaml2aws
        };
      '';

    };
  };

  system.stateVersion = "22.05"; # Did you read the comment?
}

