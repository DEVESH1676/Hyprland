#!/usr/bin/env python3
import time
import subprocess
import json

TITLE_MAX = 20
ARTIST_MAX = 14
TICK = 0.15
PAUSE_START_TICKS = 10  # 1.5s crisp start pause
PAUSE_END_TICKS = 7     # 1.0s end pause

title_pos = 0
title_counter = PAUSE_START_TICKS
title_state = "PAUSE_START"
last_title = ""

artist_pos = 0
artist_counter = PAUSE_START_TICKS
artist_state = "PAUSE_START"
last_artist = ""

def get_sleek_marquee(text, max_len, pos, state, counter, last_text, is_playing):
    if len(text) <= max_len:
        return text, 0, "PAUSE_START", PAUSE_START_TICKS, text
    
    if text != last_text:
        pos = 0
        state = "PAUSE_START"
        counter = PAUSE_START_TICKS
        last_text = text

    padded = text + "   •   "
    max_pos = len(padded)
    display = (padded * 2)[pos:pos + max_len]

    if is_playing:
        if state == "PAUSE_START":
            counter -= 1
            if counter <= 0:
                state = "SCROLLING"
        elif state == "SCROLLING":
            pos += 1
            if pos >= max_pos:
                pos = 0
                state = "PAUSE_END"
                counter = PAUSE_END_TICKS
        elif state == "PAUSE_END":
            counter -= 1
            if counter <= 0:
                state = "PAUSE_START"
                counter = PAUSE_START_TICKS

    return display, pos, state, counter, last_text

while True:
    try:
        status = subprocess.check_output(["playerctl", "status"], stderr=subprocess.DEVNULL).decode().strip()
    except Exception:
        status = "NoPlayer"

    if status in ["NoPlayer", "Stopped"]:
        print(json.dumps({"text": "", "class": "stopped", "tooltip": "No media playing"}), flush=True)
        time.sleep(2)
        continue

    try:
        title = subprocess.check_output(["playerctl", "metadata", "title"], stderr=subprocess.DEVNULL).decode().strip()
    except Exception:
        title = ""

    try:
        artist = subprocess.check_output(["playerctl", "metadata", "artist"], stderr=subprocess.DEVNULL).decode().strip()
    except Exception:
        artist = ""

    if not title:
        print(json.dumps({"text": "", "class": "stopped"}), flush=True)
        time.sleep(2)
        continue

    is_playing = (status == "Playing")
    icon = "▶" if is_playing else "⏸"

    display_title, title_pos, title_state, title_counter, last_title = get_sleek_marquee(
        title, TITLE_MAX, title_pos, title_state, title_counter, last_title, is_playing
    )

    if artist:
        display_artist, artist_pos, artist_state, artist_counter, last_artist = get_sleek_marquee(
            artist, ARTIST_MAX, artist_pos, artist_state, artist_counter, last_artist, is_playing
        )
        formatted = f"[ 󰠃 {icon}  {display_title} • {display_artist} ]"
    else:
        formatted = f"[ 󰠃 {icon}  {display_title} ]"

    print(json.dumps({"text": formatted, "tooltip": f"Title: {title}\nArtist: {artist}", "class": status.lower()}), flush=True)
    time.sleep(TICK if is_playing else 1.0)
