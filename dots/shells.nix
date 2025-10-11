{ pkgs, ... }:
let
  aliases = {
    "x" = "exit";
    "celar" = "clear";
    "tf" = "terraform";
    "kubeclt" = "kubectl";
    "edit" = "cd /home/jsh/git/jsh-nix/";
    "nixfmt" = "nixpkgs-fmt";
    "osbuild" = "nix build .#nixosConfigurations.$(hostname).config.system.build.toplevel";
    "osinstall" = "./result/bin/switch-to-configuration switch";
    "tvfb" = "filebot -r -rename * -non-strict --format /home/jsh/TV/\"{n.space('_')}-{y}/{s00e00}-{t.space('_')}\"";
    "moviefb" = "filebot -rename * -non-strict --format \"{n.space('_')}-{y}\"";
    "cwd" = "pwd | xclip -sel copy";
    "tdown" = "sudo tailscale down";
    "display-off" = "for display in $(xrandr  | awk '{print $1}' | grep -); do xrandr --output $display --off; done";
  };
  init =
    ''
      esc=/persist/extra-shell-config
      if [ -f $esc ]; then source $esc; fi
    ''
    +
    ''
      osup() {
        cd /home/jsh/git/jsh-nix
        sudo nixos-rebuild switch --flake .# --impure
        #sudo nix build .#nixosConfigurations.$(hostname).config.system.build.toplevel --impure
        #sudo ./result/bin/switch-to-configuration switch
      }
    ''
    +
    ''
      gi() {
        curl -L -s https://www.gitignore.io/api/$@ ;
      }
    ''
    +
    ''
      extract() {
         if [[ -z "$1" ]]; then
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
      open() {  
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
      xc() {
        xclip -sel copy
      }
    ''
    +
    ''
      xp() {
        xclip -o -sel clip
      }
    ''
    +
    ''
      gp() {
        CURRENT=$(git rev-parse --abbrev-ref HEAD)
        DEFAULT=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)
        if [[ $CURRENT = $DEFAULT ]] ; then
          git pull --rebase
        else
          git checkout $DEFAULT; git pull --rebase; git checkout $CURRENT; git rebase $DEFAULT; git rebase $DEFAULT; echo "Recommend running: git push origin $CURRENT -f"
          echo "git push origin $CURRENT -f" >> $HISTFILE
        fi
      }
    ''
    +
    ''
      gr() {
        DEFAULT=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)
        COMMIT_COUNT=$(git rev-list --count $DEFAULT..HEAD)
        if [[ $1 == 2 ]]; then
          git commit --amend --no-edit
        elif [[ $1 == "last" ]]; then
          git rebase -i HEAD~$COMMIT_COUNT
        else
          git rebase -i HEAD~$1
        fi
      }
    ''
    +
    ''
      geoloc() {
        curl ifconfig.io | nix run nixpkgs#toilet -- -f mono9 -t
        # curl -s "https://geo.ipify.org/api/v1?apiKey=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxipAddress=$1" | jq
      }
    ''
    +
    ''
      mm() {
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
      teamscam() {
        case $1 in
          /dev/video*)            export CAMERA=$1       ;;
          *)                      export CAMERA=/dev/video2;;
        esac
        ffmpeg -f v4l2 -input_format mjpeg -i $CAMERA -vf scale=1280x720 -pix_fmt yuyv422 -r 59.95 -f v4l2 /dev/video10
      };
    ''
    +
    ''
      pdfocr() {
        FN=$(basename -s .pdf $1)
        ocrmypdf $1 --image-dpi 1200 -d -c $FN-ocr.pdf
        mv $1 /tmp/
        echo "Original file '$1' was moved to /tmp"
        mv $FN-ocr.pdf $1
      };
    ''
    +
    ''
      replacespaces() {
        for file in *' '*
        do
          mv -- "$file" "''${file// /_}"

        done
      };
    ''
    +
    ''
      dotless() {
        awk -F'.' '{printf("%u\n", $1 * 256^3 + $2 * 256^2 + $3 * 256 + $4)}'
      };
    ''
    +
    ''
      export AWS_PAGER=""
    ''
    +
    ''
      scan() {
        while true; do
           if [ -n "$1" ]; then
             NAME=$1.png
           else
             NAME=$(date -u +%Y-%m-%dT%H%M%S).png
           fi
           scanimage --device-name=epsonds --format png --output-file="$NAME"
           if [ -s "$NAME" ]; then
             echo "Scan successful: $NAME"
             sxiv "$NAME" &
             pid=$!
             (sleep 4 && kill $pid) &
             wait $pid
             if [ -n "$1" ]; then
               return
             fi
           else
             echo "Deleted empty scan: $NAME"
             rm "$NAME"
           fi
        done
      }
    ''
    +
    ''
      b-scan() {
        while true; do
           if [ -n "$2" ]; then
             NAME=$2.png
             if [ -n "$3" ]; then
               NAME=$2-$(date -u +%Y-%m-%dT%H%M%S).png
             fi
           else
             NAME=$(date -u +%Y-%m-%dT%H%M%S).png
           fi
           if [ -s "$NAME" ]; then
             return 
           fi
           scanimage --device-name=$1 --format png --output-file="$NAME" $4
           if [ -s "$NAME" ]; then
             echo "Scan successful: $NAME"
             sxiv "$NAME" &
             pid=$!
             (sleep 4 && kill $pid) &
             wait $pid
           else
             echo "Deleted empty scan: $NAME"
             rm "$NAME"
           fi
        done
      };
    ''
    +
    ''
      e-scan() {
        while true; do
           if [ -n "$2" ]; then
             NAME=$2.png
             if [ -n "$3" ]; then
               NAME=$2-$(date -u +%Y-%m-%dT%H%M%S).png
             fi
           else
             NAME=$(date -u +%Y-%m-%dT%H%M%S).png
           fi
           if [ -s "$NAME" ]; then
             return 
           fi
           scanimage --device-name=epsonds --adf-skew=yes --adf-crp=yes --format png --output-file="$NAME"
           if [ -s "$NAME" ]; then
             echo "Scan successful: $NAME"
             sxiv "$NAME" &
             pid=$!
             (sleep 4 && kill $pid) &
             wait $pid
           else
             echo "Deleted empty scan: $NAME"
             rm "$NAME"
           fi
        done
      };
    ''
    +
    ''
      ssm-connect() {
        if [ -z "$1" ]; then
          echo "Usage: ssm-connect <instance-name>"
          return 1
        fi
      
        INSTANCE_NAME="$1"
        REGION="us-west-2"  # You can modify this or make it an optional argument
      
        INSTANCE_ID=$(aws ec2 describe-instances \
          --region "$REGION" \
          --filters "Name=tag:Name,Values=$INSTANCE_NAME" "Name=instance-state-name,Values=running" \
          --query "Reservations[*].Instances[*].InstanceId" \
          --output text)
      
        if [ -z "$INSTANCE_ID" ]; then
          echo "Instance with name '$INSTANCE_NAME' not found or not running in region '$REGION'."
          return 1
        fi
      
        echo "Starting SSM session with instance $INSTANCE_ID ($INSTANCE_NAME)..."
        aws ssm start-session --target "$INSTANCE_ID" --region "$REGION"
      }
    ''
    +
    ''
      list-instances() {
        REGION="''${1:-us-west-2}"  # Default to us-west-2 if no region passed
      
        aws ec2 describe-instances \
          --region "$REGION" \
          --filters "Name=instance-state-name,Values=running" \
          --query "Reservations[*].Instances[*].{ID:InstanceId,Name:Tags[?Key=='Name']|[0].Value}" \
          --output table
      }
    ''
    +
    ''
      watchfile() {
        local filepath="$1"
        local command="$2"
        local last_modified=$(date -r "$filepath" +%s)

        if [ ! -f "$filepath" ]; then
            echo "Error: File $filepath does not exist."
            return 1
        fi
        
        echo "Watching $filepath for changes..."
        
        while true; do
            current_modified=$(date -r "$filepath" +%s)
            if [ "$current_modified" -gt "$last_modified" ]; then
                last_modified="$current_modified"
                echo "File $filepath has been modified. Running command..."
                eval "$command"
            fi
            sleep 1 # Check every 1 second
        done
      };
    '';
in
{
  users.extraUsers.root.shell = pkgs.zsh;
  programs = {
    bash = {
      shellAliases = aliases;
      shellInit = init;
    };
    zsh = {
      enable = true;
      enableCompletion = true;
      histSize = 1000000;
      ohMyZsh = {
        enable = true;
        plugins = [
          "z"
          "branch"
          "aws"
          "kubectl"
          "kubectx"
        ];
      };
      shellAliases = aliases;
      shellInit = ''
        #ZSH_THEME_GIT_PROMPT_PREFIX="%{$reset_color%}%{$fg[white]%}["
        #ZSH_THEME_GIT_PROMPT_SUFFIX=""
        #ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[red]%}●%{$fg[white]%}]%{$reset_color%} "
        #ZSH_THEME_GIT_PROMPT_CLEAN="]%{$reset_color%} "
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
      init;
    };
  };
}
