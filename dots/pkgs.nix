{ lib, config, pkgs, latest, scan, stdenv, ... }:
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
          url = "https://addons.mozilla.org/firefox/downloads/file/4037440/1password_x_password_manager-2.5.0.xpi";
          sha256 = "sha256:702a5cd8b63a326e1c4a839bdf075534d69074450db25fe9cddcd60186df02d6";
        })
        (pkgs.fetchFirefoxAddon {
          name = "ublock";
          url = "https://addons.mozilla.org/firefox/downloads/file/4028976/ublock_origin-1.45.2.xpi";
          sha256 = "sha256-+xc4lcdsOwXxMsr4enFsdePbIb6GHq0bFLpqvH5xXos=";
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
          "extensions.activeThemeID" = { Value = "firefox-compact-dark@mozilla.org"; Status = "locked"; };
        };
      };
    };
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
    breeze-gtk
    breeze-qt5
    cava
    darktable
    digikam
    dmg2img
    dmidecode
    docker-compose
    latest.dolphin
    dunst
    eagle
    exiftool
    fdupes
    feh
    latest.ffmpeg-full
    file
    myFirefox
    foremost
    freecad
    gimp
    git
    git-lfs
    glxinfo
    gnome3.adwaita-icon-theme
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
    latest.lutris
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
    okular
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
    rxvt_unicode
    samba
    sane-airscan
    screen
    screenkey
    scrot
    silver-searcher
    scan.simple-scan
    latest.slack
    smartmontools
    spotify
    sshfs
    sshfs-fuse
    steam
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
    latest.argocd
    latest.azure-cli
    latest.azure-functions-core-tools
    latest.discord
    latest.fluxcd
    latest.github-cli
    latest.guvcview
    joplin
    latest.joplin-desktop
    minecraft
    #latest.odafileconverter
    latest.spotifyd
    latest.terraform
    zoom-us
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
    latest.nufraw
    nixpkgs-review
    deluge
    at
    latest.btop
    lm_sensors
    ansible
    openconnect
    stoken
    latest.dolphin-emu
    hdparm
    latest.conftest
    json2hcl
    latest.open-policy-agent
    ocrmypdf
    thunderbird
    hugo
    gthumb
    ifuse
    wireguard-tools
    element-desktop
    latest.obsidian
    imv
    signal-desktop
    _1password
    arandr
    font-manager
    v4l-utils
    libguestfs
    ethtool
    coldsnap
    ticker
    ssm-session-manager-plugin
    python310Packages.grip
    latest.nix
    ssh-agents
    #filebot
    gnome.nautilus
    gnome.sushi
    mtr
    ssh-agents
    wpa_supplicant
    nvtopPackages.full
    aria2
    pdftk
    kcalc
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
    (vscode-with-extensions.override {
      vscodeExtensions = with vscode-extensions; [
        dbaeumer.vscode-eslint
        esbenp.prettier-vscode
        genieai.chatgpt-vscode
      ];
    })
    latest.postman
    remmina
    sipcalc
    davinci-resolve-studio
    alacritty
    #LPA
  ];
}
