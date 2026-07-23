#!/bin/bash

# Theme Switcher Script
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
CURRENT_WALLPAPER_FILE="$HOME/.cache/current_wallpaper"

# Collect wallpapers
mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | sort)

if [ ${#WALLPAPERS[@]} -eq 0 ]; then
  notify-send "Theme Switcher" "No wallpapers found in $WALLPAPER_DIR"
  exit 1
fi

# Helpers
get_current_index() {
  [[ -f "$CURRENT_WALLPAPER_FILE" ]] && cat "$CURRENT_WALLPAPER_FILE" || echo "0"
}

apply_theme() {
  local wallpaper_path="$1"
  local index="$2"
  local wallpaper_name
  wallpaper_name=$(basename "$wallpaper_path")

  echo "$index" >"$CURRENT_WALLPAPER_FILE"

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
  local hyprlock_config="$HOME/.config/hypr/hyprlock.conf"

  [[ ! -f "${hyprlock_config}.backup" ]] && cp "$hyprlock_config" "${hyprlock_config}.backup"

  sed -i "/background {/,/}/{s|path = .*|path = $wallpaper_path|}" "$hyprlock_config"
}

restore_theme() {
  local index=$(get_current_index)
  apply_theme "${WALLPAPERS[$index]}" "$index"
}

# Main
case "${1:-next}" in
"next")
  next_index=$((($(get_current_index) + 1) % ${#WALLPAPERS[@]}))
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
  # Show only filenames in wofi
  selected=$(printf "%s\n" "${WALLPAPERS[@]##*/}" | rofi -dmenu -p "Choose Wallpaper" -i)

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
