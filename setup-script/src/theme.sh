#!/bin/bash

apply_theme() {
  # Log start of theme application
  log INFO "Applying Catppuccin theme..."

  # Create necessary directories if they don't exist
  mkdir -p "$HYPR_CONF_DIR" "$USER_HOME/.config/gtk-3.0" "$USER_HOME/.config/gtk-4.0"
  chown -R "$USER_NAME:$USER_NAME" "$HYPR_CONF_DIR" "$USER_HOME/.config/gtk-3.0" "$USER_HOME/.config/gtk-4.0"

  # Handle GTK settings file: backup if exists and create new
  if [ -f "$GTK_SETTINGS_FILE" ]; then
    log WARN "File $GTK_SETTINGS_FILE already exists, backing up..."
    mv "$GTK_SETTINGS_FILE" "$GTK_SETTINGS_FILE.bak.$(date +%Y%m%d%H%M%S)"
  fi

  # Create settings.ini for GTK
  cat <<EOF > "$GTK_SETTINGS_FILE"
[Settings]
gtk-theme-name=$GTK_THEME_NAME
gtk-icon-theme-name=$ICON_THEME_NAME
gtk-cursor-theme-name=$CURSOR_THEME_NAME
gtk-cursor-theme-size=$CURSOR_SIZE
gtk-font-name=JetBrainsMono Nerd Font 10
EOF
  chown "$USER_NAME:$USER_NAME" "$GTK_SETTINGS_FILE"

  # Create symlink for GTK4
  ln -sf "$GTK_SETTINGS_FILE" "$USER_HOME/.config/gtk-4.0/settings.ini"
  chown -h "$USER_NAME:$USER_NAME" "$USER_HOME/.config/gtk-4.0/settings.ini"

  # Add environment variables for cursor to .profile if not already present
  local profile_file="$USER_HOME/.profile"
  if ! grep -q "export XCURSOR_THEME=$CURSOR_THEME_NAME" "$profile_file"; then
    echo "export XCURSOR_THEME=$CURSOR_THEME_NAME" >> "$profile_file"
  fi
  if ! grep -q "export XCURSOR_SIZE=$CURSOR_SIZE" "$profile_file"; then
    echo "export XCURSOR_SIZE=$CURSOR_SIZE" >> "$profile_file"
  fi
  chown "$USER_NAME:$USER_NAME" "$profile_file"

  # Prepare temporary directory for Catppuccin using mktemp for safety
  local catppuccin_dir
  catppuccin_dir=$(mktemp -d /tmp/catppuccin-hyprland.XXXXXX) || { log ERROR "Failed to create temporary directory for Catppuccin!"; return 1; }
  trap "rm -rf '$catppuccin_dir'" RETURN  # Ensure cleanup on function return

  # Clone Catppuccin repo for Hyprland as the user
  sudo -u "$USER_NAME" git clone "$CATPPUCCIN_HYPRLAND_REPO" "$catppuccin_dir" &
  local pid=$!
  spinner $pid "Cloning Catppuccin Hyprland repository..."
  wait $pid || { log ERROR "Failed to clone Catppuccin Hyprland repository!"; return 1; }

  # Copy mocha.conf theme file
  local hypr_theme_file="$HYPR_CONF_DIR/mocha.conf"
  cp "$catppuccin_dir/themes/mocha.conf" "$hypr_theme_file" || { log ERROR "Failed to copy mocha.conf!"; return 1; }
  chown "$USER_NAME:$USER_NAME" "$hypr_theme_file"

  # Handle hyprland.conf: add source if not present
  local hypr_conf_file="$HYPR_CONF_DIR/hyprland.conf"
  if [ ! -f "$hypr_conf_file" ]; then
    echo "# Basic Hyprland config" > "$hypr_conf_file"
    echo "source = $hypr_theme_file" >> "$hypr_conf_file"
  else
    if ! grep -q "^source = $hypr_theme_file" "$hypr_conf_file"; then
      sed -i "1i source = $hypr_theme_file" "$hypr_conf_file"
    fi
  fi
  chown "$USER_NAME:$USER_NAME" "$hypr_conf_file"

  # Guidance for Qt apps
  log INFO "To apply theme for Qt apps, run 'qt5ct' and select Catppuccin/Kvantum theme."

  # Apply gsettings if available (for GNOME compatibility in Hyprland)
  if command -v gsettings &>/dev/null; then
    local hypr_pid
    hypr_pid=$(pgrep -u "$USER_NAME" -x Hyprland || true)
    if [ -n "$hypr_pid" ]; then
      local dbus_address
      dbus_address=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/"$hypr_pid"/environ | tr '\0' '\n' | cut -d= -f2-)
      export DBUS_SESSION_BUS_ADDRESS="$dbus_address"
      log INFO "Detected DBus session for gsettings."

      sudo -u "$USER_NAME" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME_NAME" || log WARN "Failed to set gsettings gtk-theme (DBus issue?)."
      sudo -u "$USER_NAME" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME_NAME" || log WARN "Failed to set gsettings icon-theme (DBus issue?)."
      sudo -u "$USER_NAME" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME_NAME" || log WARN "Failed to set gsettings cursor-theme (DBus issue?)."
      sudo -u "$USER_NAME" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE" || log WARN "Failed to set gsettings cursor-size (DBus issue?)."
    else
      log WARN "No Hyprland session detected; skipping gsettings (apply manually after login)."
    fi
  else
    log WARN "gsettings not available; skipping GNOME compatibility settings."
  fi

  # Log success
  log SUCCESS "Theme applied successfully! Restart Hyprland to fully apply (hyprctl reload)."
  return 0
}

