#!/bin/bash

# Function to automatically copy/override config folders from repo root to ~/.config/
# Excludes 'setup-script' and non-folder items like LICENSE and README
autoconfig() {
    # Log start (assuming logging.sh is sourced elsewhere)
    log INFO "Starting auto-configuration: overriding config folders in ~/.config/"

    # Get the repository root directory (assuming script is run from repo root or setup-script)
    local repo_root="$(dirname "$(dirname "$(realpath "$0")")")"  # Adjusts for src/ location

    # Ensure ~/.config exists
    mkdir -p ~/.config || { log ERROR "Failed to create ~/.config directory!"; return 1; }

    # Loop through all folders in repo root, excluding setup-script
    for folder in "$repo_root"/*/; do
        local folder_name=$(basename "$folder")
        if [[ "$folder_name" != "setup-script" ]]; then
            # Copy recursively, overriding existing files
            cp -r "$folder" ~/.config/ || { log ERROR "Failed to copy $folder_name to ~/.config/!"; return 1; }
            log SUCCESS "Overrode ~/.config/$folder_name with repo contents."
        fi
    done

    # Log completion
    log SUCCESS "Auto-configuration completed!"
}