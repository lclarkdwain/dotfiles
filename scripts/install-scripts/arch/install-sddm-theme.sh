#!/bin/bash

source_theme="https://github.com/JaKooLit/simple-sddm-2.git"
theme_name="simple_sddm_2"

source_dir=$(dirname "$(realpath "$0")")
if ! source "${source_dir}/global_fn.sh"; then
  echo "Error: unable to source global_fn.sh..."
  exit 1
fi

# SDDM-themes
printf "${INFO} Installing ${SKY_BLUE}Additional SDDM Theme${RESET}\n"

# Check if /usr/share/sddm/themes/$theme_name exists and remove if it does
if [ -d "/usr/share/sddm/themes/$theme_name" ]; then
  sudo rm -rf "/usr/share/sddm/themes/$theme_name"
  echo -e "\e[1A\e[K${OK} - Removed existing $theme_name directory." 2>&1 | log PIPE
fi

# Check if $theme_name directory exists in the current directory and remove if it does
if [ -d "$theme_name" ]; then
  rm -rf "$theme_name"
  echo -e "\e[1A\e[K${OK} - Removed existing $theme_name directory from the current location." 2>&1 | log PIPE
fi

# Clone the repository
if git clone --depth=1 "$source_theme" "$theme_name"; then
  if [ ! -d "$theme_name" ]; then
    echo "${ERROR} Failed to clone the repository." | log PIPE
  fi

  # Create themes directory if it doesn't exist
  if [ ! -d "/usr/share/sddm/themes" ]; then
    sudo mkdir -p /usr/share/sddm/themes
    echo "${OK} - Directory '/usr/share/sddm/themes' created." | log PIPE
  fi

  # Move cloned theme to the themes directory
  sudo mv "$theme_name" "/usr/share/sddm/themes/$theme_name" 2>&1 | log PIPE

  # setting up SDDM theme
  sddm_conf="/etc/sddm.conf"
  BACKUP_SUFFIX=".bak"

  echo -e "${NOTE} Setting up the login screen." | log PIPE

  # Backup the sddm.conf file if it exists
  if [ -f "$sddm_conf" ]; then
    echo "Backing up $sddm_conf" | log PIPE
    sudo cp "$sddm_conf" "$sddm_conf$BACKUP_SUFFIX" 2>&1 | log PIPE
  else
    echo "$sddm_conf does not exist, creating a new one." | log PIPE
    sudo touch "$sddm_conf" 2>&1 | log PIPE
  fi

  # Check if the [Theme] section exists
  if grep -q '^\[Theme\]' "$sddm_conf"; then
    # Update the Current= line under [Theme]
    sudo sed -i "/^\[Theme\]/,/^\[/{s/^\s*Current=.*/Current=$theme_name/}" "$sddm_conf" 2>&1 | log PIPE

    # If no Current= line was found and replaced, append it after the [Theme] section
    if ! grep -q '^\s*Current=' "$sddm_conf"; then
      sudo sed -i "/^\[Theme\]/a Current=$theme_name" "$sddm_conf" 2>&1 | log PIPE
      echo "Appended Current=$theme_name under [Theme] in $sddm_conf" | log PIPE
    else
      echo "Updated Current=$theme_name in $sddm_conf" | log PIPE
    fi
  else
    # Append the [Theme] section at the end if it doesn't exist
    echo -e "\n[Theme]\nCurrent=$theme_name" | sudo tee -a "$sddm_conf" >/dev/null
    echo "Added [Theme] section with Current=$theme_name in $sddm_conf" | log PIPE
  fi

  # Add [General] section with InputMethod=qtvirtualkeyboard if it doesn't exist
  if ! grep -q '^\[General\]' "$sddm_conf"; then
    echo -e "\n[General]\nInputMethod=qtvirtualkeyboard" | sudo tee -a "$sddm_conf" >/dev/null
    echo "Added [General] section with InputMethod=qtvirtualkeyboard in $sddm_conf" | log PIPE
  else
    # Update InputMethod line if section exists
    if grep -q '^\s*InputMethod=' "$sddm_conf"; then
      sudo sed -i '/^\[General\]/,/^\[/{s/^\s*InputMethod=.*/InputMethod=qtvirtualkeyboard/}' "$sddm_conf" 2>&1 | log PIPE
      echo "Updated InputMethod to qtvirtualkeyboard in $sddm_conf" | log PIPE
    else
      sudo sed -i '/^\[General\]/a InputMethod=qtvirtualkeyboard' "$sddm_conf" 2>&1 | log PIPE
      echo "Appended InputMethod=qtvirtualkeyboard under [General] in $sddm_conf" | log PIPE
    fi
  fi

  # Replace current background from assets
  sudo cp -r assets/sddm.png "/usr/share/sddm/themes/$theme_name/Backgrounds/default" 2>&1 | log PIPE
  sudo sed -i 's|^wallpaper=".*"|wallpaper="Backgrounds/default"|' "/usr/share/sddm/themes/$theme_name/theme.conf" 2>&1 | log PIPE

  echo "${OK} - ${MAGENTA}Additional ${YELLOW}$theme_name SDDM Theme${RESET} successfully installed." | log PIPE

else

  echo "${ERROR} - Failed to clone the sddm theme repository. Please check your internet connection." | log PIPE >&2
fi

printf "\n%.0s" {1..2}
