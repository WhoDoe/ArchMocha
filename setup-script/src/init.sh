#!/bin/bash

# Define current user name (use SUDO_USER if available, fallback to logname or whoami)
USER_NAME="${SUDO_USER:-$(logname 2>/dev/null || whoami)}"

# Define user's home directory using a reliable method
if command -v getent &>/dev/null; then
  USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)
else
  USER_HOME=$(eval echo "~$USER_NAME")
fi

# Define current script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define Hyprland configuration directory
HYPR_CONF_DIR="$USER_HOME/.config/hypr"

# Define GTK settings file
GTK_SETTINGS_FILE="$USER_HOME/.config/gtk-3.0/settings.ini"

# Define GTK theme name
GTK_THEME_NAME="Catppuccin-Mocha-Standard-Mauve-Dark"

# Define icon theme name
ICON_THEME_NAME="Papirus-Dark"

# Define cursor theme name
CURSOR_THEME_NAME="catppuccin-mocha-dark-cursors"

# Define cursor size
CURSOR_SIZE=24

# Define Git repository for Catppuccin Hyprland
CATPPUCCIN_HYPRLAND_REPO="https://github.com/catppuccin/hyprland.git"

# Define temporary directory for Catppuccin
CATPPUCCIN_TEMP_DIR="/tmp/catppuccin-hyprland"

# Define Git repository for Momoisay
MOMOISAY_REPO="https://github.com/Mon4sm/Momoisay.git"

# Define temporary directory for Momoisay
MOMOISAY_TEMP_DIR="/tmp/Momoisay"