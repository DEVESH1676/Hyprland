#!/usr/bin/env python3
import subprocess
import json
import time

def get_clean_app_name():
    try:
        out = subprocess.check_output(["hyprctl", "activewindow", "-j"], stderr=subprocess.DEVNULL)
        data = json.loads(out)
        if not data:
            return ""
        
        cls = data.get("class", "") or data.get("initialClass", "")
        if not cls:
            return ""

        mapping = {
            "org.kde.dolphin": "Dolphin",
            "org.gnome.nautilus": "Nautilus",
            "io.github.zen_browser.zen": "Zen Browser",
            "zen-alpha": "Zen Browser",
            "zen": "Zen Browser",
            "youtube-music-desktop-app": "YouTube Music",
            "code-url-handler": "VS Code",
            "code": "VS Code",
            "kitty": "Kitty",
            "spotify": "Spotify",
            "discord": "Discord",
            "com.obsproject.Studio": "OBS Studio",
            "org.telegram.desktop": "Telegram",
            "vlc": "VLC",
            "mpv": "MPV",
            "steam": "Steam",
            "rquickshare": "Quick Share",
            "swaync-control-center": "SwayNC",
        }

        if cls in mapping:
            return mapping[cls]

        parts = cls.split(".")
        name = parts[-1] if len(parts) > 1 else cls
        name = name.replace("-", " ").replace("_", " ").title()
        return name
    except Exception:
        return ""

if __name__ == "__main__":
    app_name = get_clean_app_name()
    print(json.dumps({"text": app_name, "tooltip": app_name}), flush=True)
