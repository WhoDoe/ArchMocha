#!/bin/bash

install_momoisay() {
  # Check if momoisay is already installed
  if command -v momoisay &>/dev/null; then
    log INFO "Momoisay is already installed, skipping."
    return 0
  fi

  # Log start of installation
  log INFO "Installing Momoisay from source..."

  # Prepare temporary directory using mktemp for safety
  local momoisay_dir
  momoisay_dir=$(mktemp -d /tmp/momoisay.XXXXXX) || { log ERROR "Failed to create temporary directory for Momoisay!"; return 1; }
  trap "rm -rf '$momoisay_dir'" RETURN  # Ensure cleanup on function return

  # Clone Momoisay repo as the user
  sudo -u "$USER_NAME" git clone "$MOMOISAY_REPO" "$momoisay_dir" &
  local pid=$!
  spinner $pid "Cloning Momoisay repository..."
  wait $pid || { log ERROR "Failed to clone Momoisay repository!"; return 1; }

  # Change into the temporary directory to build
  pushd "$momoisay_dir" >/dev/null || { log ERROR "Failed to change directory to $momoisay_dir!"; return 1; }

  # Build using make as the user (assuming no root required for build)
  sudo -u "$USER_NAME" make &
  local pid=$!
  spinner $pid "Building Momoisay..."
  wait $pid || { log ERROR "Failed to build Momoisay!"; popd >/dev/null; return 1; }

  # Copy binary to /usr/local/bin and set permissions
  sudo cp momoisay /usr/local/bin/ || { log ERROR "Failed to copy Momoisay binary!"; popd >/dev/null; return 1; }
  sudo chmod +x /usr/local/bin/momoisay || { log ERROR "Failed to set executable permission for Momoisay!"; popd >/dev/null; return 1; }

  # Exit directory
  popd >/dev/null

  # Verify installation
  if ! command -v momoisay &>/dev/null; then
    log ERROR "Momoisay installation verification failed! Momoisay is not available after installation."
    return 1
  fi

  # Log success
  log SUCCESS "Momoisay installed successfully! Run 'momoisay Hello' to test."
  return 0
}

install_steam() {
  # Check if steam is already installed
  if command -v steam &>/dev/null; then
    log INFO "Steam is already installed, skipping."
    return 0
  fi

  # Log start of installation
  log INFO "Installing Steam..."

  # Enable multilib repository if not already enabled
  if ! grep -q '^\[multilib\]$' /etc/pacman.conf; then
    log INFO "Enabling multilib repository..."
    sudo sed -i "/\[multilib\]/,/Include/s/^#//" /etc/pacman.conf || { log ERROR "Failed to enable multilib repository!"; return 1; }
    sudo pacman -Syu --noconfirm &
    local pid=$!
    spinner $pid "Updating package database after enabling multilib..."
    wait $pid || { log ERROR "Failed to update package database!"; return 1; }
  else
    log INFO "Multilib repository is already enabled."
  fi

  # Detect GPU and determine drivers
  log INFO "Detecting GPU..."
  local gpu
  gpu=$(lspci | grep -i --color=never 'vga\|3d\|2d') || { log ERROR "Failed to detect GPU!"; return 1; }

  local drivers=""
  if echo "$gpu" | grep -iq "nvidia"; then
    drivers="nvidia nvidia-utils lib32-nvidia-utils nvidia-settings"
    log INFO "NVIDIA GPU detected. Installing NVIDIA drivers."
  elif echo "$gpu" | grep -iq "amd\|ati"; then
    drivers="mesa vulkan-radeon lib32-mesa lib32-vulkan-radeon amdvlk lib32-amdvlk"
    log INFO "AMD GPU detected. Installing AMD drivers."
  elif echo "$gpu" | grep -iq "intel"; then
    drivers="mesa vulkan-intel lib32-mesa lib32-vulkan-intel"
    log INFO "Intel GPU detected. Installing Intel drivers."
  else
    drivers="mesa lib32-mesa"
    log WARNING "Unknown GPU detected. Installing fallback Mesa drivers."
  fi

  # Install GPU drivers
  if [ -n "$drivers" ]; then
    sudo pacman -S --noconfirm --needed $drivers &
    local pid=$!
    spinner $pid "Installing GPU drivers..."
    wait $pid || { log ERROR "Failed to install GPU drivers!"; return 1; }
  fi

  # Install steam and steam-native-runtime
  log INFO "Installing Steam and steam-native-runtime..."
  sudo pacman -S --noconfirm --needed steam steam-native-runtime &
  local pid=$!
  spinner $pid "Installing Steam and native runtime..."
  wait $pid || { log ERROR "Failed to install Steam and steam-native-runtime!"; return 1; }

  # Verify installation
  if ! command -v steam &>/dev/null; then
    log ERROR "Steam installation verification failed! Steam is not available after installation."
    return 1
  fi

  # Log success
  log SUCCESS "Steam installed successfully! Run 'steam' to launch."
  return 0
}