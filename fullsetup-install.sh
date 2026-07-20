#!/usr/bin/env bash

# ==============================================================================
# full-setup.sh - Gigi's Arch Linux Full-Setup Installer
# curl -fsSL https://raw.githubusercontent.com/deadduck-09/gigis-rice/main/fullsetup-install.sh | bash
# ==============================================================================
# Focuses strictly on installing software, packages, services, and system prep.
# Executes the local styling layer via install.sh safely from its own directory.
# ==============================================================================

set -e # Exit immediately if a command exits with a non-zero status

# --- Detect Script Location ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Colors & Presentation ---
NC='\033[0m'
BOLD='\033[1m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'

LOG_FILE="$SCRIPT_DIR/full-setup.log"
echo "=== Gigi's Arch Setup Log Started $(date) ===" > "$LOG_FILE"

# --- Helper Functions ---
msg() {
    echo -e "${CYAN}${BOLD}::${NC} ${BOLD}$1${NC}"
    echo "INFO: $1" >> "$LOG_FILE"
}

success() {
    echo -e "${GREEN}${BOLD}✓${NC} ${GREEN}$1${NC}"
    echo "SUCCESS: $1" >> "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}${BOLD}⚠ WARNING:${NC} ${YELLOW}$1${NC}"
    echo "WARNING: $1" >> "$LOG_FILE"
}

error() {
    echo -e "${RED}${BOLD}✗ ERROR:${NC} ${RED}$1${NC}"
    echo "ERROR: $1" >> "$LOG_FILE" >&2
}

# --- Initial Banner & Safety Checks ---
clear
echo -e "${CYAN}${BOLD}"
echo "==================================================="
echo "          GIGI'S COMPLETE SETUP INSTALLER          "
echo "==================================================="
echo -e "${NC}"
echo "This installer will transform a minimal Arch Linux setup"
echo "into a fully configured, polished Niri-based workstation."
echo "No personal data, passwords, or browser profiles will be copied."
echo "----------------------------------------------------------"
echo "Logging output to: $LOG_FILE"
echo ""

# Prevent running as root directly
if [ "$EUID" -eq 0 ]; then
    error "Please do not run this script as root/sudo directly. Run it as a normal user."
    exit 1
fi

# Pre-execution backup warning
warning "This script will download your system baseline and call the styling script."
warning "Existing configuration directories in ~/.config may be overwritten or backed up by the rice script."
read -r -p "Do you want to proceed? (y/N): " confirm < /dev/tty
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    msg "Installation aborted by user."
    exit 0
fi

# Request sudo privileges early
msg "Elevating privileges for system tasks..."
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# --- Dependency Check ---
msg "Checking essential environment dependencies..."
for cmd in git curl fc-cache; do
    if ! command -v "$cmd" &> /dev/null; then
        msg "Installing missing system dependency: $cmd"
        sudo pacman -S --needed --noconfirm "$cmd" 2>&1 | sudo tee -a "$LOG_FILE" > /dev/null
    fi
done

# --- Arrays of Packages ---
PACMAN_PKGS=(
    # Desktop / Wayland / Display
    niri waybar mako fuzzel cliphist wl-clipboard swaybg swayidle swaylock 
    wlsunset xorg-xwayland xdg-desktop-portal xdg-desktop-portal-gtk xsettingsd sddm swaync plymouth
    # Shell Customization
    nwg-look qt5ct qt6ct matugen
    # Terminal Utilities
    fish starship kitty ghostty fastfetch btop htop fzf ripgrep tree ncdu jq 
    chafa gum git lazygit wget rsync unzip shellcheck
    # File Management
    yazi thunar thunar-volman nautilus tumbler ffmpegthumbnailer gvfs-mtp udisks2
    # Development
    neovim nodejs npm go rust clang cmake zed python-pip python-pipx python-virtualenv
    # Media
    mpv mpd mpc rmpc cava yt-dlp gpu-screen-recorder obs-studio
    # Content Creation
    audacity kdenlive gwenview spectacle
    # Productivity
    obsidian libreoffice-fresh kate
    # Virtualization
    gnome-boxes libvirt
    # Audio
    pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber 
    gst-plugin-pipewire gst-plugins-good gst-plugins-bad gst-plugins-ugly
    # Bluetooth & Network
    bluez bluez-utils networkmanager network-manager-applet
    # Themes & Fonts
    adw-gtk-theme papirus-icon-theme inter-font noto-fonts noto-fonts-cjk 
    noto-fonts-emoji ttf-dejavu ttf-liberation ttf-jetbrains-mono 
    ttf-jetbrains-mono-nerd woff2-font-awesome
    # System Utilities
    brightnessctl ddcutil power-profiles-daemon flatpak smartmontools 
    btrfs-progs ntfs-3g exfatprogs zram-generator xdg-user-dirs polkit polkit-gnome polkit-kde-agent
)