auto_set_grub_theme() {
  # Log the start of the theme setup process
  log INFO "Starting auto setup for GRUB Vimix theme..."
  # Check if git is installed; install if missing
  if ! command -v git &>/dev/null; then
    # Log git installation start
    log INFO "Installing git..."
    # Run pacman to install git non-interactively
    sudo pacman -Syu --noconfirm git &
    # Capture PID for spinner
    pid=$!
    # Show spinner during installation
    spinner $pid "Installing git..."
    # Wait for process and handle failure
    wait $pid || { log ERROR "Failed to install git!"; return 1; }
  fi
  # Create a temporary directory as user for cloning
  local theme_dir=$(sudo -u "$USER_NAME" mktemp -d /tmp/grub2-themes.XXXXXX) || { log ERROR "Failed to create temp dir!"; return 1; }
  # Set trap to clean up temp dir on return
  trap "rm -rf '$theme_dir'" RETURN
  # Log cloning process
  log INFO "Cloning GRUB Vimix theme repository..."
  # Clone the repo as user
  sudo -u "$USER_NAME" git clone https://github.com/vinceliuice/grub2-themes.git "$theme_dir" &
  # Capture PID
  pid=$!
  # Spinner for cloning
  spinner $pid "Cloning theme repository..."
  # Wait and handle clone failure
  wait $pid || { log ERROR "Failed to clone!"; return 1; }
  # Change to the cloned directory
  pushd "$theme_dir" >/dev/null || { log ERROR "Failed to cd!"; return 1; }
  # Log theme installation
  log INFO "Installing Vimix theme..."
  # Run install script with sudo for Vimix theme, color icons, 1080p resolution
  sudo ./install.sh -t vimix -i color -s 1080p &
  # Capture PID
  pid=$!
  # Spinner for installation
  spinner $pid "Installing Vimix theme..."
  # Wait and handle install failure, pop directory on error
  wait $pid || { log ERROR "Failed to install!"; popd >/dev/null; return 1; }
  # Return to previous directory
  popd >/dev/null
  # Log success
  log SUCCESS "GRUB Vimix theme installed! Reboot to apply."
  return 0
}

