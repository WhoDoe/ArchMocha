keep_sudo_alive() {
  # Check if not root, request sudo privileges, and keep them alive
  if [[ $EUID -ne 0 ]]; then
    log INFO "Requesting sudo privileges..."
    if ! sudo -v; then
      log ERROR "Failed to obtain sudo privileges. Please ensure you have sudo access."
      exit 1
    fi
    (
      while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
      done
    ) & disown
    SUDO_KEEPALIVE_PID=$!
    trap "kill $SUDO_KEEPALIVE_PID 2>/dev/null" EXIT
  fi
}