AUR_PKGS=(
    noctalia-shell helium-browser-bin zen-browser-bin vscodium-bin 
    bibata-cursor-theme-bin ttf-material-symbols-variable-git spicetify-cli 
    spotify mpvpaper ani-cli cbonsai pipes.sh pokego-bin peaclock
)

SYSTEM_SERVICES=(
    bluetooth.service
    NetworkManager.service
    sddm.service
    power-profiles-daemon.service
    udisks2.service
    libvirtd.service
)

USER_SERVICES=(
    mpd.service
    wireplumber.service
)

USER_SOCKETS=(
    pipewire.socket
    pipewire-pulse.socket
)

# --- Step 1: Core Pacman Packages ---
msg "Updating package databases and installing official packages..."
if sudo pacman -Syu --noconfirm --needed "${PACMAN_PKGS[@]}" 2>&1 | sudo tee -a "$LOG_FILE" > /dev/null; then
    success "Official Arch Linux packages installed successfully."
else
    error "Failed to install Pacman packages. Check $LOG_FILE for details."
    exit 1
fi

# --- Step 2: Handle AUR Helper ---
msg "Detecting AUR helper..."
AUR_HELPER=""
if command -v yay &> /dev/null; then
    AUR_HELPER="yay"
elif command -v paru &> /dev/null; then
    AUR_HELPER="paru"
else
    warning "Neither 'yay' nor 'paru' was found. Bootstrapping 'yay' automatically..."
    sudo pacman -S --needed --noconfirm base-devel 2>&1 | sudo tee -a "$LOG_FILE" > /dev/null
    
    BUILD_DIR=$(mktemp -d)
    git clone https://aur.archlinux.org/yay-bin.git "$BUILD_DIR/yay-bin" >> "$LOG_FILE" 2>&1
    cd "$BUILD_DIR/yay-bin"
    makepkg -si --noconfirm >> "$LOG_FILE" 2>&1
    cd - > /dev/null
    rm -rf "$BUILD_DIR"
    
    AUR_HELPER="yay"
fi
success "Using AUR helper: $AUR_HELPER"

# --- Step 3: Install AUR Packages ---
msg "Installing AUR packages via $AUR_HELPER..."
if $AUR_HELPER -S --noconfirm --needed "${AUR_PKGS[@]}" >> "$LOG_FILE" 2>&1; then
    success "AUR packages installed successfully."
else
    error "Failed to install some AUR packages. Check $LOG_FILE for details."
    exit 1
fi

# --- Step 4: Flatpak Apps ---
msg "Installing Flatpak ecosystem packages..."
if flatpak install --user -y flathub org.vinegarhq.Sober >> "$LOG_FILE" 2>&1; then
    success "Flatpak applications configured successfully."
else
    warning "Flatpak remote not loaded yet. Registering Flathub..."
    flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo >> "$LOG_FILE" 2>&1
    if flatpak install --user -y flathub org.vinegarhq.Sober >> "$LOG_FILE" 2>&1; then
        success "Flatpak applications configured successfully."
    else
        warning "Could not deploy 'Sober' flatpak dynamically. You may install it manually post-reboot."
    fi
fi

# --- Step 5: Font Cache Refresh ---
msg "Regenerating font cache libraries..."
if fc-cache -fv >> "$LOG_FILE" 2>&1; then
    success "Font cache rebuilt successfully."
else
    warning "Font cache rebuilding run reported warnings. Font states may lag until reload."
fi

