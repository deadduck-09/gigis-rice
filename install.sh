#!/usr/bin/env bash

# ==============================================================================
# Gigi's Rice Installer - Professional Production Grade Deployment Engine
# Target Environment: Arch Linux (Niri + Noctalia Base Ecosystem)
# Reference URL: https://github.com/deadduck-09/gigis-rice
# ==============================================================================

# Strict Execution Guard: Exit on errors, unset variables, and pipeline faults
set -euo pipefail
IFS=$'\n\t'

# --- Runtime Execution Performance Benchmarking ---
START_TIME=$(date +%s)
readonly START_TIME

# --- Immutable Global System Constants ---
readonly VERSION="3.0.0"
readonly AUTHOR="Gigi"
# readonly REPO_URL="https://github.com/deadduck-09/gigis-rice"
readonly LOG_DIR="$HOME/.cache/gigis-rice"
readonly LOG_FILE="$LOG_DIR/install.log"
TIMESTAMP=$(date +%Y-%m-%d-%H%M%S)
readonly TIMESTAMP
readonly BACKUP_DIR="$HOME/.config-backup-$TIMESTAMP"

# --- UI Color Space Definitions (ANSI Escape Matrix) ---
readonly NC='\033[0m'
readonly BOLD='\033[1m'
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'

# --- Component Profile Ordering Matrix ---
# Defines the precise sequential installation execution order.
readonly PREFERRED_ORDER=(
    "niri"
    "noctalia"
    "kitty"
    "waybar"
    "mpd"
    "mpv"
    "fastfetch"
    "yazi"
    "rmpc"
)

# --- Component Configuration Specification Maps ---
# Decouples config directories from binary commands and package names.
declare -A BINARY_MAP=(
    ["nvim"]="nvim"
    ["kitty"]="kitty"
    ["waybar"]="waybar"
    ["fastfetch"]="fastfetch"
    ["mpv"]="mpv"
    ["mpd"]="mpd"
    ["niri"]="niri"
    ["noctalia"]="noctalia"
    ["rmpc"]="rmpc"
    ["yazi"]="yazi"
)

declare -A PACKAGE_MAP=(
    ["nvim"]="neovim"
    ["kitty"]="kitty"
    ["waybar"]="waybar"
    ["fastfetch"]="fastfetch"
    ["mpv"]="mpv"
    ["mpd"]="mpd"
    ["niri"]="niri"
    ["noctalia"]="noctalia-git"
    ["rmpc"]="rmpc"
    ["yazi"]="yazi"
)

# --- Runtime Analytical State Trackers ---
CURRENT_STEP=0
TOTAL_STEPS=8  # Dynamically incremented or decremented based on runtime operational mode

INSTALLED_CONFIGS=()
SKIPPED_CONFIGS=()
FAILED_CONFIGS=()
INSTALLED_PACKAGES=()
ALREADY_PRESENT_PACKAGES=()
FAILED_PACKAGES=()

DRY_RUN=false
HAS_INTERNET=true

# ==============================================================================
# 1. System Logging & Signal Processing Infrastructure
# ==============================================================================

# Ensure the log ecosystem exists immediately
mkdir -p "$LOG_DIR"
echo "=== GIGI'S RICE INITIALIZATION AUDIT RUNNING AT $(date) ===" > "$LOG_FILE"

log_to_file() {
    local level="$1"
    local msg="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $msg" >> "$LOG_FILE"
}

cleanup_handler() {
    local exit_code=$?
    if [ "$exit_code" -ne 0 ]; then
        echo -e "\n\n${RED}${BOLD}❌ Script terminated unexpectedly. Detailed diagnostics written to: $LOG_FILE${NC}"
        log_to_file "FATAL" "Execution process halted via shell trap error boundary."
    fi
    exit "$exit_code"
}
trap cleanup_handler EXIT
trap 'exit 130' SIGINT SIGTERM

# ==============================================================================
# 2. Advanced Terminal UI Engine
# ==============================================================================

print_banner() {
    clear
    echo -e "${PURPLE}╔═════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                                                                 ║${NC}"
    echo -e "${PURPLE}║                 ${GREEN}🌿 Gigi's Rice Installer 🌿${PURPLE}                     ║${NC}"
    echo -e "${PURPLE}║                                                                 ║${NC}"
    echo -e "${PURPLE}║                  ${CYAN}Niri + Noctalia Configuration${PURPLE}                  ║${NC}"
    echo -e "${PURPLE}║                                                                 ║${NC}"
    echo -e "${PURPLE}╚═════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "  ${BOLD}Version:${NC} ${YELLOW}$VERSION${NC} | ${BOLD}Author:${NC} ${YELLOW}$AUTHOR${NC} | ${BOLD}Log:${NC} ${BLUE}$LOG_FILE${NC}"
    echo -e "───────────────────────────────────────────────────────────────────\n"
}

