# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
let
  home-manager = builtins.fetchGit {
    url = "https://github.com/rycee/home-manager.git";
    rev = "8def3835111f0b16850736aa210ca542fcd02af6";
    ref = "release-19.03";
  };
in
{
  imports =
    [ 
      ./hardware-configuration.nix
      "${home-manager}/nixos"
    ];

  hardware.enableAllFirmware = true;

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        version = 2;
        devices = [ "nodev" ];
        useOSProber = true;
	efiSupport = true;
      };
    };
    supportedFilesystems = [ "zfs" ];
  };

  networking = {
    hostName = "jsh-server";
    hostId = "a6bbe9e1";
    useDHCP = false;
    interfaces.enp4s0.useDHCP = true;
  };

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  ## Uncomment for wireless macbook
  # networking.networkmanager.enable = false;
  # networking.wireless.enable = true;

  services.xserver.xkbOptions = "ctrl:swapcaps";

  services.udev.packages = [ pkgs.libu2f-host ];

  time.timeZone = "America/LosAngeles";
  
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    wget
    vim
    rxvt_unicode
    qutebrowser
    chromium
    i3-gaps
    slack
    spotify
    unzip
    scrot
    tldr
    xfce.xfce4-power-manager
    zsh
    neofetch
    htop
    gtk3
    lightdm
    lightdm_gtk_greeter
    git
    oh-my-zsh
    rofi
    dunst
    ffmpeg
    aspell
    gimp
    gnumake
    vlc
    which
    nmap
    ncat
    python38Packages.grip
    zathura
    zfs
    zoom-us
    tree
    feh
    file
    fdupes
    discord
    silver-searcher
    screen
    rsync
    restic
    polybar 
    ncurses
    ncdu
    jq
    hddtemp
    google-cloud-sdk
    _1password
    tmux
    pavucontrol
    xclip
    os-prober
    woeusb
    cudatoolkit
    x11vnc
    glxinfo
    youtube-dl
    unrar
    lsof
    yubikey-manager
  ];

  environment.variables.EDITOR = "urxvt";

  # List services that you want to enable:
  # Enable the OpenSSH daemon.
  services = {
    openssh.enable = true;
    ##x11vnc.enable= true;
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;


  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Enable the X11 windowing system and i3 gaps
  services.xserver = {
    enable = true;
    autorun = true;
    displayManager.lightdm.enable = true;
    displayManager.defaultSession = "none+i3";
    windowManager.i3 = {
      enable = true;
      package = pkgs.i3-gaps;
    };
    layout = "us";
    videoDrivers = [ "nvidia" ];
  };

  hardware.opengl.driSupport32Bit = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jsh = {
    isNormalUser = true;
    extraGroups = [ "wheel" "sudo"]; # Enable ‘sudo’ for the user.
    shell = pkgs.zsh;
  };

  home-manager.users.jsh = {
    programs.home-manager.enable = true;

    programs.zsh = {
      enable = true;
      enableCompletion = true;
    };

    xdg = {
      enable = true;

### brightness control

      configFile.brightness = {
        target = ".brightness";
        text = ''
#! /bin/sh

BRIGHTNESS=$(xrandr --verbose| grep Brightness | awk '{print $2}'| head -n 1)

if [ "$1" = "up" ]; then

  for screen in $(xrandr | grep " connected" | awk '{print $1}'); do
    xrandr --output $screen --brightness $(bc <<< "$BRIGHTNESS+ 0.1");
  done

else

  for screen in $(xrandr | grep " connected" | awk '{print $1}'); do
    xrandr --output $screen --brightness $(bc <<< "$BRIGHTNESS- 0.1");
  done
fi
'';
};
  
  
### i3 status

      configFile.i3status = {
        target = "i3status.conf";
        text = ''
# i3status configuration file.
# see "man i3status" for documentation.

# It is important that this file is edited as UTF-8.
# The following line should contain a sharp s:
# ß
# If the above line is not correctly displayed, fix your editor first!

general {
        colors = true
        interval = 5
        color_good = "#ffffff"
        color_bad = "#586E75"
        color_degraded = "#DC322F"
}

order += "cpu_usage"
order += "disk /"
order += "ethernet _first_"
order += "memory"
order += "tztime local"

cpu_usage {
        format = "   CPU %usage   "
}

disk "/" {
        format = "   %avail   "
        #format = "   ⛁ %avail   "
}

ethernet _first_ {
        format_up = "   %ip   "
        format_down = "   no lan   "
}

memory {
        format = "   %used/%available   "
        #threshold_degraded = "1G"
        format_degraded = "MEMORY < %available"
}

tztime local {
        format = "   %Y  %m  %d  %H:%M:%S   "
        #format = " %d.%m. %H:%M "
}
'';
};

### Xresources config

      configFile.xresources = {
        target = "../.Xresources";
        text = ''
urxvt.font: xft:San Francisco Display:pixelsize=18,style=reular
urxvt.boldFont: xft:San Francisco Display:pixelsize=18,style=bold
urxvt.letterSpace: -3 

urxvt*transparent: true
urxvt*shading: 15

!! black dark/light
*color0:                          #222D31
*color8:                          #585858

!! red dark/light
*color1:                          #ab4642
*color9:                          #ab4642

!! green dark/light
*color2:                          #7E807E
*color10:                         #8D8F8D

!! yellow dark/light - numbes in vim
*color3:                          #7cafc2
*color11:                         #7cafc2

!! blue dark/light
*color4:                          #7cafc2
*color12:                         #7cafc2

!! magenta dark/light
*color5:                          #ba8baf
*color13:                         #ba8baf

!! cyan dark/light
*color6:                          #1ABB9B
*color14:                         #1ABB9B

!! white dark/light
*color7:                          #d8d8d8
*color15:                         #FFFFFF 

Xcursor.theme: xcursor-breeze
Xcursor.size:                     30

URxvt.depth:                      32
URxvt.background:                 #131515
URxvt*scrollBar:                  false
URxvt*mouseWheelScrollPage:       false
URxvt*cursorBlink:                true
URxvt*background:                 black
URxvt*foreground:                 grey
URxvt*saveLines:                  5000

! Normal copy-paste keybindings without perls
URxvt.iso14755:                   false
URxvt.keysym.Shift-Control-V:     eval:paste_clipboard
URxvt.keysym.Shift-Control-C:     eval:selection_to_clipboard
URxvt.keysym.Conrol-V:            eval:paste_clipboard
URxvt.keysym.Control-C:           eval:selection_to_clipboard

!Xterm escape codes, word by word movement
URxvt.keysym.Control-Left:        \033[1;5D
URxvt.keysym.Shift-Control-Left:  \033[1;6D
URxvt.keysym.Control-Right:       \033[1;5C
URxvt.keysym.Shift-Control-Right: \033[1;6C
URxvt.keysym.Control-Up:          \033[1;5A
URxvt.keysym.Shift-Control-Up:    \033[1;6A
URxvt.keysym.Control-Down:        \033[1;5B
URxvt.keysym.Shift-Control-Down:  \033[1;6B
'';
};



### tmux config

      configFile.tmux = {
        target = "../.tmux.conf";
        text = ''
# change bind key to ctrl - a; this makes bind easier to hit and allows nesting tmux in an ssh session

unbind C-b
set -g prefix C-a

# split panes using | and -
bind \\ split-window -h
bind - split-window -v
unbind '"'
unbind %

# Enable mouse mode (tmux 2.1 and above)
set -g mouse on

# Allow for selection and copy of text from window
# Press y before releasing mouse
# don't rename windows automatically
set-option -g allow-rename off
bind-key -T copy-mode MouseDragEnd1Pane send -X copy-pipe-and-cancel "xclip -sel clip"

# Basic status bar colors
set -g status-fg colour240
set -g status-bg colour233

# Left side of status bar
### set -g status-left-bg colour233
### set -g status-left-fg colour243
set -g status-left-length 40
set -g status-left "#[fg=colour232,bg=colour39,bold] #S #[fg=colour39,bg=colour240,nobold]#[fg=colour233,bg=colour240] #(whoami) #[fg=colour240,bg=colour235]#[fg=colour240,bg=colour235] #I:#P #[fg=colour235,bg=colour233,nobold]"

# Right side of status bar
### set -g status-right-bg colour233
### set -g status-right-fg colour243
set -g status-right-length 150
# set -g status-right "#[fg=colour235,bg=colour233]#[fg=colour240,bg=colour235] %H:%M:%S #[fg=colour240,bg=colour235]#[fg=colour233,bg=colour240] %d-%b-%y #[fg=colour245,bg=colour240]#[fg=colour232,bg=colour245,bold] #H "
set -g status-right "#[fg=colour235,bg=colour233]#[fg=colour240,bg=colour235] %H:%M:%S #[fg=colour240,bg=colour235]#[fg=colour233,bg=colour240] %d-%b-%y " 

# Window status
set -g window-status-format " #I:#W#F "
set -g window-status-current-format " #I:#W#F "

# Current window status
### set -g window-status-current-bg colour39
### set -g window-status-current-fg colour232

# Window with activity status
### set -g window-status-activity-bg colour75 # fg and bg are flipped here due to
### set -g window-status-activity-fg colour233 # a bug in tmux

# Window separator
set -g window-status-separator ""

# Window status alignment
set -g status-justify centre

# Pane border
### set -g pane-border-bg default
### set -g pane-border-fg colour238

# Active pane border
### set -g pane-active-border-bg default
### set -g pane-active-border-fg colour39

# Pane number indicator
set -g display-panes-colour colour233
set -g display-panes-active-colour colour245


# Message
### set -g message-bg colour39
### set -g message-fg black

# Command message
### set -g message-command-bg colour233
### set -g message-command-fg black

# Mode
### set -g mode-bg colour39
### set -g mode-fg colour232
#set-option -g default-shell /bin/zsh

#Set working directory to same as last pane
#unbind v
#unbind n
#bind b send-keys -t "~/.tm
'';
};

### dunst config

      configFile.dunst = {
        target = "dunst/dunstrc";
        text = ''
[global]
    ### Display ###

    # Which monitor should the notifications be displayed on.
    monitor = 0

    # Display notification on focused monitor.  Possible modes are:
    #   mouse: follow mouse pointer
    #   keyboard: follow window with keyboard focus
    #   none: don't follow anything
    #
    # "keyboard" needs a window manager that exports the
    # _NET_ACTIVE_WINDOW property.
    # This should be the case for almost all modern window managers.
    #
    # If this option is set to mouse or keyboard, the monitor option
    # will be ignored.
    follow = mouse

    # The geometry of the window:
    #   [{width}]x{height}[+/-{x}+/-{y}]
    # The geometry of the message window.
    # The height is measured in number of notifications everything else
    # in pixels.  If the width is omitted but the height is given
    # ("-geometry x2"), the message window expands over the whole screen
    # (dmenu-like).  If width is 0, the window expands to the longest
    # message displayed.  A positive x is measured from the left, a
    # negative from the right side of the screen.  Y is measured from
    # the top and down respectively.
    # The width can be negative.  In this case the actual width is the
    # screen width minus the width defined in within the geometry option.
    #geometry = "300x5-30+20"
    geometry = "x10"

    # Show how many messages are currently hidden (because of geometry).
    indicate_hidden = yes

    # Shrink window if it's smaller than the width.  Will be ignored if
    # width is 0.
    shrink = no

    # The transparency of the window.  Range: [0; 100].
    # This option will only work if a compositing window manager is
    # present (e.g. xcompmgr, compiz, etc.).
    transparency = 0

    # The height of the entire notification.  If the height is smaller
    # than the font height and padding combined, it will be raised
    # to the font height and padding.
    notification_height = 0

    # Draw a line of "separator_height" pixel height between two
    # notifications.
    # Set to 0 to disable.
    separator_height = 2

    # Padding between text and separator.
    padding = 8

    # Horizontal padding.
    horizontal_padding = 8

    # Defines width in pixels of frame around the notification window.
    # Set to 0 to disable.
    frame_width = 0

    # Defines color of the frame around the notification window.
    frame_color = "#aaaaaa"

    # Define a color for the separator.
    # possible values are:
    #  * auto: dunst tries to find a color fitting to the background;
    #  * foreground: use the same color as the foreground;
    #  * frame: use the same color as the frame;
    #  * anything else will be interpreted as a X color.
    separator_color = frame

    # Sort messages by urgency.
    sort = yes

    # Don't remove messages, if the user is idle (no mouse or keyboard input)
    # for longer than idle_threshold seconds.
    # Set to 0 to disable.
    # A client can set the 'transient' hint to bypass this. See the rules
    # section for how to disable this if necessary
    idle_threshold = 120

    ### Text ###

    font = San Francisco Display 20

    # The spacing between lines.  If the height is smaller than the
    # font height, it will get raised to the font height.
    line_height = 0

    # Possible values are:
    # full: Allow a small subset of html markup in notifications:
    #        <b>bold</b>
    #        <i>italic</i>
    #        <s>strikethrough</s>
    #        <u>underline</u>
    #
    #        For a complete reference see
    #        <https://developer.gnome.org/pango/stable/pango-Markup.html>.
    #
    # strip: This setting is provided for compatibility with some broken
    #        clients that send markup even though it's not enabled on the
    #        server. Dunst will try to strip the markup but the parsing is
    #        simplistic so using this option outside of matching rules for
    #        specific applications *IS GREATLY DISCOURAGED*.
    #
    # no:    Disable markup parsing, incoming notifications will be treated as
    #        plain text. Dunst will not advertise that it has the body-markup
    #        capability if this is set as a global setting.
    #
    # It's important to note that markup inside the format option will be parsed
    # regardless of what this is set to.
    markup = full

    # The format of the message.  Possible variables are:
    #   %a  appname
    #   %s  summary
    #   %b  body
    #   %i  iconname (including its path)
    #   %I  iconname (without its path)
    #   %p  progress value if set ([  0%] to [100%]) or nothing
    #   %n  progress value if set without any extra characters
    #   %%  Literal %
    # Markup is allowed
    format = "<b>%s</b>    %b"

    # Alignment of message text.
    # Possible values are "left", "center" and "right".
    alignment = center 

    # Vertical alignment of message text and icon.
    # Possible values are "top", "center" and "bottom".
    vertical_alignment = center

    # Show age of message if message is older than show_age_threshold
    # seconds.
    # Set to -1 to disable.
    show_age_threshold = 60

    # Split notifications into multiple lines if they don't fit into
    # geometry.
    word_wrap = yes

    # When word_wrap is set to no, specify where to make an ellipsis in long lines.
    # Possible values are "start", "middle" and "end".
    ellipsize = middle

    # Ignore newlines '\n' in notifications.
    ignore_newline = no

    # Stack together notifications with the same content
    stack_duplicates = true

    # Hide the count of stacked notifications with the same content
    hide_duplicate_count = false

    # Display indicators for URLs (U) and actions (A).
    show_indicators = yes

    ### Icons ###

    # Align icons left/right/off
    icon_position = off

    # Scale small icons up to this size, set to 0 to disable. Helpful
    # for e.g. small files or high-dpi screens. In case of conflict,
    # max_icon_size takes precedence over this.
    min_icon_size = 0

    # Scale larger icons down to this size, set to 0 to disable
    max_icon_size = 32

    # Paths to default icons.
    icon_path = /usr/share/icons/gnome/16x16/status/:/usr/share/icons/gnome/16x16/devices/

    ### History ###

    # Should a notification popped up from history be sticky or timeout
    # as if it would normally do.
    sticky_history = yes

    # Maximum amount of notifications kept in history
    history_length = 20

    ### Misc/Advanced ###

    # dmenu path.
    dmenu = /usr/bin/dmenu -p dunst:

    # Browser for opening urls in context menu.
    browser = /usr/bin/qutebrowser

    # Always run rule-defined scripts, even if the notification is suppressed
    always_run_script = true

    # Define the title of the windows spawned by dunst
    title = Dunst

    # Define the class of the windows spawned by dunst
    class = Dunst

    # Print a notification on startup.
    # This is mainly for error detection, since dbus (re-)starts dunst
    # automatically after a crash.
    startup_notification = false

    # Manage dunst's desire for talking
    # Can be one of the following values:
    #  crit: Critical features. Dunst aborts
    #  warn: Only non-fatal warnings
    #  mesg: Important Messages
    #  info: all unimportant stuff
    # debug: all less than unimportant stuff
    verbosity = mesg

    # Define the corner radius of the notification window
    # in pixel size. If the radius is 0, you have no rounded
    # corners.
    # The radius will be automatically lowered if it exceeds half of the
    # notification height to avoid clipping text and/or icons.
    corner_radius = 0

    ### Legacy

    # Use the Xinerama extension instead of RandR for multi-monitor support.
    # This setting is provided for compatibility with older nVidia drivers that
    # do not support RandR and using it on systems that support RandR is highly
    # discouraged.
    #
    # By enabling this setting dunst will not be able to detect when a monitor
    # is connected or disconnected which might break follow mode if the screen
    # layout changes.
    force_xinerama = false

    ### mouse

    # Defines list of actions for each mouse event
    # Possible values are:
    # * none: Don't do anything.
    # * do_action: If the notification has exactly one action, or one is marked as default,
    #              invoke it. If there are multiple and no default, open the context menu.
    # * close_current: Close current notification.
    # * close_all: Close all notifications.
    # These values can be strung together for each mouse event, and
    # will be executed in sequence.
    mouse_left_click = close_current
    mouse_middle_click = do_action, close_current
    mouse_right_click = close_all

# Experimental features that may or may not work correctly. Do not expect them
# to have a consistent behaviour across releases.
[experimental]
    # Calculate the dpi to use on a per-monitor basis.
    # If this setting is enabled the Xft.dpi value will be ignored and instead
    # dunst will attempt to calculate an appropriate dpi value for each monitor
    # using the resolution and physical size. This might be useful in setups
    # where there are multiple screens with very different dpi values.
    per_monitor_dpi = false

[shortcuts]

    # Shortcuts are specified as [modifier+][modifier+]...key
    # Available modifiers are "ctrl", "mod1" (the alt-key), "mod2",
    # "mod3" and "mod4" (windows-key).
    # Xev might be helpful to find names for keys.

    # Close notification.
    close = ctrl+space

    # Close all notifications.
    close_all = ctrl+shift+space

    # Redisplay last message(s).
    # On the US keyboard layout "grave" is normally above TAB and left
    # of "1". Make sure this key actually exists on your keyboard layout,
    # e.g. check output of 'xmodmap -pke'
    history = ctrl+grave

    # Context menu.
    context = ctrl+shift+period

[urgency_low]
    # IMPORTANT: colors have to be defined in quotation marks.
    # Otherwise the "#" and following would be interpreted as a comment.
    background = "#222222"
    foreground = "#FFFFFF"
    timeout = 10
    # Icon for notifications with low urgency, uncomment to enable
    #icon = /path/to/icon

[urgency_normal]
    background = "#7cafc2"
    foreground = "#FFFFFF"
    timeout = 10
    # Icon for notifications with normal urgency, uncomment to enable
    #icon = /path/to/icon

[urgency_critical]
    background = "#900000"
    foreground = "#FFFFFF"
    timeout = 0
    # Icon for notifications with critical urgency, uncomment to enable
    #icon = /path/to/icon
        '';
      };


### rofi config

      configFile.rofi = {
        target = "rofi/config";
        text = ''
! ------------------------------------------------------------------------------
! ROFI Color theme
! ------------------------------------------------------------------------------
rofi.color-enabled: true
# 		   Window	  Border	 Separator
rofi.color-window: argb:D0000000, #ffffff, argb:50ffffff

#		    Background	  Foreground	 Alt Background Highlight Bg   Highlight Fg
rofi.color-normal: argb:00000000, argb:FFFFFFFF, argb:00000000, argb:00000000, argb:FF7cafc2
#rofi.color-normal: argb:00000000, argb:FFFFFFFF, argb:00000000, argb:A0FFFFFF, argb:D0000000
#rofi.color-active: argb:00000000, argb:FFFFFFFF, argb:00000000, argb:A02C3E4F, argb:D0FFFFFF
#rofi.color-urgent: argb:00000000, argb:FFFFFFFF, argb:00000000, argb:A02C3E4F, argb:D0FFFFFF

rofi.bw: 0
rofi.fake-transparency: true
rofi.fullscreen: true
rofi.padding: 350
rofi.line-padding: 10
rofi.separator-style: none
#rofi.lines: 0 

rofi.hide-scrollbar: false 
rofi.font: fira-code 15
        '';
      };

### i3 config

      configFile.i3 = {
        target = "i3/config";
        text = ''
exec xrandr --output HDMI-0 --mode 2560x1440 --right-of DP-2 --primary
exec xrandr --output DP-2 --mode 2560x1440 --left-of HDMI-0

exec feh --bg-fill https://i.imgur.com/QoufAE6.jpg  
exec setxkbmap -option ctrl:swapcaps

exec pactl set-card-profile alsa_card.pci-0000_0b_00.1 output:hdmi-stereo-extra1
exec pactl set-default-sink alsa_output.pci-0000_0b_00.1.hdmi-stereo-extra1


#bindsym F5 exec pactl set-card-profile alsa_card.pci-0000_0b_00.1 output:hdmi-stereo-extra1 && set-default-sink alsa_output.pci-0000_0b_00.1.hdmi-stereo-extra1 
bindsym F5 exec set-default-sink alsa_output.pci-0000_0b_00.1.hdmi-stereo-extra1 
bindsym F6 exec pactl set-default-sink bluez_sink.38_18_4C_6C_7D_00.a2dp_sink
bindsym F12 exec pactl set-sink-volume alsa_output.pci-0000_0b_00.1.hdmi-stereo-extra1 -10%
bindsym XF86MonBrightnessDown exec sh ~/.config/.brightness down
bindsym XF86MonBrightnessUp exec sh ~/.config/.brightness up


#bluetoothctl -- connect 38:18:4C:6C:7D:00 && pactl set-default-sink bluez_sink.38_18_4C_6C_7D_00.a2dp_sink

gaps inner 20
gaps outer 40

default_border none

# i3 config file (v4)
#
# Please see https://i3wm.org/docs/userguide.html for a complete reference!
#
# This config file uses keycodes (bindsym) and was written for the QWERTY
# layout.
#
# To get a config file with the same key positions, but for your current
# layout, use the i3-config-wizard
#

# Font for window titles. Will also be used by the bar unless a different font
# is used in the bar {} block below.
#font pango:monospace 20
font pango:San Francisco Display 15


# This font is widely installed, provides lots of unicode glyphs, right-to-left
# text rendering and scalability on retina/hidpi displays (thanks to pango).
#font pango:DejaVu Sans Mono 8

# The combination of xss-lock, nm-applet and pactl is a popular choice, so
# they are included here as an example. Modify as you see fit.

# xss-lock grabs a logind suspend inhibit lock and will use i3lock to lock the
# screen before suspend. Use loginctl lock-session to lock your screen.
exec --no-startup-id xss-lock --transfer-sleep-lock -- i3lock --nofork

# NetworkManager is the most popular way to manage wireless networks on Linux,
# and nm-applet is a desktop environment-independent system tray GUI for it.
exec --no-startup-id nm-applet

# Use pactl to adjust volume in PulseAudio.
set $refresh_i3status killall -SIGUSR1 i3status
bindsym XF86AudioRaiseVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +10% && $refresh_i3status
bindsym XF86AudioLowerVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -10% && $refresh_i3status
bindsym XF86AudioMute exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle && $refresh_i3status
bindsym XF86AudioMicMute exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle && $refresh_i3status

# use these keys for focus, movement, and resize directions when reaching for
# the arrows is not convenient
set $up l
set $down k
set $left j
set $right semicolon
set $mod Mod4

# use Mouse+$mod to drag floating windows to their wanted position
floating_modifier $mod

# start a terminal
bindsym $mod+Return exec urxvt -e tmux

# screenshot

bindsym $mod+Shift+p exec scrot --focused
bindsym $mod+p exec scrot

# kill focused window
bindsym $mod+q kill 

# start dmenu (a program launcher)
bindsym $mod+space exec rofi -show run -display-run "" #-padding  $(echo $(xdpyinfo | grep dimensions: | awk '{print $2}' | awk -F 'x' '{print $1}') \* .2083 | bc)
#bindsym $mod+space exec rofi -show run -display-run "" -padding 800
# There also is the (new) i3-dmenu-desktop which only displays applications
# shipping a .desktop file. It is a wrapper around dmenu, so you need that
# installed.
# bindsym $mod+d exec --no-startup-id i3-dmenu-desktop

# change focus
bindsym $mod+$left focus left
bindsym $mod+$down focus down
bindsym $mod+$up focus up
bindsym $mod+$right focus right

# alternatively, you can use the cursor keys:
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

# move focused window
bindsym $mod+Shift+$left move left
bindsym $mod+Shift+$down move down
bindsym $mod+Shift+$up move up
bindsym $mod+Shift+$right move right

# alternatively, you can use the cursor keys:
bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right

# split in horizontal orientation
bindsym $mod+h split h

# split in vertical orientation
bindsym $mod+v split v

# enter fullscreen mode for the focused container
bindsym $mod+f fullscreen toggle

# change container layout (stacked, tabbed, toggle split)
#bindsym $mod+s layout stacking
#bindsym $mod+w layout tabbed
#bindsym $mod+e layout toggle split

# toggle tiling / floating
bindsym $mod+Shift+space floating toggle

# focus the parent container
bindsym $mod+a focus parent

# focus the child container
#bindsym $mod+d focus child

# move the currently focused window to the scratchpad
bindsym $mod+Shift+minus move scratchpad

# Show the next scratchpad window or hide the focused scratchpad window.
# If there are multiple scratchpad windows, this command cycles through them.
bindsym $mod+minus scratchpad show

# Define names for default workspaces for which we configure key bindings later on.
# We use variables to avoid repeating the names in multiple places.
set $ws1 "1"
set $ws2 "2"
set $ws3 "3"
set $ws4 "4"
set $ws5 "5"
set $ws6 "6"
set $ws7 "7"
set $ws8 "8"
set $ws9 "9"
set $ws10 "10"

# switch to workspace
bindsym $mod+1 workspace number $ws1
bindsym $mod+2 workspace number $ws2
bindsym $mod+3 workspace number $ws3
bindsym $mod+4 workspace number $ws4
bindsym $mod+5 workspace number $ws5
bindsym $mod+6 workspace number $ws6
bindsym $mod+7 workspace number $ws7
bindsym $mod+8 workspace number $ws8
bindsym $mod+9 workspace number $ws9
bindsym $mod+0 workspace number $ws10

# move focused container to workspace
bindsym $mod+Shift+1 move container to workspace number $ws1
bindsym $mod+Shift+2 move container to workspace number $ws2
bindsym $mod+Shift+3 move container to workspace number $ws3
bindsym $mod+Shift+4 move container to workspace number $ws4
bindsym $mod+Shift+5 move container to workspace number $ws5
bindsym $mod+Shift+6 move container to workspace number $ws6
bindsym $mod+Shift+7 move container to workspace number $ws7
bindsym $mod+Shift+8 move container to workspace number $ws8
bindsym $mod+Shift+9 move container to workspace number $ws9
bindsym $mod+Shift+0 move container to workspace number $ws10

# reload the configuration file
bindsym $mod+Shift+c reload
# restart i3 inplace (preserves your layout/session, can be used to upgrade i3)
bindsym $mod+Shift+r restart
# exit i3 (logs you out of your X session)
bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -B 'Yes, exit i3' 'i3-msg exit'"

# resize window (you can also use the mouse for that)
mode "resize" {
        # These bindings trigger as soon as you enter the resize mode

        # Pressing left will shrink the window’s width.
        # Pressing right will grow the window’s width.
        # Pressing up will shrink the window’s height.
        # Pressing down will grow the window’s height.
        bindsym $left       resize shrink width 10 px or 10 ppt
        bindsym $down       resize grow height 10 px or 10 ppt
        bindsym $up         resize shrink height 10 px or 10 ppt
        bindsym $right      resize grow width 10 px or 10 ppt

        # same bindings, but for the arrow keys
        bindsym Left        resize shrink width 10 px or 10 ppt
        bindsym Down        resize grow height 10 px or 10 ppt
        bindsym Up          resize shrink height 10 px or 10 ppt
        bindsym Right       resize grow width 10 px or 10 ppt

        # back to normal: Enter or Escape or $mod+r
        bindsym Return mode "default"
        bindsym Escape mode "default"
        bindsym $mod+r mode "default"
}

bindsym $mod+r mode "resize"

# Start i3bar to display a workspace bar (plus the system information i3status
# finds out, if available)

bar {

  font pango: fira-code 20

  colors {
      background #000000
      statusline #ffffff
      separator #ffffff
      focused_workspace #7cafc2 #7cafc2 #000000
      active_workspace #333333 #5f676a

  }
        status_command i3status -c ~/.config/i3status.conf
        position top
        mode hide 

}

        '';
      };
    };
  };

fonts.fonts = with pkgs; [
  noto-fonts
  noto-fonts-cjk
  noto-fonts-emoji
  liberation_ttf
  fira-code
  fira-code-symbols
  mplus-outline-fonts
  dina-font
  proggyfonts
];


  security.sudo.configFile = ''
    jsh ALL=(ALL) NOPASSWD:ALL
  '';

  # Read docs before changing -> (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?

}
