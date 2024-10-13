#!/usr/bin/env bash
set -x

# Terminate already running bar instances
pkill polybar

# Launch Polybar for each monitor
if type "xrandr"; then
  for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    if [ $m == 'DP-2' ]; then
      MONITOR=$m polybar -rq --log=info -c /home/jsh/.config/polybar/config.ini left_vert > /home/jsh/.config/polybar/polybar_left_vert_$(date '+%Y-%m-%d_%H-%M-%S').log 2>&1 &
    else
      MONITOR=$m polybar -rq --log=info -c /home/jsh/.config/polybar/config.ini right > /home/jsh/.config/polybar/polybar_right_$(date '+%Y-%m-%d_%H-%M-%S').log 2>&1 &
    fi
  done
else
  polybar -rq --log=info -c /home/jsh/.config/polybar/config.ini right > /home/jsh/.config/polybar/polybar_right_$(date '+%Y-%m-%d_%H-%M-%S').log 2>&1 &
fi