auto_rice_ly() {
  log INFO "Starting auto rice for Ly (cyberpunk mocha style)..."

  # Check and install git if not present
  if ! command -v git &>/dev/null; then
    log INFO "Installing git..."
    sudo pacman -Syu --noconfirm git &
    local pid=$!
    spinner $pid "Installing git..."
    wait $pid || { log ERROR "Failed to install git!"; return 1; }
  fi

  # Check and install Ly if not present
  if ! pacman -Qi ly &>/dev/null; then
    log INFO "Installing Ly..."
    sudo pacman -S --noconfirm ly &
    local pid=$!
    spinner $pid "Installing Ly..."
    wait $pid || { log ERROR "Failed to install Ly!"; return 1; }
  else
    log INFO "Ly is already installed."
  fi

  # Check for other enabled DMs
  local current_dm
  current_dm=$(systemctl list-unit-files --type=service | grep -E 'sddm|lightdm|gdm|ly' | grep enabled | awk '{print $1}' | grep -v '^ly\.service$') || true

  if [[ -n "$current_dm" ]]; then
    log WARN "Other DM(s) enabled: $current_dm. Disable manually if needed: sudo systemctl disable $current_dm"
    read -r -p "Continue with Ly setup? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
      log INFO "Aborting Ly setup as per user choice."
      return 1
    fi
  fi

  # Configure services
  log INFO "Configuring services..."

  # Disable getty@tty2.service if enabled
  if systemctl is-enabled getty@tty2.service &>/dev/null; then
    sudo systemctl disable --now getty@tty2.service &
    local pid=$!
    spinner $pid "Disabling getty@tty2.service..."
    wait $pid || { log ERROR "Failed to disable getty@tty2.service!"; return 1; }
  else
    log INFO "getty@tty2.service is already disabled."
  fi

  # Enable ly.service if not enabled
  if ! systemctl is-enabled ly.service &>/dev/null; then
    sudo systemctl enable --now ly.service &
    local pid=$!
    spinner $pid "Enabling ly.service..."
    wait $pid || { log ERROR "Failed to enable ly.service!"; return 1; }
  else
    log INFO "ly.service is already enabled."
  fi

  # Rice config.ini
  local config_file="/etc/ly/config.ini"
  if [[ -f "$config_file" ]]; then
    local backup_file="${config_file}.bak.$(date +%Y%m%d%H%M%S)"
    sudo cp "$config_file" "$backup_file" || { log ERROR "Failed to backup Ly config!"; return 1; }
    log INFO "Backup of config created at $backup_file"
  fi

  log INFO "Ricing Ly config (cyberpunk mocha)..."
  sudo bash -c "cat > $config_file" << EOL
# path to a file used to add setup instructions in the help screen
addsetup =
# animation played on invalid input
animation = matrix
# whether to play the animation while typing the password too
animonpass = true
# format string for clock in top right corner (see strftime specification)
clock = %Y-%m-%d %H:%M:%S
# enable/disable big clock
bigclock = true
# The character used to mask the password
asterisk = *
# Erase password input on failure
blank_password = true
# The \`fg\` and \`bg\` color settings take a digit 0-8 corresponding to:
# define TB_DEFAULT 0x00
# define TB_BLACK 0x01
# define TB_RED 0x02
# define TB_GREEN 0x03
# define TB_YELLOW 0x04
# define TB_BLUE 0x05
# define TB_MAGENTA 0x06
# define TB_CYAN 0x07
# define TB_WHITE 0x08
# Background color id
bg = 1
# Foreground color id
fg = 7
# Blank main box background
# Setting to false will make it transparent
blank_box = true
# Remove main box borders
hide_borders = false
# Main box margins
margin_box_h = 8
margin_box_v = 4
# Input boxes length
input_len = 50
# Max input sizes
max_desktop_len = 100
max_login_len = 255
max_password_len = 255
# Remove F1/F2 command hints
hide_key_hints = true
# language to use during the session
lang =
# path to file containing the mcookie value
mcookie_cmd = mcookie
# command used to run the shell for Setup
setup = /bin/sh -l
# whether to run Setup on each TTY respawn
setup_always = false
# command used to spawn terminals in the same working directory
term_reset_cmd = tput reset
# tty Ly will start on
tty = 2
# vt in use by X or Wayland
vt = 4
# command used to run the user's .xinitrc and X server
x_cmd = /usr/bin/X -keeptty
# setup script to run before xsetup (as root, with \$DISPLAY set)
x_cmd_setup =
# wayland sessions directory
wayland_sessions_dir = /usr/share/wayland-sessions
# command used to run the wayland compositor
wayland_cmd = dbus-run-session -sh
# x sessions directory
x_sessions_dir = /usr/share/xsessions
# command used to generate the xauthority cookie
xauth_cmd = xauth add :0 . \`mcookie\`
# command used to setup the X server
xsetup =
EOL

  if [[ $? -ne 0 ]]; then
    log ERROR "Failed to write Ly config!"
    return 1
  fi

  log SUCCESS "Ly rice complete!"
  return 0
}