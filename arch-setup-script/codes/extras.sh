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
  # Prompt for sudo credentials at the start to cache them
  log INFO "Authenticating sudo for the installation process..."
  sudo -v || { log ERROR "Sudo authentication failed. Please ensure you have sudo privileges."; return 1; }

  # Check if steam is already installed
  if command -v steam &>/dev/null; then
    log INFO "Steam is already installed, skipping."
    return 0
  fi

  # Log start of installation
  log INFO "Installing Steam and required drivers..."

  # Perform a full system update first
  log INFO "Performing full system update..."
  sudo pacman -Syu --noconfirm &
  pid=$!
  spinner $pid "Updating system..."
  wait $pid || { log ERROR "Failed to update system!"; return 1; }

  # Enable multilib repository if not already enabled
  if ! grep -q '^\[multilib\]$' /etc/pacman.conf; then
    log INFO "Enabling multilib repository..."
    sudo sed -i "/\[multilib\]/,/Include/s/^#//" /etc/pacman.conf || { log ERROR "Failed to enable multilib repository!"; return 1; }
    sudo pacman -Syu --noconfirm &
    pid=$!
    spinner $pid "Updating package database after enabling multilib..."
    wait $pid || { log ERROR "Failed to update package database!"; return 1; }
  else
    log INFO "Multilib repository is already enabled."
  fi

  # Install additional 32-bit support packages
  log INFO "Installing additional 32-bit support packages..."
  sudo pacman -S --noconfirm --needed lib32-gcc-libs lib32-glibc &
  pid=$!
  spinner $pid "Installing 32-bit support..."
  wait $pid || { log WARN "Failed to install 32-bit support packages. Continuing..."; }

  # Detect GPU type
  log INFO "Detecting GPU..."
  GPU_TYPE="none"
  if lspci | grep -iE "vga|3d|display" | grep -i nvidia > /dev/null; then
    GPU_TYPE="nvidia"
    log INFO "NVIDIA GPU detected."
  elif lspci | grep -iE "vga|3d|display" | grep -i amd > /dev/null; then
    GPU_TYPE="amd"
    log INFO "AMD GPU detected."
  elif lspci | grep -iE "vga|3d|display" | grep -i intel > /dev/null; then
    GPU_TYPE="intel"
    log INFO "Intel GPU detected."
  else
    log WARN "No supported GPU detected. Falling back to Mesa for OpenGL support."
  fi

  # Install GPU drivers based on detection
  case "$GPU_TYPE" in
    nvidia)
      # Detect if newer GPU for nvidia-open (Turing+), fallback to nvidia
      log INFO "Checking NVIDIA GPU generation..."
      # Simple check: assume modern, use open if available; but for script, use dkms for flexibility
      KERNEL=$(uname -r)
      if [[ $KERNEL == *-lts || $KERNEL == *-rt || $KERNEL == *-zen || $KERNEL == *-hardened ]]; then
        DRIVER="nvidia-open-dkms"  # Prefer open for newer
        if ! pacman -Ss nvidia-open-dkms &>/dev/null; then
          DRIVER="nvidia-dkms"
        fi
        log INFO "Selected $DRIVER for kernel $KERNEL (custom kernel detected)."
      else
        DRIVER="nvidia-open"
        if ! pacman -Ss nvidia-open &>/dev/null; then
          DRIVER="nvidia"
        fi
        log INFO "Selected $DRIVER for kernel $KERNEL."
      fi

      # Handle package conflicts (expanded for open variants)
      log INFO "Checking for package conflicts..."
      CONFLICTING_PKGS=("nvidia" "nvidia-dkms" "nvidia-open" "nvidia-open-dkms")
      for pkg in "${CONFLICTING_PKGS[@]}"; do
        if pacman -Qs "^$pkg$" > /dev/null && [ "$pkg" != "$DRIVER" ]; then
          log INFO "Removing conflicting package $pkg to install $DRIVER..."
          sudo pacman -Rdd --noconfirm "$pkg" || { log ERROR "Failed to remove $pkg package!"; return 1; }
        fi
      done

      # Install NVIDIA driver and related packages
      log INFO "Installing $DRIVER, nvidia-utils, lib32-nvidia-utils, vulkan-icd-loader, lib32-vulkan-icd-loader, nvidia-settings..."
      sudo pacman -S --noconfirm --needed "$DRIVER" nvidia-utils lib32-nvidia-utils vulkan-icd-loader lib32-vulkan-icd-loader nvidia-settings &
      pid=$!
      spinner $pid "Installing NVIDIA drivers and libraries..."
      wait $pid || { log ERROR "Failed to install NVIDIA drivers!"; return 1; }

      # Generate Xorg configuration only if X11 is in use
      if [[ -n "$DISPLAY" && "$XDG_SESSION_TYPE" == "x11" ]]; then
        log INFO "Generating Xorg configuration for NVIDIA..."
        sudo nvidia-xconfig || { log WARN "Failed to generate Xorg configuration. This may not be needed on Wayland."; }
      else
        log INFO "Skipping Xorg configuration (Wayland or no display detected)."
      fi

      # Enable DRM kernel mode setting for Wayland (if not default)
      log INFO "Ensuring NVIDIA DRM modeset for Wayland..."
      if [ ! -f /etc/modprobe.d/nvidia.conf ]; then
        echo "options nvidia_drm modeset=1 fbdev=1" | sudo tee /etc/modprobe.d/nvidia.conf
      fi

      # Verify NVIDIA driver
      if command -v nvidia-smi &>/dev/null; then
        log INFO "NVIDIA driver installed successfully:"
        nvidia-smi
      else
        log ERROR "NVIDIA driver verification failed! nvidia-smi not found."
        return 1
      fi
      ;;

    amd)
      log INFO "Installing AMD drivers: mesa lib32-mesa amdvlk vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader..."
      sudo pacman -S --noconfirm --needed mesa lib32-mesa amdvlk vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader &
      pid=$!
      spinner $pid "Installing AMD drivers and libraries..."
      wait $pid || { log ERROR "Failed to install AMD drivers!"; return 1; }
      ;;

    intel)
      log INFO "Installing Intel drivers: mesa lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader..."
      sudo pacman -S --noconfirm --needed mesa lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader &
      pid=$!
      spinner $pid "Installing Intel drivers and libraries..."
      wait $pid || { log ERROR "Failed to install Intel drivers!"; return 1; }
      ;;

    *)
      log INFO "Installing generic Mesa for OpenGL support..."
      sudo pacman -S --noconfirm --needed mesa lib32-mesa vulkan-icd-loader lib32-vulkan-icd-loader &
      pid=$!
      spinner $pid "Installing Mesa and Vulkan libraries..."
      wait $pid || { log ERROR "Failed to install Mesa packages!"; return 1; }
      ;;
  esac

  # Install steam and steam-native-runtime
  log INFO "Installing Steam and steam-native-runtime..."
  sudo pacman -S --noconfirm --needed steam steam-native-runtime &
  pid=$!
  spinner $pid "Installing Steam and native runtime..."
  wait $pid || { log ERROR "Failed to install Steam and steam-native-runtime!"; return 1; }

  # Install font packages for better Steam compatibility
  log INFO "Installing fonts for Steam..."
  sudo pacman -S --noconfirm --needed ttf-liberation &
  pid=$!
  spinner $pid "Installing fonts..."
  wait $pid || { log WARN "Failed to install fonts. Continuing..."; }

  # Verify Steam installation
  if ! command -v steam &>/dev/null; then
    log ERROR "Steam installation verification failed! Steam is not available after installation."
    return 1
  fi

  # Ensure tools for verification are installed
  log INFO "Ensuring verification tools are installed..."
  sudo pacman -S --noconfirm --needed mesa-demos vulkan-tools &
  pid=$!
  spinner $pid "Installing mesa-demos and vulkan-tools..."
  wait $pid || { log WARN "Failed to install verification tools. Skipping some checks."; }

  # Verify OpenGL support
  log INFO "Checking OpenGL support..."
  if command -v glxinfo &>/dev/null; then
    glxinfo | grep "OpenGL version" || log WARN "OpenGL check returned no output."
  else
    log WARN "glxinfo not found. OpenGL support check skipped."
  fi

  # Verify Vulkan support
  log INFO "Checking Vulkan support..."
  if command -v vulkaninfo &>/dev/null; then
    vulkaninfo --summary || log WARN "Vulkan check returned no output."
  else
    log WARN "vulkaninfo not found. Vulkan support check skipped."
  fi

  # Add symlinks for libpcre if not exist (for native runtime fixes)
  if [ ! -L /usr/lib/libpcre.so.3 ]; then
    sudo ln -s /usr/lib/libpcre.so.1 /usr/lib/libpcre.so.3
  fi
  if [ ! -L /usr/lib32/libpcre.so.3 ]; then
    sudo ln -s /usr/lib32/libpcre.so.1 /usr/lib32/libpcre.so.3
  fi

  # Configure Steam desktop file for auto-launch with LD_PRELOAD and flags
  log INFO "Configuring Steam desktop file for native runtime with fixes..."
  LOCAL_DESKTOP="$HOME/.local/share/applications/steam.desktop"
  mkdir -p "$HOME/.local/share/applications"
  if [ ! -f "$LOCAL_DESKTOP" ]; then
    cp /usr/share/applications/steam.desktop "$LOCAL_DESKTOP"
  fi
  if ! grep -q "steam-native" "$LOCAL_DESKTOP"; then
    cp "$LOCAL_DESKTOP" "$LOCAL_DESKTOP.bak"
    sed -i 's|^Exec=/usr/bin/steam %U|Exec=env LD_PRELOAD="/usr/lib32/libgio-2.0.so.0 /usr/lib32/libglib-2.0.so.0 /usr/lib32/libgmodule-2.0.so.0 /usr/lib/libgio-2.0.so.0 /usr/lib/libglib-2.0.so.0 /usr/lib/libgmodule-2.0.so.0" /usr/bin/steam-native %U -no-cef-sandbox|' "$LOCAL_DESKTOP"
    log INFO "Steam desktop file configured for native runtime with LD_PRELOAD and -no-cef-sandbox."
  else
    log INFO "Steam desktop file already configured."
  fi

  # Log success
  log SUCCESS "Steam and drivers installed successfully! Launch Steam from your menu or run 'steam-native' with the configured options."
  log INFO "Please reboot your system to apply changes, especially for driver modules."
  log INFO "If issues persist, try Steam Beta or manual launch: steam-native -no-cef-sandbox."
  return 0
}