#!/bin/bash

# === CONFIG ===
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
SYMLINK_PATH="$HOME/.config/hypr/current_wallpaper"
HYPRLOCK_CONFIG="$HOME/.config/hypr/hyprlock.conf"

cd "$WALLPAPER_DIR" || exit 1

# === handle spaces in names ===
IFS=$'\n'

# === ICON-PREVIEW SELECTION WITH ROFI, SORTED BY NEWEST ===
SELECTED_WALL=$(for a in $(ls -t *.jpg *.png *.gif *.jpeg 2>/dev/null); do echo -en "$a\0icon\x1f$a\n"; done | rofi -dmenu -p "")
[ -z "$SELECTED_WALL" ] && exit 1
SELECTED_PATH="$WALLPAPER_DIR/$SELECTED_WALL"

# === SET WALLPAPER WITH SMOOTH TRANSITION ===
awww init &>/dev/null || true
awww img "$SELECTED_PATH" \
  --transition-type grow \
  --transition-fps 60 \
  --transition-duration 1.2 \
  --transition-pos "$(awk -v r=$RANDOM 'BEGIN{srand(r); print rand()}'),$(awk -v r=$RANDOM 'BEGIN{srand(r); print rand()}')"

# === GENERATE COLOR SCHEMES ===
# Pywal for terminal colors
if command -v wal &> /dev/null; then
  wal -q -i "$SELECTED_PATH" --backend colorthief -n

  # Dynamically update Cava gradient colors
  if [ -f "$HOME/.cache/wal/colors" ] && [ -f "$HOME/.config/cava/config" ]; then
    mapfile -t WAL_COLORS < "$HOME/.cache/wal/colors"
    if [ ${#WAL_COLORS[@]} -ge 7 ]; then
      sed -i "s/gradient_color_1 = .*/gradient_color_1 = '${WAL_COLORS[1]}'/" "$HOME/.config/cava/config"
      sed -i "s/gradient_color_2 = .*/gradient_color_2 = '${WAL_COLORS[2]}'/" "$HOME/.config/cava/config"
      sed -i "s/gradient_color_3 = .*/gradient_color_3 = '${WAL_COLORS[3]}'/" "$HOME/.config/cava/config"
      sed -i "s/gradient_color_4 = .*/gradient_color_4 = '${WAL_COLORS[4]}'/" "$HOME/.config/cava/config"
      sed -i "s/gradient_color_5 = .*/gradient_color_5 = '${WAL_COLORS[5]}'/" "$HOME/.config/cava/config"
      sed -i "s/gradient_color_6 = .*/gradient_color_6 = '${WAL_COLORS[6]}'/" "$HOME/.config/cava/config"
      pkill -USR2 cava 2>/dev/null || true
    fi
  fi
fi

# Matugen for app/UI colors
if command -v matugen &> /dev/null; then
  matugen image "$SELECTED_PATH" -m dark --source-color-index 0 > /dev/null 2>&1
fi

# === UPDATE HYPRLOCK WALLPAPER ===
if [ -f "$HYPRLOCK_CONFIG" ]; then
  sed -i "/background {/,/}/{s|path = .*|path = $SELECTED_PATH|}" "$HYPRLOCK_CONFIG"
fi

# === CREATE SYMLINK ===
mkdir -p "$(dirname "$SYMLINK_PATH")"
ln -sf "$SELECTED_PATH" "$SYMLINK_PATH"

notify-send "Wallpaper" "Applied: $SELECTED_WALL"