render_progress() {
    local percent=$1
    local width=30
    local filled=$(( percent * width / 100 ))
    local empty=$(( width - filled ))
    
    printf "  Progress: ["
    if [ "$filled" -gt 0 ]; then
        printf "%${filled}s" "" | tr ' ' '█'
    fi
    if [ "$empty" -gt 0 ]; then
        printf "%${empty}s" "" | tr ' ' '░'
    fi
    printf "] %d%%\n\n" "$percent"
}

log_step() {
    ((++CURRENT_STEP))
    local title="$1"
    local pct=$(( (CURRENT_STEP * 100) / TOTAL_STEPS ))
    
    echo -e "\n${BLUE}${BOLD}───────────────────────────────────────────────────────────────────${NC}"
    echo -e "${BLUE}${BOLD}[$CURRENT_STEP/$TOTAL_STEPS] $title${NC}"
    echo -e "${BLUE}${BOLD}───────────────────────────────────────────────────────────────────${NC}"
    render_progress "$pct"
    log_to_file "STEP" "Started step: $title"
}

log_success() { echo -e "  ${GREEN}✔${NC} $1"; log_to_file "SUCCESS" "$1"; }
log_fail()    { echo -e "  ${RED}❌${NC} $1"; log_to_file "ERROR" "$1"; }
log_info()    { echo -e "  ${CYAN}ℹ${NC} $1"; log_to_file "INFO" "$1"; }
log_warn()    { echo -e "  ${YELLOW}⚠${NC} $1"; log_to_file "WARN" "$1"; }

# ==============================================================================
# 3. Structural Hardware & Repository Inspection Functions
# ==============================================================================

verify_environment() {
    if [ ! -d "configs" ]; then
        log_fail "Directory root error. Script must be executed inside the git repository."
        exit 1
    fi

    if [ ! -f /etc/arch-release ]; then
        log_fail "Distribution target unsupported. This profile requires Arch Linux."
        exit 1
    fi
}

probe_network() {
    log_to_file "NETWORK" "Running network link tests."
    # High performance /dev/tcp connection attempt to public DNS servers
    if { true > "/dev/tcp/1.1.1.1/53"; } &>/dev/null || \
       { true > "/dev/tcp/8.8.8.8/53"; } &>/dev/null; then
        HAS_INTERNET=true
        log_to_file "NETWORK" "Internet access available."
    else
        HAS_INTERNET=false
        log_to_file "NETWORK" "Internet access unavailable."
    fi
}

get_discovered_modules() {
    local dynamic_modules=()
    local ordered_item
    
    # 1. Add configurations specified in the installation order
    for ordered_item in "${PREFERRED_ORDER[@]}"; do
        if [ -d "configs/$ordered_item" ]; then
            dynamic_modules+=("$ordered_item")
        fi
    done
    
    # 2. Scan and append any newly added configurations found in the directory
    if [ -d "configs" ]; then
        local entry
        for entry in configs/*; do
            if [ -d "$entry" ]; then
                local base_entry="${entry##*/}"
                local is_known=false
                local known_item
                
                for known_item in "${dynamic_modules[@]}"; do
                    if [[ "$known_item" == "$base_entry" ]]; then
                        is_known=true
                        break
                    fi
                done
                
                if ! $is_known; then
                    dynamic_modules+=("$base_entry")
                fi
            fi
        done
    fi
    printf '%s\n' "${dynamic_modules[@]}"
}

get_system_aur_helper() {
    if command -v yay &>/dev/null; then
        echo "yay"
    elif command -v paru &>/dev/null; then
        echo "paru"
    else
        echo ""
    fi
}

# ==============================================================================
# 4. Functional Execution Core Phases
# ==============================================================================

phase_validate_env() {
    log_step "Validating Environment"
    
    if ! command -v niri &>/dev/null; then
        log_warn "Niri window manager not found in local system bin paths."
    else
        log_success "Niri base environment verified."
    fi

    if ! command -v noctalia &>/dev/null; then
        log_warn "Noctalia configuration shell interface not found."
    else
        log_success "Noctalia base environment verified."
    fi
}

