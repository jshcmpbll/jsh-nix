#!/bin/bash

# Terminate already running bar instances

  pkill polybar

# Launch Polybar for each monitor
  
if type "xrandr"; then
  for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    MONITOR=$m polybar -rq -c ~/.config/polybar/config.ini arctic &
  done
else
  polybar -rq -c ~/.config/polybar/config.ini arctic &
fi
