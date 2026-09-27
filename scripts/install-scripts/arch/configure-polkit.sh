set -euo pipefail

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

if ! systemctl --user list-unit-files 2>/dev/null | grep -q '^hyprpolkitagent\.service'; then
  echo "${WARN} hyprpolkitagent.service not found in user units. Skipping polkit setup." | log PIPE
  exit 0
fi
# Skip if another polkit agent is already running
if pgrep -u "$UID" -f 'xfce-polkit|polkit-gnome-authentication-agent-1|polkit-kde-authentication-agent-1|hyprpolkitagent' >/dev/null 2>&1; then
  echo "${NOTE} Polkit agent already running. Skipping hyprpolkitagent setup." | log PIPE
  exit 0
fi

OVERRIDE_DIR="$HOME/.config/systemd/user/hyprpolkitagent.service.d"
OVERRIDE_FILE="$OVERRIDE_DIR/override.conf"

# Keep the tracked override
if [ -e "$OVERRIDE_FILE" ]; then
  echo "${NOTE} $OVERRIDE_FILE already exists. Keeping it." | log PIPE
else
  mkdir -p "$OVERRIDE_DIR"
  cat >"$OVERRIDE_FILE" <<'EOF'
[Unit]
After=
After=dbus.service
PartOf=

[Install]
WantedBy=default.target
EOF
fi

systemctl --user daemon-reload 2>&1 | log PIPE || true
systemctl --user enable hyprpolkitagent 2>&1 | log PIPE || true
systemctl --user start hyprpolkitagent 2>&1 | log PIPE || true

echo "${OK} hyprpolkitagent override configured and service started." | log PIPE
