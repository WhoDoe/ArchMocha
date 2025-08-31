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
