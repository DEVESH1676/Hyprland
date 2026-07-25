#!/bin/bash
# Returns JSON for Waybar custom volume module
# Matches exact icon formatting of the original wireplumber config:
# Default icons: " :", " :", " :"
# Muted: ""
# Bluetooth: " "
# Headphone: " :"

ALSA_CARD="Audio"

sink_info=$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null)
sink_name=$(echo "$sink_info" | grep 'node.name' | head -1)
is_bt=$(echo "$sink_name" | grep -ic 'bluez')
is_hp=$(echo "$sink_info" | grep -ic 'headphone')

bt_prefix=""

if echo "$sink_name" | grep -q 'pro-output'; then
    # ── Pro Audio Mode (ALSA Hardware Volume) ──
    alsa_out=$(amixer -c "$ALSA_CARD" sget PCM 2>/dev/null)
    vol=$(echo "$alsa_out" | grep -oP '\[\d+%\]' | head -1 | tr -d '[]%')
    sw_state=$(echo "$alsa_out" | grep -oP '\[(on|off)\]' | head -1 | tr -d '[]')
    
    vol=${vol:-0}
    if [ "$sw_state" = "off" ]; then
        text="${bt_prefix}"
        tooltip="Pro Audio (HW): Muted"
        alt="muted"
    else
        if [ "$is_bt" -gt 0 ]; then
            icon=" :"
        elif [ "$is_hp" -gt 0 ]; then
            icon=" :"
        elif [ "$vol" -gt 66 ]; then
            icon=" :"
        elif [ "$vol" -gt 33 ]; then
            icon=" :"
        else
            icon=" :"
        fi
        
        text="${bt_prefix}${icon}${vol}%"
        tooltip="Pro Audio (HW Volume): ${vol}%"
        alt="normal"
    fi
else
    # ── Analog Stereo Mode (PipeWire Software Volume) ──
    wp_out=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
    vol=$(echo "$wp_out" | awk '{print int($2 * 100)}')
    is_muted=$(echo "$wp_out" | grep -c 'MUTED')
    
    vol=${vol:-0}
    if [ "$is_muted" -gt 0 ]; then
        text="${bt_prefix}"
        tooltip="Analog Stereo: Muted"
        alt="muted"
    else
        if [ "$is_bt" -gt 0 ]; then
            icon=" :"
        elif [ "$is_hp" -gt 0 ]; then
            icon=" :"
        elif [ "$vol" -gt 66 ]; then
            icon=" :"
        elif [ "$vol" -gt 33 ]; then
            icon=" :"
        else
            icon=" :"
        fi
        
        text="${bt_prefix}${icon}${vol}%"
        tooltip="Analog Stereo: ${vol}%"
        alt="normal"
    fi
fi

printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' "$text" "$tooltip" "$alt"