# --- Step 6: System Configurations & Services ---
msg "Configuring virtualization group metrics..."
if getent group libvirt > /dev/null; then
    sudo usermod -aG libvirt "$USER" 2>&1 | sudo tee -a "$LOG_FILE" > /dev/null
    success "User added to libvirt group."
else
    warning "Group 'libvirt' not found. Creating and attaching user..."
    sudo groupadd -r libvirt 2>&1 | sudo tee -a "$LOG_FILE" > /dev/null || true
    sudo usermod -aG libvirt "$USER" 2>&1 | sudo tee -a "$LOG_FILE" > /dev/null
fi

msg "Enabling system-level services..."
for service in "${SYSTEM_SERVICES[@]}"; do
    msg "Enabling: $service"
    sudo systemctl enable "$service" 2>&1 | sudo tee -a "$LOG_FILE" > /dev/null
done

msg "Setting default target boot environment to graphical..."
sudo systemctl set-default graphical.target 2>&1 | sudo tee -a "$LOG_FILE" > /dev/null
success "System services and boot environmental states mapped."

# --- Step 7: User Services ---
msg "Enabling user-level services & sockets..."
systemctl --user daemon-reload >> "$LOG_FILE" 2>&1

for socket in "${USER_SOCKETS[@]}"; do
    systemctl --user enable "$socket" >> "$LOG_FILE" 2>&1
done

for service in "${USER_SERVICES[@]}"; do
    systemctl --user enable "$service" >> "$LOG_FILE" 2>&1
done

if command -v xdg-user-dirs-update &> /dev/null; then
    xdg-user-dirs-update >> "$LOG_FILE" 2>&1
fi
success "User level environmental services enabled."

# --- Step 8: Shell Setup ---
msg "Configuring login shell variables..."
if command -v fish &> /dev/null; then
    FISH_PATH=$(command -v fish)
    if [ "$SHELL" != "$FISH_PATH" ]; then
        msg "Setting Fish as default login shell..."
        if ! grep -q "$FISH_PATH" /etc/shells; then
            echo "$FISH_PATH" | sudo tee -a /etc/shells > /dev/null
        fi
        chsh -s "$FISH_PATH"
        success "Shell updated successfully. (Changes active upon next session initialization)"
    else
        success "Fish is already configured as your default shell."
    fi
else
    error "Fish shell executable was not resolved. Skipping configuration."
fi

# --- Step 9: Run Pre-existing Rice Installer (One-Liner Compatible) ---
msg "Package foundation ready. Fetching rice installer from repository..."
echo "----------------------------------------------------------"

# Dynamically download the repository into temporary memory to access install.sh
RICE_TMP=$(mktemp -d)
if git clone "https://github.com/deadduck-09/gigis-rice.git" "$RICE_TMP" >> "$LOG_FILE" 2>&1; then
    if [ -f "$RICE_TMP/install.sh" ]; then
        chmod +x "$RICE_TMP/install.sh"
        
        # Move into the temporary directory context so your rice installer paths work
        cd "$RICE_TMP"
        ./install.sh
        cd - > /dev/null
        
        # Clean up temporary files
        rm -rf "$RICE_TMP"
        success "Rice configuration layer executed successfully."
    else
        error "Could not find 'install.sh' in the fetched repository context."
        rm -rf "$RICE_TMP"
        exit 1
    fi
else
    error "Failed to clone repository during styling layer handoff."
    rm -rf "$RICE_TMP"
    exit 1
fi

# --- Wrap up ---
echo ""
echo "=========================================================="
echo -e "${GREEN}${BOLD}      GIGI'S WORKSTATION DEPLOYMENT IS COMPLETE!         ${NC}"
echo "=========================================================="
echo "All baseline application architectures and services are loaded."
echo -e "${YELLOW}A system reboot is required to activate the sddm interface and load Niri.${NC}"
echo "=========================================================="
echo ""
read -r -p "Would you like to reboot now? (y/N): " reboot_now < /dev/tty
if [[ "$reboot_now" =~ ^[Yy]$ ]]; then
    msg "Rebooting system..."
    sudo reboot
else
    msg "Exiting script. Please reboot manually whenever you are ready!"
fi
