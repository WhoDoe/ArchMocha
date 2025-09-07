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
  log INFO "Installing Steam and required drivers..."

  # Enable multilib repository if not already enabled
  if ! grep -q '^\[multilib\]$' /etc/pacman.conf; then
    log INFO "Enabling multilib repository..."
    sed -i "/\[multilib\]/,/Include/s/^#//" /etc/pacman.conf || { log ERROR "Failed to enable multilib repository!"; return 1; }
    pacman -Syu --noconfirm &
    pid=$!
    spinner $pid "Updating package database after enabling multilib..."
    wait $pid || { log ERROR "Failed to update package database!"; return 1; }
  else
    log INFO "Multilib repository is already enabled."
  fi

  # Detect NVIDIA GPU
  log INFO "Detecting GPU..."
  if lspci | grep -i nvidia > /dev/null; then
    log INFO "NVIDIA GPU detected."

    # Check kernel type to decide between nvidia and nvidia-dkms
    KERNEL=$(uname -r)
    if [[ $KERNEL == *-lts || $KERNEL == *-rt ]]; then
      DRIVER="nvidia-dkms"
      log INFO "Selected $DRIVER for kernel $KERNEL."
    else
      DRIVER="nvidia"
      log INFO "Selected $DRIVER for kernel $KERNEL."
    fi

    # Handle package conflicts
    log INFO "Checking for package conflicts..."
    if pacman -Qs nvidia > /dev/null && [ "$DRIVER" = "nvidia-dkms" ]; then
      log INFO "Removing nvidia to install nvidia-dkms..."
      pacman -R --noconfirm nvidia || { log ERROR "Failed to remove nvidia package!"; return 1; }
    elif pacman -Qs nvidia-dkms > /dev/null && [ "$DRIVER" = "nvidia" ]; then
      log INFO "Removing nvidia-dkms to install nvidia..."
      pacman -R --noconfirm nvidia-dkms || { log ERROR "Failed to remove nvidia-dkms package!"; return 1; }
    fi

    # Install NVIDIA driver and related packages
    log INFO "Installing $DRIVER, nvidia-utils, lib32-nvidia-utils, vulkan-icd-loader, lib32-vulkan-icd-loader..."
    pacman -S --noconfirm --needed $DRIVER nvidia-utils lib32-nvidia-utils vulkan-icd-loader lib32-vulkan-icd-loader &
    pid=$!
    spinner $pid "Installing NVIDIA drivers and libraries..."
    wait $pid || { log ERROR "Failed to install NVIDIA drivers!"; return 1; }

    # Generate Xorg configuration
    log INFO "Generating Xorg configuration for NVIDIA..."
    nvidia-xconfig || { log ERROR "Failed to generate Xorg configuration!"; return 1; }

    # Verify NVIDIA driver
    if command -v nvidia-smi &>/dev/null; then
      log INFO "NVIDIA driver installed successfully:"
      nvidia-smi
    else
      log ERROR "NVIDIA driver verification failed! nvidia-smi not found."
      return 1
    fi
  else
    log INFO "No NVIDIA GPU detected. Installing mesa for OpenGL support..."
    pacman -S --noconfirm --needed mesa lib32-mesa &
    pid=$!
    spinner $pid "Installing mesa and lib32-mesa..."
    wait $pid || { log ERROR "Failed to install mesa packages!"; return 1; }
  fi

  # Install steam and steam-native-runtime
  log INFO "Installing Steam and steam-native-runtime..."
  pacman -S --noconfirm --needed steam steam-native-runtime &
  pid=$!
  spinner $pid "Installing Steam and native runtime..."
  wait $pid || { log ERROR "Failed to install Steam and steam-native-runtime!"; return 1; }

  # Verify Steam installation
  if ! command -v steam &>/dev/null; then
    log ERROR "Steam installation verification failed! Steam is not available after installation."
    return 1
  fi

  # Verify OpenGL support
  log INFO "Checking OpenGL support..."
  if command -v glxinfo &>/dev/null; then
    glxinfo | grep "OpenGL version" || log WARN "OpenGL check returned no output."
  else
    log WARN "glxinfo not found. Installing mesa-demos..."
    pacman -S --noconfirm mesa-demos &
    pid=$!
    spinner $pid "Installing mesa-demos..."
    wait $pid || { log ERROR "Failed to install mesa-demos!"; return 1; }
    glxinfo | grep "OpenGL version" || log WARN "OpenGL check returned no output."
  fi

  # Verify Vulkan support
  log INFO "Checking Vulkan support..."
  if command -v vulkaninfo &>/dev/null; then
    vulkaninfo --summary || log WARN "Vulkan check returned no output."
  else
    log WARN "vulkaninfo not found. Vulkan may not be fully supported."
  fi

  # Log success
  log SUCCESS "Steam and drivers installed successfully! Run 'steam' to launch."
  log INFO "Please reboot your system to apply changes."
  return 0
}