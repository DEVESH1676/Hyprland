#!/bin/bash

# Check if required tools are installed
if ! command -v playerctl &>/dev/null; then
  echo "playerctl not found. Please install it."
  notify-send "SwayNC Error" "playerctl not found. Please install it."
  exit 1
fi
if ! command -v curl &>/dev/null; then
  echo "curl not found. Please install it."
  notify-send "SwayNC Error" "curl not found. Please install it."
  exit 1
fi

# Directory to cache album art
CACHE_DIR="$HOME/.cache/swaync"
mkdir -p "$CACHE_DIR"

# Get current mpris:artUrl from Spotify
ART_URL=$(playerctl --player=spotify metadata mpris:artUrl 2>/dev/null)

if [[ -z "$ART_URL" ]]; then
  echo "No art URL found for Spotify."
  notify-send "SwayNC Error" "No art URL found for Spotify."
  exit 1
fi

# Check if the URL is the outdated Spotify format
if [[ "$ART_URL" == https://open.spotify.com/image/* ]]; then
  # Extract the image ID from the URL
  IMAGE_ID=$(echo "$ART_URL" | sed 's|https://open.spotify.com/image/||')
  # Rewrite to the correct URL
  NEW_ART_URL="https://i.scdn.co/image/$IMAGE_ID"

  # Download the image to cache
  CACHE_PATH="$CACHE_DIR/spotify_album_art.jpg"
  curl -s "$NEW_ART_URL" -o "$CACHE_PATH"

  if [[ -f "$CACHE_PATH" ]]; then
    echo "Downloaded corrected album art to $CACHE_PATH"
    # Notify swaync to reload
    swaync-client --reload-config
  else
    echo "Failed to download album art from $NEW_ART_URL"
    notify-send "SwayNC Error" "Failed to download Spotify album art."
  fi
else
  # If the URL is already correct, cache it
  CACHE_PATH="$CACHE_DIR/spotify_album_art.jpg"
  curl -s "$ART_URL" -o "$CACHE_PATH"
  if [[ -f "$CACHE_PATH" ]]; then
    echo "Cached existing art URL to $CACHE_PATH"
    swaync-client --reload-config
  else
    echo "Failed to cache art from $ART_URL"
    notify-send "SwayNC Error" "Failed to cache Spotify album art."
  fi
fi
