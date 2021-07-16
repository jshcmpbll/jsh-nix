# Nix configuration and setup script

![desktop](https://imgur.com/03ESIC1.png)

## Custom Keyboard Shortcuts

|shortcut|function|
|---|---|
|mod+p|screenshot all screens and save to home directory|
|mod+shift+p|screenshot just focused window|
|mod+space|rofi search (used to launch applications and scripts as seen on the right of the screenshot)|

## Polybar

Polybar is the bar at the bottom of both my screens. On the left screen I have it only display the current workspace that is active. On the right one it is configured to show the following
- CPU Usage
- Memory Usage
- Disk Usage
- Workspace
- Date
- Time

## Picom
picom manages the compositing of different windows. Occasionally I have to run `pkill picom` when sharing my screen on Zoom becuase it interprits the screen share window as a standard window and places a drop shadow behind it.
