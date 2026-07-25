#!/bin/bash
# Smart volume control: auto-detects PipeWire profile and uses the correct backend.
#
# Analog Stereo → SwayOSD (PipeWire software volume + native OSD popup)
# Pro Audio     → amixer  (ALSA hardware volume + notify-send fallback OSD)
#
# Uses ALSA card ID string ("Audio") not index number, so it survives
# USB re-enumeration across reboots and hot-plugs.

ALSA_CARD="Audio"   # /proc/asound/cards → [Audio]
STEP=2              # Volume step percentage

action="$1"  # raise | lower | mute

# ── Detect active profile from default sink node name ──
sink_name=$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep 'node.name' | head -1)

if echo "$sink_name" | grep -q 'pro-output'; then
    # ═══════════════════════════════════════════════
    #  PRO AUDIO MODE
    #  Software volume is locked at 0 dB (bit-perfect).
    #  Control the DAC's hardware PCM register directly.
    # ═══════════════════════════════════════════════
    case "$action" in
        raise)
            amixer -c "$ALSA_CARD" -q sset PCM "${STEP}%+"
            ;;
        lower)
            amixer -c "$ALSA_CARD" -q sset PCM "${STEP}%-"
            ;;
        mute)
            # This DAC has pswitch (hardware mute), so toggle works.
            # If it ever fails, fall back to wpctl mute on the PipeWire node.
            amixer -c "$ALSA_CARD" -q sset PCM toggle 2>/dev/null \
                || wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
            ;;
    esac

    # ── Build OSD notification from actual hardware state ──
    alsa_out=$(amixer -c "$ALSA_CARD" sget PCM 2>/dev/null)
    vol=$(echo "$alsa_out" | grep -oP '\[\d+%\]' | head -1 | tr -d '[]%')
    sw_state=$(echo "$alsa_out" | grep -oP '\[(on|off)\]' | head -1 | tr -d '[]')

    if [ "$sw_state" = "off" ]; then
        icon="audio-volume-muted"
        label="Muted"
    elif [ "${vol:-0}" -gt 66 ]; then
        icon="audio-volume-high"
        label="${vol}%"
    elif [ "${vol:-0}" -gt 33 ]; then
        icon="audio-volume-medium"
        label="${vol}%"
    else
        icon="audio-volume-low"
        label="${vol}%"
    fi

    notify-send -t 1500 \
        -i "$icon" \
        -h "int:value:${vol:-0}" \
        -h "string:x-canonical-private-synchronous:volume" \
        "🎚 HW Volume (Pro Audio)" "$label"

else
    # ═══════════════════════════════════════════════
    #  ANALOG STEREO MODE
    #  SwayOSD handles everything: PipeWire software
    #  volume adjustment + native on-screen display.
    # ═══════════════════════════════════════════════
    case "$action" in
        raise) swayosd-client --output-volume +"${STEP}" ;;
        lower) swayosd-client --output-volume -"${STEP}" ;;
        mute)  swayosd-client --output-volume mute-toggle ;;
    esac
fi

# Refresh Waybar custom volume module instantly
pkill -RTMIN+8 waybar 2>/dev/null || true
