#!/bin/bash
# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Arch Hyprland Enhanced Auto Setup         ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Exit on errors, undefined variables, or pipe failures
set -euo pipefail

# Define script directory and source required files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

declare -a REQUIRED_FILES=(
  "src/init.sh"
  "logging.sh"
  "utils.sh"
  "network.sh"
  "install.sh"
  "theme.sh"
  "services.sh"
  "extras.sh"
  "pkgs.sh"
  "autoconfig.sh"
)

# Source all required files with error checking
for file in "${REQUIRED_FILES[@]}"; do
  if [[ -f "$SCRIPT_DIR/$file" ]]; then
    source "$SCRIPT_DIR/$file"
  else
    echo -e "\033[1;31mERROR: Required file $file not found in $SCRIPT_DIR!\033[0m"
    exit 3
  fi
done

# Check if running on Arch Linux
if ! grep -q '^ID=arch' /etc/os-release; then
  echo -e "\033[1;31mERROR: This script is designed for Arch Linux only.\033[0m"
  exit 4
fi

# Check if running as root
if [[ $EUID -eq 0 ]]; then
  echo -e "\033[1;31mERROR: Do not run this script as root. Use a regular user with sudo privileges.\033[0m"
  exit 5
fi

main() {
  # Clear screen and display header
  clear
  if command -v figlet &>/dev/null; then
    echo -e "\033[1;35m"
    figlet "Hyprland Setup"
    echo -e "\033[0m"
  else
    echo "Arch Hyprland Enhanced Auto Setup"
  fi

  log INFO "Starting Hyprland setup script..."

  # Ensure sudo privileges are maintained
  keep_sudo_alive

  # Check and configure network
  if ! check_network; then
    log WARN "No internet connection detected. Attempting to configure network..."
    configure_network
    if ! check_network; then
      log ERROR "Failed to establish network connection. Exiting."
      exit 2
    fi
    log SUCCESS "Network connection established."
  fi

  # Update system before installation
  log INFO "Updating system..."
  update_system

  # Install paru if not present
  if ! command -v paru &>/dev/null; then
    log INFO "Installing paru AUR helper..."
    install_paru
  fi

  # Check and install missing packages
  log INFO "Checking for missing packages..."
  declare -a MISSING_PKGS=()
  for pkg in "${PKGS[@]}"; do
    # Clean package name (remove whitespace and carriage returns)
    pkg=$(echo "$pkg" | sed 's/[[:space:]]\+//g' | tr -d '\r')
    if [[ -n "$pkg" ]] && ! paru -Qi "$pkg" &>/dev/null; then
      MISSING_PKGS+=("$pkg")
    fi
  done

  if [[ ${#MISSING_PKGS[@]} -gt 0 ]]; then
    log INFO "Installing ${#MISSING_PKGS[@]} missing packages: ${MISSING_PKGS[*]}"
    if ! paru -S --needed --noconfirm "${MISSING_PKGS[@]}"; then
      log ERROR "Package installation failed!"
      exit 1
    fi
    log SUCCESS "All packages installed successfully."
  else
    log SUCCESS "All required packages are already installed."
  fi

  # Update GRUB configuration
  update_grub

  # Apply theme
  apply_theme
  auto_set_grub_theme
  auto_rice_ly

  # Install additional extras (e.g., momoisay)
  install_momoisay

  # Enable required services
  enable_services

  # Auto override config folder
  autoconfig

  log SUCCESS "Hyprland setup completed successfully! Please reboot and start Hyprland."
}

# Trap Ctrl+C and other signals for graceful exit
trap 'log ERROR "Script interrupted by user."; exit 1' SIGINT SIGTERM

# Execute main function with any passed arguments
main "$@"