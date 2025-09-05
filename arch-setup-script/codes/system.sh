#!/bin/bash

# Function to install paru if it's not already installed
install_paru() {
    # Check if paru is not installed
    if ! command -v paru &>/dev/null; then
        # Log the start of the installation process
        log INFO "Installing paru..."
        
        # Install required dependencies (base-devel and git) with a full system upgrade
        sudo pacman -Syu --needed --noconfirm base-devel git || { log ERROR "Failed deps"; exit 1; }
        
        # Create a temporary directory as the specified user for building paru
        paru_dir=$(sudo -u "$USER_NAME" mktemp -d /tmp/paru.XXXXXX) || { log ERROR "Temp dir failed"; exit 1; }
        
        # Set a trap to clean up the temporary directory on script exit
        trap "rm -rf '$paru_dir'" EXIT
        
        # Clone the paru repository from AUR as the specified user
        sudo -u "$USER_NAME" git clone https://aur.archlinux.org/paru.git "$paru_dir" || { log ERROR "Clone failed"; exit 1; }
        
        # Change to the cloned directory
        pushd "$paru_dir" >/dev/null
        
        # Build and install paru using makepkg as the specified user
        sudo -u "$USER_NAME" HOME="$USER_HOME" makepkg -si --noconfirm || { log ERROR "Makepkg failed"; exit 1; }
        
        # Return to the previous directory
        popd >/dev/null
        
        # Verify that paru was installed successfully
        if ! command -v paru &>/dev/null; then log ERROR "Verification failed"; exit 1; fi
        
        # Log successful installation
        log SUCCESS "Paru installed!"
    else
        # Log if paru is already installed
        log INFO "Paru already installed."
    fi
}

# Function to update the system packages
update_system() {
    # Log the start of the system update
    log INFO "Updating system..."
    
    # Perform a full system upgrade non-interactively
    sudo pacman -Syu --noconfirm || { log ERROR "Update failed"; exit 1; }
    
    # Log successful update
    log SUCCESS "System updated!"
}