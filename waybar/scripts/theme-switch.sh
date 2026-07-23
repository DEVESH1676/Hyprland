#!/bin/bash

# Theme Switcher Script
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
CURRENT_WALLPAPER_FILE="$HOME/.cache/current_wallpaper"
SYMLINK_PATH="$HOME/.config/hypr/current_wallpaper"
HYPRLOCK_CONFIG="$HOME/.config/hypr/hyprlock.conf"

# Collect wallpapers
mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | sort -V)

if [ ${#WALLPAPERS[@]} -eq 0 ]; then
  notify-send "Theme Switcher" "No wallpapers found in $WALLPAPER_DIR"
  exit 1
fi

# Helpers
get_current_index() {
  if [ -L "$SYMLINK_PATH" ]; then
    local current_real
    current_real=$(readlink -f "$SYMLINK_PATH")
    for i in "${!WALLPAPERS[@]}"; do
      if [ "${WALLPAPERS[$i]}" = "$current_real" ]; then
        echo "$i"
        return
      fi
    done
  fi
  if [ -f "$CURRENT_WALLPAPER_FILE" ]; then
    local cached_path
    cached_path=$(cat "$CURRENT_WALLPAPER_FILE")
    for i in "${!WALLPAPERS[@]}"; do
      if [ "${WALLPAPERS[$i]}" = "$cached_path" ]; then
        echo "$i"
        return
      fi
    done
  fi
  echo "0"
}

apply_theme() {
  local wallpaper_path="$1"
  local index="$2"
  local wallpaper_name
  wallpaper_name=$(basename "$wallpaper_path")

  echo "$wallpaper_path" >"$CURRENT_WALLPAPER_FILE"
  mkdir -p "$(dirname "$SYMLINK_PATH")"
  ln -sf "$wallpaper_path" "$SYMLINK_PATH"

  # Generate random float between 0.0 and 1.0 for X and Y
  local rand_x=$(awk -v r=$RANDOM 'BEGIN{srand(r); print rand()}')
  local rand_y=$(awk -v r=$RANDOM 'BEGIN{srand(r); print rand()}')
  local random_pos="${rand_x},${rand_y}"

  # Apply wallpaper with random grow origin
  awww init &>/dev/null || true
  awww img "$wallpaper_path" \
    --transition-type grow \
    --transition-fps 60 \
    --transition-duration 1.2 \
    --transition-pos "$random_pos"

  # Wait for wallpaper to be fully loaded before generating colors
  sleep 0.3

  update_hyprlock_wallpaper "$wallpaper_path"

  # Generate color scheme with Pywal (for terminal)
  if command -v wal &> /dev/null; then
    wal -q -i "$wallpaper_path" --backend colorthief -n

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

  # Generate color scheme with Matugen (for UI/Apps)
  if command -v matugen &> /dev/null; then
    matugen image "$wallpaper_path" -m dark --source-color-index 0 > /dev/null 2>&1
  fi

  notify-send "Theme Switcher" "Applied: $wallpaper_name"
}

update_hyprlock_wallpaper() {
  local wallpaper_path="$1"
  if [ -f "$HYPRLOCK_CONFIG" ]; then
    sed -i "/background {/,/}/{s|path = .*|path = $wallpaper_path|}" "$HYPRLOCK_CONFIG"
  fi
}

restore_theme() {
  local index=$(get_current_index)
  apply_theme "${WALLPAPERS[$index]}" "$index"
}

# Main
case "${1:-next}" in
"next")
  curr=$(get_current_index)
  next_index=$(((curr + 1) % ${#WALLPAPERS[@]}))
  apply_theme "${WALLPAPERS[$next_index]}" "$next_index"
  ;;
"random")
  random_index=$((RANDOM % ${#WALLPAPERS[@]}))
  apply_theme "${WALLPAPERS[$random_index]}" "$random_index"
  ;;
"restore")
  restore_theme
  ;;
"list")
  curr_idx=$(get_current_index)
  selected=$(printf "%s\n" "${WALLPAPERS[@]##*/}" | rofi -dmenu -p "Choose Wallpaper" -i -selected-row "$curr_idx")

  if [ -n "$selected" ]; then
    for i in "${!WALLPAPERS[@]}"; do
      if [[ "${WALLPAPERS[$i]##*/}" == "$selected" ]]; then
        apply_theme "${WALLPAPERS[$i]}" "$i"
        break
      fi
    done
  else
    notify-send "Theme Switcher" "No wallpaper selected."
  fi
  ;;
esac
