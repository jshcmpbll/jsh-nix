{ lib, config, pkgs, latest, scan, stdenv,  ... }:
let
  myFirefox = pkgs.wrapFirefox
    (latest.pkgs.firefox-unwrapped.override (old: {
      requireSigning = false;
      allowAddonSideload = true;
    }))
    {
      cfg = { smarctcardSupport = true; };
      nixExtensions = [
        (pkgs.fetchFirefoxAddon {
          name = "1password";
          url = "https://addons.mozilla.org/firefox/downloads/file/4546733/1password_x_password_manager-8.11.4.27.xpi";
          sha256 = "sha256-Pt0F9pysyl7fLkoG+cMtsHBdTPLBM8ISE2z12w++ZIk=";
        })
        (pkgs.fetchFirefoxAddon {
          name = "ublock";
          url = "https://addons.mozilla.org/firefox/downloads/file/4531307/ublock_origin-1.65.0.xpi";
          sha256 = "sha256-PnPJaimpM4ZgZfB1b+AymEv1slSvjdGv16f34GaKM88=";
        })
        (pkgs.fetchFirefoxAddon {
          name = "custom_user_agent_revived";
          url = "https://addons.mozilla.org/firefox/downloads/file/3648268/custom_user_agent_revived-0.2.1.xpi";
          sha256 = "sha256-yOrXRXT8qjz4AI1Rw6r+ISogMRk0/OpMo0rEVJwT+J4=";
        })
      ];
      extraPolicies = {
        DisablePocket = true;
        DisableTelemetry = true;
        DisableAccounts = true;
        DisableFirefoxAccounts = true;
        DisableFirefoxScreenshots = true;
        DisplayBookmarksToolbar = "newtab";
        FirefoxHome = {
          Pocket = false;
          Snippets = false;
        };
        Preferences = {
          "geo.enabled" = { Value = "false"; };
          "browser.fullscreen.autohide" = { Value = "false"; };
          "extensions.activeThemeID" = { Value = "firefox-compact-dark@mozilla.org"; Status = "locked"; };
          "quicksuggest.enabled" = { Value = "false"; Status = "locked"; };
          "full-screen-api.warning.timeout" = { Value = "1000"; Status = "locked"; };
          "signon.autofill.plugins.disabled" = { Value = "true"; Status = "locked"; };
          "browser.search.selectedEngine" = { Value = "DuckDuckGo"; Status = "locked"; };
          "browser.search.suggest" = { Value = "false"; Status = "locked"; };

          "proxy-profile/network.proxy.type" = { Value = 1; Status = "locked"; };
          "proxy-profile/network.proxy.socks" = { Value = "127.0.0.1"; Status = "locked"; };
          "proxy-profile/network.proxy.socks_port" = { Value = 1080; Status = "locked"; };
          "proxy-profile/network.proxy.socks_version" = { Value = 5; Status = "locked"; };
          "proxy-profile/network.proxy.socks_remote_dns" = { Value = true; Status = "locked"; };

        };
      };
    };
    myZoom-us = if config.networking.hostName == "jsh-lenovo"
      then pkgs.runCommand "zoom" { buildInputs = [ pkgs.makeWrapper ]; } ''
        mkdir -p $out/bin $out/share
        makeWrapper ${pkgs.zoom-us}/bin/zoom $out/bin/zoom $@ \
        --set QT_SCALE_FACTOR 0.50
        
        # Copy desktop file and other necessary directories
        cp -r ${pkgs.zoom-us}/share/* $out/share/
        
        # Update desktop file to use our wrapper
        substituteInPlace $out/share/applications/Zoom.desktop \
          --replace "Exec=zoom" "Exec=$out/bin/zoom"
      ''
      else pkgs.zoom-us;
in
{
  imports = [
    ./loopback-cam.nix
  ];

  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = true;
  };

  environment.systemPackages = with pkgs; [
    #builtins.readFile /home/jsh/git/jsh-nix/packages ];
    aspell
    aspellDicts.en
    audacity
    awscli2
    bc
    bind
    blueman
    kdePackages.breeze-gtk
    kdePackages.breeze
    cava
    darktable
    digikam
    dmg2img
    dmidecode
    docker-compose
    kdePackages.dolphin
    dunst
    eagle
    exiftool
    fdupes
    feh
    ffmpeg-full
    file
    myFirefox
    foremost
    freecad
    gimp
    git
    git-lfs
    glxinfo
    adwaita-icon-theme
    gnumake
    gnupg
    gnuplot
    go
    google-chrome
    google-cloud-sdk
    grub2
    gtk3
    hddtemp
    htop
    i3-gaps
    imagemagick
    iperf3
    jq
    killall
    kompose
    kubectl
    kubernetes
    kubernetes-helm
    libheif
    libimobiledevice
    libreoffice
    libvirt
    lightdm
    lightdm_gtk_greeter
    linuxPackages.v4l2loopback
    lm_sensors
    lsof
    lutris
    lyx
    mediainfo
    mkdocs
    mpv
    mupdf
    nmap
    ncdu
    ncurses
    fastfetch
    nixpkgs-fmt
    nix-prefetch-git
    nload
    nmap
    nodePackages.prettier
    ntfs3g
    ofono-phonesim
    oh-my-zsh
    kdePackages.okular
    os-prober
    pandoc
    pavucontrol
    pciutils
    pdfsandwich
    php
    picom
    polybarFull
    prometheus
    pywal
    qemu
    qemu_kvm
    qemu-utils
    redshift
    restic
    rofi
    rpl
    rsync
    samba
    sane-airscan
    screen
    screenkey
    scrot
    silver-searcher
    scan.simple-scan
    slack
    smartmontools
    spotify
    sshfs
    sshfs-fuse
    latest.steam
    sxiv
    synergy
    inetutils # telnet
    tesseract
    texlive.combined.scheme-full
    tigervnc
    tldr
    tlp
    tmux
    tree
    unrar
    vlc
    argocd
    azure-cli
    discord
    fluxcd
    github-cli
    guvcview
    joplin
    joplin-desktop
    minecraft
    terraform
    myZoom-us
    ranger
    unzip
    usbmuxd
    usbutils
    #vulkan-loader
    #vulkan-tools
    vulnix
    wget
    which
    wine
    wireshark-cli
    wireshark-qt
    woeusb
    xclip
    xfce.thunar
    xorg.xdpyinfo
    yaml2json
    yarn
    yj
    yq
    yt-dlp
    yubico-piv-tool
    yubikey-manager
    zathura
    zfs
    zsh
    binutils
    helmsman
    terraform-docs
    libimobiledevice
    magic-wormhole
    wormhole-william
    nufraw
    nixpkgs-review
    deluge
    at
    btop
    lm_sensors
    ansible
    openconnect
    stoken
    dolphin-emu
    hdparm
    conftest
    json2hcl
    open-policy-agent
    ocrmypdf
    thunderbird
    hugo
    gthumb
    ifuse
    wireguard-tools
    element-desktop
    obsidian
    imv
    signal-desktop
    _1password-cli
    arandr
    font-manager
    v4l-utils
    libguestfs
    ethtool
    coldsnap
    ticker
    ssm-session-manager-plugin
    python313Packages.grip
    latest.nix
    ssh-agents
    #filebot
    nautilus
    sushi
    mtr
    ssh-agents
    wpa_supplicant
    nvtopPackages.full
    aria2
    pdftk
    kdePackages.kcalc
    latest.beeper
    freetube
    nodejs
    sipcalc
    davinci-resolve-studio
    v4l-utils
    nodejs
    wpa_supplicant_gui
    slurm-nm
    bat
    cifs-utils
    samba4Full
    asciinema
    bruno 
    (latest.vscode-with-extensions.override {
      vscodeExtensions = with vscode-extensions; [
        dbaeumer.vscode-eslint
        esbenp.prettier-vscode
        github.copilot
        latest.vscode-extensions.github.copilot-chat
        continue.continue
      ];
    })
    postman
    remmina
    sipcalc
    davinci-resolve-studio
    ghostty
    latest.claude-code
    simplescreenrecorder
    #LPA
  ];
}
