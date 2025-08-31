#!/bin/bash

# Function to log messages with enhanced formatting using ASCII icons
log() {
  # Get level and message
  local level="$1"
  shift
  local msg="$@"

  # Skip logging if message is empty
  [[ -z "$msg" ]] && return

  # Create timestamp with milliseconds for precision (fallback if %3N not supported)
  local timestamp
  if date +"%Y-%m-%d %H:%M:%S.%3N" &>/dev/null; then
    timestamp=$(date +"%Y-%m-%d %H:%M:%S.%3N")
  else
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  fi

  # Select color and ASCII icon based on level
  local color icon
  case "$level" in
    INFO) color="\033[1;34m"; icon="[i] "; ;;
    WARN) color="\033[1;33m"; icon="[!] "; ;;
    ERROR) color="\033[1;31m"; icon="[x] "; ;;
    SUCCESS) color="\033[1;32m"; icon="[+] "; ;;
    DEBUG) color="\033[1;35m"; icon="[?] "; ;;
    *) color="\033[0m"; icon=" "; ;;
  esac

  # Print log with enhanced format: icon, timestamp, level, message
  echo -e "${color}${icon}[${timestamp}] [${level}] ${msg}\033[0m"

  # Special handling for ERROR: log to file and optional exit
  if [[ "$level" == "ERROR" ]]; then
    echo "[${timestamp}] [${level}] ${msg}" >> error.log # Append to error log file
    # Uncomment to exit on error: # exit 1
  fi
}

# Enhanced spinner with ASCII animation for better compatibility
spinner() {
  # Get PID of process to monitor and optional message
  local pid=$1
  local msg="${2:-Working...}"
  local delay=0.1 # Delay for animation
  local spinstr='|/-\' # Pure ASCII spinner sequence for maximum compatibility

  # Display spinner while process is running
  while kill -0 $pid 2>/dev/null; do
    local temp=${spinstr#?}
    printf "\r\033[1;36m%c\033[0m %s" "${spinstr:0:1}" "$msg"
    spinstr=$temp${spinstr%"${temp}"}
    sleep $delay
  done

  # Clear the spinner line after completion
  printf "\r\033[K"
}