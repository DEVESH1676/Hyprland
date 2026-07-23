#!/bin/bash

# === CONFIG ===
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
SYMLINK_PATH="$HOME/.config/hypr/current_wallpaper"
CACHE_FILE="$HOME/.cache/current_wallpaper"
HYPRLOCK_CONFIG="$HOME/.config/hypr/hyprlock.conf"

cd "$WALLPAPER_DIR" || exit 1

# Collect all wallpapers sorted naturally
mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | sort -V)

if [ ${#WALLPAPERS[@]} -eq 0 ]; then
  notify-send "Wallpaper" "No wallpapers found in $WALLPAPER_DIR"
  exit 1
fi

# Detect current active wallpaper
CURRENT_NAME=""
if [ -L "$SYMLINK_PATH" ]; then
  CURRENT_NAME=$(basename "$(readlink -f "$SYMLINK_PATH")")
elif [ -f "$CACHE_FILE" ]; then
  CURRENT_NAME=$(basename "$(cat "$CACHE_FILE")")
fi

# Determine 0-indexed row for rofi -selected-row
SELECTED_ROW=0
for i in "${!WALLPAPERS[@]}"; do
  fname=$(basename "${WALLPAPERS[$i]}")
  if [ "$fname" = "$CURRENT_NAME" ]; then
    SELECTED_ROW=$i
    break
  fi
done

# Build Rofi input string with icon preview
ROFI_INPUT=""
for wp in "${WALLPAPERS[@]}"; do
  fname=$(basename "$wp")
  ROFI_INPUT+="${fname}\0icon\x1f${wp}\n"
done

# Launch Rofi with -selected-row pointing to current wallpaper
SELECTED_WALL=$(echo -en "$ROFI_INPUT" | rofi -dmenu -p "Wallpaper" -i -selected-row "$SELECTED_ROW")
[ -z "$SELECTED_WALL" ] && exit 0

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

# === CREATE SYMLINK & SAVE CACHE ===
mkdir -p "$(dirname "$SYMLINK_PATH")"
ln -sf "$SELECTED_PATH" "$SYMLINK_PATH"
echo "$SELECTED_PATH" > "$CACHE_FILE"

notify-send "Wallpaper" "Applied: $SELECTED_WALL"
