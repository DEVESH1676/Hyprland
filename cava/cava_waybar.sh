#!/usr/bin/env bash

# Ultra-Smooth Waybar CAVA Visualizer Script (Monstercat Wave Engine)
config_file="$HOME/.config/cava/config_waybar"

# Ensure waybar cava config exists with fluid Monstercat smoothing
if [ ! -f "$config_file" ]; then
    cat << 'EOF' > "$config_file"
[general]
framerate = 60
bars = 10
bar_width = 1
bar_spacing = 1
sensitivity = 100
autosens = 1
lower_cutoff_freq = 50
higher_cutoff_freq = 12000

[smoothing]
monstercat = 1
waves = 1
gravity = 90
integral = 70
noise_reduction = 0.77

[eq]
1 = 1.4
2 = 1.2
3 = 1.0
4 = 1.0
5 = 1.2

[input]
method = pipewire
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
EOF
fi

# Unicode block characters for equalizer height (baseline level 0 uses ▂ to avoid empty space gaps)
dict=("▂" "▂" "▃" "▄" "▅" "▆" "▇" "█")

# Exit cleanly on SIGPIPE (when Waybar closes stdout pipe)
trap 'exit 0' SIGPIPE

# Process raw cava output and render unicode equalizer bars
cava -p "$config_file" 2>/dev/null | while read -r line; do
    player_status=$(playerctl status 2>/dev/null || echo "NoPlayer")

    # If music player is paused, show only the music icon ♪
    if [ "$player_status" = "Paused" ]; then
        echo "♪" 2>/dev/null || exit 0
        continue
    # If no media player is open or stopped, hide widget
    elif [ "$player_status" = "NoPlayer" ] || [ "$player_status" = "Stopped" ]; then
        echo "" 2>/dev/null || exit 0
        continue
    fi

    output=""
    IFS=';' read -ra ADDR <<< "$line"
    for val in "${ADDR[@]}"; do
        if [[ "$val" =~ ^[0-7]$ ]]; then
            output+="${dict[$val]}"
        fi
    done

    # While playing, keep equalizer bars rendering smoothly (rests at baseline ▂ during quiet parts)
    echo "♪ $output" 2>/dev/null || exit 0
done
