#!/bin/bash

enable_services() {
  log INFO "Starting service enabling process..."

  # Check and install required system packages
  log INFO "Checking for required system packages..."
  local packages=("networkmanager" "bluez" "power-profiles-daemon")
  declare -a missing_pkgs=()
  for pkg in "${packages[@]}"; do
    if ! pacman -Qs "^${pkg}$" >/dev/null; then
      missing_pkgs+=("$pkg")
    else
      log INFO "$pkg is already installed."
    fi
  done

  if [[ ${#missing_pkgs[@]} -gt 0 ]]; then
    log INFO "Installing missing packages: ${missing_pkgs[*]}"
    sudo pacman -S --needed --noconfirm "${missing_pkgs[@]}" &
    local pid=$!
    spinner $pid "Installing required packages..."
    wait $pid || { log WARN "Failed to install some packages. Continuing..."; }
  fi

  # Refresh systemd units
  log INFO "Reloading systemd daemon to ensure unit files are available..."
  sudo systemctl daemon-reload

  # Enable and start system-wide services
  log INFO "Enabling system services..."
  local services=("NetworkManager" "bluetooth" "power-profiles-daemon")
  for svc in "${services[@]}"; do
    local svc_name="${svc}.service"
    if systemctl cat "$svc_name" &>/dev/null; then
      log INFO "Found $svc_name, checking status..."

      # Enable if not enabled
      if ! systemctl is-enabled "$svc_name" &>/dev/null; then
        log INFO "Enabling $svc_name..."
        sudo systemctl enable "$svc_name" &
        local pid=$!
        spinner $pid "Enabling $svc_name..."
        wait $pid || { log WARN "Failed to enable $svc_name. Continuing..."; }
      else
        log INFO "$svc_name is already enabled."
      fi

      # Start if not active
      if ! systemctl is-active "$svc_name" &>/dev/null; then
        log INFO "Starting $svc_name..."
        sudo systemctl start "$svc_name" &
        local pid=$!
        spinner $pid "Starting $svc_name..."
        wait $pid || { log WARN "Failed to start $svc_name. Continuing..."; }
      else
        log INFO "$svc_name is already active."
      fi
    else
      log WARN "$svc_name not found. Attempting to reinstall corresponding package..."
      local pkg_name
      case "$svc" in
        NetworkManager) pkg_name="networkmanager" ;;
        bluetooth) pkg_name="bluez" ;;
        power-profiles-daemon) pkg_name="power-profiles-daemon" ;;
      esac
      sudo pacman -S --needed --noconfirm --overwrite '*' "$pkg_name" &
      local pid=$!
      spinner $pid "Reinstalling $pkg_name..."
      if wait $pid; then
        sudo systemctl daemon-reload
        if systemctl cat "$svc_name" &>/dev/null; then
          log INFO "Reinstallation successful, checking status for $svc_name..."

          # Enable if not enabled
          if ! systemctl is-enabled "$svc_name" &>/dev/null; then
            log INFO "Enabling $svc_name..."
            sudo systemctl enable "$svc_name" &
            local pid=$!
            spinner $pid "Enabling $svc_name..."
            wait $pid || { log WARN "Failed to enable $svc_name after reinstall. Continuing..."; }
          else
            log INFO "$svc_name is already enabled."
          fi

          # Start if not active
          if ! systemctl is-active "$svc_name" &>/dev/null; then
            log INFO "Starting $svc_name..."
            sudo systemctl start "$svc_name" &
            local pid=$!
            spinner $pid "Starting $svc_name..."
            wait $pid || { log WARN "Failed to start $svc_name after reinstall. Continuing..."; }
          else
            log INFO "$svc_name is already active."
          fi
        else
          log WARN "$svc_name still not found after reinstall."
        fi
      else
        log WARN "Failed to reinstall $pkg_name."
      fi
    fi
  done

  # Disable iwd if installed and active
  local iwd_svc="iwd.service"
  if systemctl cat "$iwd_svc" &>/dev/null; then
    log INFO "Disabling iwd service..."
    sudo systemctl disable --now "$iwd_svc" &
    local pid=$!
    spinner $pid "Disabling iwd..."
    wait $pid || { log WARN "Failed to disable iwd service."; }
  else
    log INFO "iwd service not found, skipping."
  fi

  log SUCCESS "Service configuration completed!"
}

update_grub() {
  log INFO "Starting GRUB update for dual-boot configuration..."

  # Check and install os-prober if not present (required for detecting other OS)
  if ! command -v os-prober &>/dev/null; then
    log INFO "Installing os-prober for OS detection..."
    sudo pacman -S --needed --noconfirm os-prober &
    local pid=$!
    spinner $pid "Installing os-prober..."
    wait $pid || { log WARN "Failed to install os-prober. OS detection may not work."; }
  fi

  # Install GRUB to EFI firmware
  log INFO "Installing GRUB to EFI firmware..."
  sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB &
  local pid=$!
  spinner $pid "Installing GRUB..."
  if wait $pid; then
    log INFO "GRUB installed successfully."
  else
    log WARN "Failed to install GRUB."
  fi

  # Ensure GRUB_DISABLE_OS_PROBER=false for dual-boot
  log INFO "Configuring GRUB_DISABLE_OS_PROBER=false..."
  local grub_default="/etc/default/grub"
  if [ -f "$grub_default" ]; then
    if grep -q "^GRUB_DISABLE_OS_PROBER=" "$grub_default"; then
      sudo sed -i 's/^GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' "$grub_default" || log WARN "Failed to update GRUB_DISABLE_OS_PROBER."
    elif grep -q "^#GRUB_DISABLE_OS_PROBER=" "$grub_default"; then
      sudo sed -i 's/^#GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' "$grub_default" || log WARN "Failed to update GRUB_DISABLE_OS_PROBER."
    else
      echo "GRUB_DISABLE_OS_PROBER=false" | sudo tee -a "$grub_default" >/dev/null || log WARN "Failed to add GRUB_DISABLE_OS_PROBER."
    fi
  else
    log WARN "/etc/default/grub not found. Creating..."
    sudo mkdir -p /etc/default
    echo "GRUB_DISABLE_OS_PROBER=false" | sudo tee "$grub_default" >/dev/null || log WARN "Failed to create /etc/default/grub."
  fi

  # Generate GRUB configuration
  log INFO "Generating GRUB configuration..."
  sudo grub-mkconfig -o /boot/grub/grub.cfg &
  local pid=$!
  spinner $pid "Generating GRUB config..."
  if wait $pid; then
    if grep -qi "Windows" /boot/grub/grub.cfg; then
      log SUCCESS "GRUB updated successfully with Windows entry!"
    else
      log WARN "GRUB updated but no Windows entry found. Ensure Windows is installed and detectable."
    fi
  else
    log WARN "Failed to generate GRUB configuration."
  fi
}