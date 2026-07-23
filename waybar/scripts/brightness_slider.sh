#!/bin/sh
current=$(brightnessctl | grep "Current" | awk '{print $4}' | tr -d '()%')
new=$(echo -e "$current\n10\n20\n30\n40\n50\n60\n70\n80\n90\n100" | rofi -dmenu -p "Brightness")
[ -n "$new" ] && brightnessctl set "$new%"
