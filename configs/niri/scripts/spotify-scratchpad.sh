#!/usr/bin/env bash

SCRATCH_WS="scratch"

WIN_ID=$(niri msg -j windows | jq -r '
    .[] | select(.app_id=="spotify") | .id
' | head -n1)

CURRENT_WS=$(niri msg -j workspaces | jq -r '
    .[] | select(.is_active==true) | .name // .id
')

# Launch Spotify if not running
if [ -z "$WIN_ID" ]; then
    spotify &
    exit 0
fi

# Check if Spotify is focused
FOCUSED=$(niri msg -j windows | jq -r "
    .[] | select(.id==$WIN_ID) | .is_focused
")

if [ "$FOCUSED" = "true" ]; then
    # Hide Spotify
    niri msg action move-window-to-workspace "$SCRATCH_WS"
else
    # Bring Spotify back
    niri msg action move-window-to-workspace "$CURRENT_WS"
    niri msg action focus-window
fi
