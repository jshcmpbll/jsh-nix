#! /usr/bin/env bash
set -x

# Terminate already running bar instances

  pkill polybar

# Launch Polybar for each monitor
  
if type "xrandr"; then
  for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    if [ $m == 'HDMI-0' ]
    then
      MONITOR=$m polybar -rq -c ~/.config/polybar/config.ini right &
    elif [ $m == 'DP-2' ]
    then 
      MONITOR=$m polybar -rq -c ~/.config/polybar/config.ini left &
    else
      MONITOR=$m polybar -rq -c ~/.config/polybar/config.ini right &
    fi
  done
else
  polybar -rq -c ~/.config/polybar/config.ini right &
fi
