#!/usr/bin/env bash

# Ultra-Smooth Waybar CAVA Visualizer Script
config_file="$HOME/.config/cava/config_waybar"

# Ensure waybar cava config exists
if [ ! -f "$config_file" ]; then
    cat << 'EOF' > "$config_file"
[general]
framerate = 60
bars = 10
bar_width = 1
bar_spacing = 1

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

# Unicode block characters for equalizer height
dict=(" " "▂" "▃" "▄" "▅" "▆" "▇" "█")

# Process raw cava output and render unicode equalizer bars
cava -p "$config_file" | while read -r line; do
    output=""
    IFS=';' read -ra ADDR <<< "$line"
    for val in "${ADDR[@]}"; do
        if [[ "$val" =~ ^[0-7]$ ]]; then
            output+="${dict[$val]}"
        fi
    done
    if [[ -n "$output" ]]; then
        echo "♪ $output"
    fi
done
