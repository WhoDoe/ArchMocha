#!/bin/bash

check_network() {
  # Check network connectivity by pinging public DNS servers
  # Use a more robust check with multiple attempts and fallback
  local attempts=3
  local success=false

  for ((i=1; i<=attempts; i++)); do
    if ping -c1 -W2 8.8.8.8 &>/dev/null || ping -c1 -W2 1.1.1.1 &>/dev/null; then
      success=true
      break
    fi
    log WARN "Network check attempt $i/$attempts failed. Retrying..."
    sleep 2
  done

  $success
}

configure_network() {
  # Log warning if no network
  log WARN "No network connection detected. Network configuration is required to continue."

  # Check for available network tools and configure accordingly
  if command -v nmtui &>/dev/null && [ -n "$DISPLAY" ]; then
    # Log info and open nmtui for user to connect (requires graphical session)
    log INFO "Detected graphical session. Opening nmtui... Please connect to a WiFi network and exit to continue."
    sudo -E -u "$USER_NAME" nmtui  # Preserve environment variables with -E
  elif command -v nmcli &>/dev/null; then
    # Log info and use nmcli to list networks and guide user
    log INFO "Using nmcli for network configuration."
    log INFO "Available WiFi networks:"
    nmcli device wifi list
    log INFO "To connect, run: sudo nmcli device wifi connect <SSID> password <PASSWORD>"
    log INFO "After connecting, press Enter to continue."
    read -r -p "Press Enter when done..."
  elif command -v iwctl &>/dev/null; then
    # Enable and start iwd if not already running
    if ! systemctl is-active --quiet iwd; then
      log INFO "Enabling and starting iwd service..."
      sudo systemctl enable --now iwd
      sleep 3  # Increased sleep for service startup
    fi
    # Log info and open iwctl for user to connect
    log INFO "Opening iwctl... Use these commands:"
    log INFO "  device list"
    log INFO "  station wlan0 scan"
    log INFO "  station wlan0 get-networks"
    log INFO "  station wlan0 connect <SSID>"
    log INFO "Exit iwctl when connected."
    sudo -u "$USER_NAME" iwctl
  else
    # Log error if no network tools found
    log ERROR "No supported network configuration tools found (nmtui, nmcli, or iwctl)."
    log ERROR "Please install NetworkManager or iwd manually and rerun the script."
    exit 2
  fi

  # Log info for rechecking network after configuration
  log INFO "Rechecking network connection after configuration..."

  if ! check_network; then
    log ERROR "Network configuration failed. Still no connection detected. Exiting script."
    exit 2
  fi

  log SUCCESS "Network configuration successful."
}