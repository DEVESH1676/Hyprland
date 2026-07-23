# 🖥️ Hyprland Dotfiles

My personal [Hyprland](https://hyprland.org) desktop configuration for Arch Linux — featuring dynamic wallpaper theming, a custom audio visualizer, and a fully riced notification center.

---

## ✨ Features

- 🎨 **Dual Color Engine** — [Pywal](https://github.com/dylanaraps/pywal) (terminal) + [Matugen](https://github.com/InioX/matugen) (apps/UI) auto-generate color palettes from your wallpaper
- 🎵 **Live Audio Visualizer** — 60 FPS unicode equalizer bars pulsing in Waybar + 6 GPU GLSL shader presets
- 📶 **Rofi Wi-Fi Manager** — High-contrast signal/lock icons, modal password dialog, disconnect support
- 🔔 **SwayNC Notification Center** — Pywal-synced theme with media player, volume/brightness sliders, and quick-action grid
- 🔊 **SwayOSD** — On-screen display for volume (2% steps), brightness (exact 5% steps), Caps/Num Lock
- 🚪 **Wlogout** — Logout menu with hover icon effects
- 🖼️ **Wallpaper Picker** — `Super+W` opens a file picker that transitions wallpaper with grow animation and reloads all color engines

---

## 📦 Components

| Component | Purpose | Config Path |
| :--- | :--- | :--- |
| [Hyprland](https://hyprland.org) | Wayland compositor | `hypr/` |
| [Waybar](https://github.com/Alexays/Waybar) | Status bar | `waybar/` |
| [Rofi](https://github.com/davatorium/rofi) | App launcher & Wi-Fi menu | `rofi/` |
| [Kitty](https://sw.kovidgoyal.net/kitty/) | Terminal emulator | `kitty/` |
| [SwayNC](https://github.com/ErikReider/SwayNotificationCenter) | Notification center | `swaync/` |
| [SwayOSD](https://github.com/ErikReider/SwayOSD) | On-screen display | `swayosd/` |
| [Wlogout](https://github.com/ArtsyMacaw/wlogout) | Logout menu | `wlogout/` |
| [Cava](https://github.com/karlstav/cava) | Audio visualizer | `cava/` |
| [Fastfetch](https://github.com/fastfetch-cli/fastfetch) | System info | `fastfetch/` |
| [Pywal](https://github.com/dylanaraps/pywal) | Terminal color schemes | `wal/` |
| [Matugen](https://github.com/InioX/matugen) | Material You theming | `matugen/` |

---

## 🔧 Dependencies

```bash
# Core
sudo pacman -S hyprland waybar rofi kitty swaync cava fastfetch brightnessctl playerctl wl-clipboard

# Theming
sudo pacman -S python-pywal python-colorthief
yay -S matugen-bin swayosd-git

# Wallpaper & Lock
yay -S awww hyprlock hypridle hyprpicker

# Notifications & Logout
sudo pacman -S libnotify wlogout
```

---

## 🚀 Installation

```bash
# 1. Clone this repo
git clone https://github.com/DEVESH1676/Hyprland.git ~/Hyprland

# 2. Backup your existing configs (optional)
mkdir -p ~/config-backup
for dir in hypr waybar wlogout rofi kitty swaync swayosd cava fastfetch matugen wal; do
  [ -d "$HOME/.config/$dir" ] && cp -r "$HOME/.config/$dir" ~/config-backup/
done

# 3. Deploy configs to ~/.config
cd ~/Hyprland
for dir in hypr waybar wlogout rofi kitty swaync swayosd cava fastfetch matugen wal; do
  [ -d "$dir" ] && cp -r "$dir" "$HOME/.config/"
done

# 4. Make scripts executable
chmod +x ~/.config/hypr/scripts/*.sh
chmod +x ~/.config/waybar/scripts/*.sh
chmod +x ~/.config/cava/cava_waybar.sh

# 5. Log out and log back into Hyprland
```

---

## 🎨 How Theming Works


When you change your wallpaper (`Super+W` or the Waybar theme button):

1. **awww** — Sets the new wallpaper with a grow transition animation
2. **Pywal** — Extracts colors using `colorthief` backend → updates terminal, Cava gradients
3. **Matugen** — Generates Material You tokens → updates Rofi, SwayNC, Kitty, GTK apps
4. **Hyprlock** — Updates lockscreen background to match

All of this happens automatically in a single keypress.

---

## 🔄 Updating Your Backup

After making changes to your live config, sync them back to this repo:

```bash
cd ~/Hyprland

# Sync all configs from live system to repo
for dir in hypr waybar wlogout rofi kitty swaync swayosd cava fastfetch matugen wal; do
  [ -d "$HOME/.config/$dir" ] && rsync -av --delete --exclude='.git*' "$HOME/.config/$dir/" "$dir/"
done

# Commit and push
git add .
git commit -m "Update configs $(date +%Y-%m-%d)"
git push
```

### One-Liner Update

```bash
cd ~/Hyprland && for d in hypr waybar wlogout rofi kitty swaync swayosd cava fastfetch matugen wal; do [ -d "$HOME/.config/$d" ] && rsync -av --delete --exclude='.git*' "$HOME/.config/$d/" "$d/"; done && git add . && git commit -m "Update $(date +%Y-%m-%d)" && git push
```

---

## 📁 Directory Structure

```
~/Hyprland/
├── cava/           # Audio visualizer + Waybar equalizer + GPU shaders
├── fastfetch/      # Terminal system info + custom profiles
├── hypr/           # Hyprland core config + keybinds + scripts
├── kitty/          # Terminal emulator + Matugen color template
├── matugen/        # Material You theme generator config + templates
├── rofi/           # App launcher + dynamic wallpaper colors
├── swaync/         # Notification center + Pywal theme + icons
├── swayosd/        # Volume/brightness/lock OSD styling
├── wal/            # Pywal custom colorschemes + templates
├── waybar/         # Status bar + Wi-Fi menu + theme switcher
└── wlogout/        # Logout menu + hover icon effects
```