phase_system_refresh() {
    log_step "Updating System"
    if $DRY_RUN; then log_info "Dry Run: Skipping system updates."; return; fi

    if ! $HAS_INTERNET; then
        log_warn "Offline state detected. Skipping pacman mirror sync operations."
        return
    fi

    read -rp "  Run system package upgrade via pacman? [Y/n]: " choice
    choice=${choice:-Y}
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        log_info "Running pacman system upgrade..."
        if sudo pacman -Syu; then
            log_success "System update complete."
        else
            log_fail "Pacman synchronization encountered an execution error."
            exit 1
        fi
    else
        log_info "System update skipped by user choice."
    fi
}

phase_inspect_dependencies() {
    log_step "Checking Installed Programs"
    local modules
    mapfile -t modules < <(get_discovered_modules)
    
    local mod
    for mod in "${modules[@]}"; do
        local check_cmd="${BINARY_MAP[$mod]:-"$mod"}"
        local target_pkg="${PACKAGE_MAP[$mod]:-"$mod"}"
        
        if command -v "$check_cmd" &>/dev/null; then
            log_success "Package dependency met: $mod ($target_pkg)"
            ALREADY_PRESENT_PACKAGES+=("$target_pkg")
        else
            log_warn "Package dependency missing: $mod ($target_pkg)"
        fi
    done
}

