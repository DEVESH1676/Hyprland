#!/usr/bin/env python3
import time
import subprocess
import json

TITLE_MAX_LEN = 20
SPEED = 0.35

pos = 0
last_title = ""

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

    icon = "▶" if status == "Playing" else "⏸"

    # Marquee scroll ONLY the title if it exceeds TITLE_MAX_LEN
    if len(title) <= TITLE_MAX_LEN:
        display_title = title
    else:
        padded = title + "   •   "
        if title != last_title:
            pos = 0
            last_title = title
        display_title = (padded * 2)[pos:pos + TITLE_MAX_LEN]
        if status == "Playing":
            pos = (pos + 1) % len(padded)

    # Append artist statically if present
    if artist:
        formatted = f"[ 󰠃 {icon} | {display_title} - {artist} ]"
    else:
        formatted = f"[ 󰠃 {icon} | {display_title} ]"

    print(json.dumps({"text": formatted, "tooltip": f"Title: {title}\nArtist: {artist}", "class": status.lower()}), flush=True)
    time.sleep(SPEED if status == "Playing" else 1.0)
