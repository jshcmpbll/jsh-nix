#! /usr/bin/env bash
set -x

# Terminate already running bar instances

  pkill polybar

# Launch Polybar for each monitor
  
if type "xrandr"; then
  for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    if [ $m == 'DP-2' ]
    then
      MONITOR=$m polybar -rq -c /home/jsh/.config/polybar/config.ini left_vert &
      # MONITOR=$m polybar -rq -c /home/jsh/.config/polybar/config.ini right &
    else
      MONITOR=$m polybar -rq -c /home/jsh/.config/polybar/config.ini right &
    fi
  done
else
  polybar -rq -c /home/jsh/.config/polybar/config.ini right &
fi