phase_resolve_dependencies() {
    log_step "Installing Missing Programs"
    if $DRY_RUN; then log_info "Dry Run: Skipping application deployment."; return; fi

    if ! $HAS_INTERNET; then
        log_warn "Network connection required to install packages. Skipping package deployment."
        return
    fi

    local modules
    mapfile -t modules < <(get_discovered_modules)
    local missing_pkgs=()
    local missing_mods=()

    local mod
    for mod in "${modules[@]}"; do
        local check_cmd="${BINARY_MAP[$mod]:-"$mod"}"
        local target_pkg="${PACKAGE_MAP[$mod]:-"$mod"}"
        
        if ! command -v "$check_cmd" &>/dev/null; then
            missing_pkgs+=("$target_pkg")
            missing_mods+=("$mod")
        fi
    done

    if [ ${#missing_pkgs[@]} -eq 0 ]; then
        log_success "All application dependencies are verified."
        return
    fi

    echo -e "  The following programs are missing: ${YELLOW}${missing_pkgs[*]}${NC}"
    read -rp "  Install missing programs? [Y/n]: " choice
    choice=${choice:-Y}

    if [[ ! "$choice" =~ ^[Yy]$ ]]; then
        log_warn "Skipped program installation. Some system components may be non-functional."
        return
    fi

    local helper
    helper=$(get_system_aur_helper)

    local i
    for ((i=0; i<${#missing_pkgs[@]}; i++)); do
        local pkg="${missing_pkgs[i]}"
        log_info "Installing package: $pkg"
        
        if sudo pacman -S --needed --noconfirm "$pkg" 2>>"$LOG_FILE"; then
            log_success "Successfully installed native package: $pkg"
            INSTALLED_PACKAGES+=("$pkg")
        else
            if [ -n "$helper" ]; then
                log_info "Package not found natively. Retrying installation with AUR helper: $helper"
                if "$helper" -S --needed --noconfirm "$pkg" 2>>"$LOG_FILE"; then
                    log_success "Successfully installed AUR package: $pkg"
                    INSTALLED_PACKAGES+=("$pkg")
                    continue
                fi
            fi
            log_fail "Failed to install required program package: $pkg"
            FAILED_PACKAGES+=("$pkg")
        fi
    done
}

phase_execute_backup() {
    log_step "Backing Up Existing Configurations"
    if $DRY_RUN; then log_info "Dry Run: Bypassing filesystem backup creation."; return; fi

    local modules
    mapfile -t modules < <(get_discovered_modules)
    local verified_backups=()

    local mod
    for mod in "${modules[@]}"; do
        if [ -e "$HOME/.config/$mod" ]; then
            verified_backups+=("$mod")
        fi
    done

    if [ ${#verified_backups[@]} -eq 0 ]; then
        log_info "No pre-existing local configurations detected. Skipping backup phase."
        return
    fi

    if ! mkdir -p "$BACKUP_DIR" 2>>"$LOG_FILE"; then
        log_fail "Failed to initialize backup matrix location directory."
        exit 1
    fi

    for mod in "${verified_backups[@]}"; do
        if cp -a "$HOME/.config/$mod" "$BACKUP_DIR/" 2>>"$LOG_FILE"; then
            log_success "Saved backup copy of: ~/.config/$mod"
        else
            log_fail "Failed to copy backup configurations for module component target: $mod"
        fi
    done
}

phase_deploy_configs() {
    local interactive=$1
    log_step "Installing Configurations"
    
    local modules
    mapfile -t modules < <(get_discovered_modules)
    
    if [ ! -d "$HOME/.config" ] && ! $DRY_RUN; then
        mkdir -p "$HOME/.config" 2>>"$LOG_FILE"
    fi

    local mod
    for mod in "${modules[@]}"; do
        local action=true
        if $interactive; then
            read -rp "  Install user configuration profile layout for [${mod}]? [Y/n]: " choice
            choice=${choice:-Y}
            [[ ! "$choice" =~ ^[Yy]$ ]] && action=false
        fi

        if $action; then
            if $DRY_RUN; then
                log_info "Dry Run: Would safe-deploy configurations path profile module: $mod"
                INSTALLED_CONFIGS+=("$mod")
            else
                # Atomic deployment: Copy files to a temporary directory first, then move them into place
                local tmp_dest="$HOME/.config/.$mod.tmp.$TIMESTAMP"
                local final_dest="$HOME/.config/$mod"
                
                rm -rf "$tmp_dest"
                if cp -r "configs/$mod" "$tmp_dest" 2>>"$LOG_FILE"; then
                    if [ -e "$final_dest" ]; then
                        rm -rf "$final_dest" 2>>"$LOG_FILE"
                    fi
                    if mv "$tmp_dest" "$final_dest" 2>>"$LOG_FILE"; then
                        log_success "Installed configuration profile: $mod"
                        INSTALLED_CONFIGS+=("$mod")
                    else
                        log_fail "Atomic move step failed for configuration module: $mod"
                        FAILED_CONFIGS+=("$mod")
                    fi
                else
                    log_fail "Staging execution step failed for configuration module: $mod"
                    FAILED_CONFIGS+=("$mod")
                    rm -rf "$tmp_dest"
                fi
            fi
        else
            log_warn "Skipped installation profile: $mod"
            SKIPPED_CONFIGS+=("$mod")
        fi
    done

    # --- Supplementary Non-XDG Asset Deployments ---
    local asset_folders=("wallpapers" "fonts" "themes" "icons" "bin")
    local asset
    for asset in "${asset_folders[@]}"; do
        if [ -d "$asset" ]; then
            local dest=""
            case "$asset" in
                "wallpapers") dest="$HOME/Pictures/Wallpapers" ;;
                "fonts")      dest="$HOME/.local/share/fonts" ;;
                "themes")     dest="$HOME/.local/share/themes" ;;
                "icons")      dest="$HOME/.local/share/icons" ;;
                "bin")         dest="$HOME/.local/bin" ;;
            esac
            
            if [ -n "$dest" ]; then
                log_info "Installing auxiliary asset profile: $asset"
                if ! $DRY_RUN; then
                    mkdir -p "$dest" 2>>"$LOG_FILE"
                    if cp -a "$asset"/. "$dest/" 2>>"$LOG_FILE"; then
                        log_success "Asset deployment complete: $asset -> $dest"
                    else
                        log_fail "Failed to install asset files for: $asset"
                    fi
                else
                    log_info "Dry Run: Would deploy additional components from $asset -> $dest"
                fi
            fi
        fi
    done
}

phase_signal_environments() {
    log_step "Reloading Running Applications"
    if $DRY_RUN; then log_info "Dry Run: Bypassing operational live reloads."; return; fi

    if pgrep -x "kitty" &>/dev/null; then
        killall -USR1 kitty 2>/dev/null && log_success "Kitty configuration reload signal dispatched." || true
    fi
    if pgrep -x "waybar" &>/dev/null; then
        killall -SIGUSR2 waybar 2>/dev/null && log_success "Waybar configuration reload signal dispatched." || true
    fi
}

phase_compile_summary() {
    log_step "Installation Summary"
    local end_time
  end_time=$(date +%s)
    local elapsed=$((end_time - START_TIME))
    
    echo -e "  ${BOLD}✓ Installed Packages:${NC}       ${GREEN}${INSTALLED_PACKAGES[*]:-None}${NC}"
    echo -e "  ${BOLD}✓ Already Met Packages:${NC}    ${CYAN}${ALREADY_PRESENT_PACKAGES[*]:-None}${NC}"
    echo -e "  ${BOLD}✓ Failed Package Installs:${NC}   ${RED}${FAILED_PACKAGES[*]:-None}${NC}"
    echo -e "  ${BOLD}✓ Installed Configs:${NC}        ${GREEN}${INSTALLED_CONFIGS[*]:-None}${NC}"
    echo -e "  ${BOLD}✓ Skipped Configs:${NC}          ${YELLOW}${SKIPPED_CONFIGS[*]:-None}${NC}"
    echo -e "  ${BOLD}✓ Failed Configs:${NC}           ${RED}${FAILED_CONFIGS[*]:-None}${NC}"
    
    if [ -d "$BACKUP_DIR" ]; then
        echo -e "  ${BOLD}✓ Backup Matrix Root:${NC}       ${PURPLE}$BACKUP_DIR${NC}"
    fi
    echo -e "  ${BOLD}✓ Diagnostic Log Location:${NC}  ${BLUE}$LOG_FILE${NC}"
    echo -e "  ${BOLD}✓ Run Time Processing:${NC}      ${YELLOW}$elapsed seconds${NC}"
    echo -e "${BLUE}───────────────────────────────────────────────────────────────────${NC}"
}

# ==============================================================================
# 5. Backup Restore Infrastructure Management
# ==============================================================================

execute_restore_operation() {
    TOTAL_STEPS=2
    log_step "Restoring System Backups"
    
    local backups=()
    if [ -d "$HOME" ]; then
        local dir
        # Safely locate timestamped backup matrices using bash wildcards
        for dir in "$HOME"/.config-backup-*; do
            if [ -d "$dir" ]; then
                backups+=("$dir")
            fi
        done
    fi

    if [ ${#backups[@]} -eq 0 ]; then
        log_fail "No previous configurations backup archives found."
        return
    fi

    echo -e "\n  ${BOLD}Available Backups:${NC}"
    local i
    for i in "${!backups[@]}"; do
        echo -e "  ${GREEN}[$((i+1))]${NC} $(basename "${backups[$i]}")"
    done
    echo -e "  ${RED}[c]${NC} Cancel"
    echo -e "${BLUE}───────────────────────────────────────────────────────────────────${NC}"
    
    read -rp "Select a backup archive index to restore: " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -le "${#backups[@]}" ] && [ "$choice" -gt 0 ]; then
        local target_dir="${backups[$((choice - 1))]}"
        log_info "Restoring configuration from: $target_dir"
        
        if [ ! -d "$HOME/.config" ]; then
            mkdir -p "$HOME/.config"
        fi

        local item
        for item in "$target_dir"/*; do
            if [ -e "$item" ]; then
                local base_name="${item##*/}"
                # Safely clear the target destination before copying files back
                rm -rf "$HOME/.config/$base_name" 2>>"$LOG_FILE"
                if cp -a "$item" "$HOME/.config/" 2>>"$LOG_FILE"; then
                    log_success "Restored: ~/.config/$base_name"
                else
                    log_fail "Failed to restore module: $base_name"
                fi
            fi
        done
        log_success "System rollback operations completed."
    else
        log_info "Rollback procedures canceled."
    fi
}

# ==============================================================================
# 6. Global Operational Entry Execution Orchestrator
# ==============================================================================

run_orchestrated_installer() {
    local interactive=$1
    phase_validate_env
    phase_system_refresh
    phase_inspect_dependencies
    phase_resolve_dependencies
    phase_execute_backup
    phase_deploy_configs "$interactive"
    phase_signal_environments
    phase_compile_summary
    
    echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}                    Installation Complete!                         ${NC}"
    echo -e "${GREEN}                                                                   ${NC}"
    echo -e "${GREEN}         Please log out and log back in to reload your profile.    ${NC}"
    echo -e "${GREEN}                   Enjoy Gigi's Rice 🌿                            ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${NC}\n"
}

main() {
    verify_environment
    probe_network
    print_banner

    echo -e "  ${BOLD}Select an action to proceed:${NC}"
    echo -e "  ${GREEN}[1]${NC} Full Auto-Install"
    echo -e "  ${GREEN}[2]${NC} Install Selected Configs (Interactive Mode)"
    echo -e "  ${YELLOW}[3]${NC} Restore Backup"
    echo -e "  ${CYAN}[4]${NC} Dry Run"
    echo -e "  ${RED}[5]${NC} Exit"
    echo -e "───────────────────────────────────────────────────────────────────${NC}"
    read -rp "Selection: " menu_choice

    case "$menu_choice" in
        1)
            DRY_RUN=false
            run_orchestrated_installer false
            ;;
        2)
            DRY_RUN=false
            run_orchestrated_installer true
            ;;
        3)
            execute_restore_operation
            ;;
        4)
            DRY_RUN=true
            log_warn "Dry Run Simulation Active. No modifications will be made to your system."
            run_orchestrated_installer false
            ;;
        5)
            echo -e "\nExiting installation workspace. Have an excellent day! 🌿"
            exit 0
            ;;
        *)
            log_fail "Invalid menu choice selected."
            exit 1
            ;;
    esac
}

main
