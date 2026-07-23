#!/usr/bin/env bash

# Hyprland Dotfiles Sync Script
# Syncs live ~/.config changes back to this repo and pushes to GitHub

set -e

REPO_DIR="$HOME/Hyprland"
CONFIGS=(hypr waybar wlogout rofi kitty swaync swayosd cava fastfetch matugen wal)

cd "$REPO_DIR"

echo "🔄 Syncing live configs to repo..."
for dir in "${CONFIGS[@]}"; do
  if [ -d "$HOME/.config/$dir" ]; then
    rsync -av --delete --exclude='.git*' "$HOME/.config/$dir/" "$REPO_DIR/$dir/"
    echo "  ✅ $dir"
  else
    echo "  ⚠️  $dir not found in ~/.config, skipping"
  fi
done

echo ""
echo "📝 Staging changes..."
git add .

# Check if there are changes to commit
if git diff --cached --quiet; then
  echo "✅ No changes detected — everything is up to date!"
  exit 0
fi

echo ""
git status --short
echo ""

COMMIT_MSG="Update configs $(date +%Y-%m-%d_%H:%M)"
git commit -m "$COMMIT_MSG"

echo ""
echo "🚀 Pushing to GitHub..."
git push

echo ""
echo "✅ Done! Backup updated on GitHub."
