#!/bin/bash

#/**
# * Grub With Flair - Grub2 Theme Installer
# *
# * A script to easily install and configure custom Grub2 themes
# * 
# * @license MIT
# * @author  "Chris Titus" <contact@christitus.com>
# * @author  "Matthias Morin" <mat@tangoman.io>
# * @version 1.0.1
# * @link    https://youtu.be/BAyzHP1Cqb0
# */

# Configuration
#--------------
THEME_DIR='/boot/grub/themes'
THEME_NAME=''
GRUB_CONFIG_PATH='/etc/default/grub'
GRUB_BACKUP_PATH="${GRUB_CONFIG_PATH}.bak"

# Text formatting functions
#-------------------------
function echo_title() {     echo -ne "\033[1;44;37m${*}\033[0m\n"; }
function echo_caption() {   echo -ne "\033[0;1;44m${*}\033[0m\n"; }
function echo_bold() {      echo -ne "\033[0;1;34m${*}\033[0m\n"; }
function echo_danger() {    echo -ne "\033[0;31m${*}\033[0m\n"; }
function echo_success() {   echo -ne "\033[0;32m${*}\033[0m\n"; }
function echo_warning() {   echo -ne "\033[0;33m${*}\033[0m\n"; }
function echo_secondary() { echo -ne "\033[0;34m${*}\033[0m\n"; }
function echo_info() {      echo -ne "\033[0;35m${*}\033[0m\n"; }
function echo_primary() {   echo -ne "\033[0;36m${*}\033[0m\n"; }
function echo_error() {     echo -ne "\033[0;1;31merror:\033[0;31m\t${*}\033[0m\n"; }
function echo_label() {     echo -ne "\033[0;1;32m${*}:\033[0m\t"; }
function echo_prompt() {    echo -ne "\033[0;36m${*}\033[0m "; }

# Display a stylized header
#-------------------------
function splash() {
    local hr
    hr=" **$(printf "%${#1}s" | tr ' ' '*')** "
    echo_title "${hr}"
    echo_title " * $1 * "
    echo_title "${hr}"
    echo
}

# Verify script is running with root privileges
#--------------------------------------------
function check_root() {
    ROOT_UID=0
    if [[ ! "${UID}" -eq "${ROOT_UID}" ]]; then
        echo_error 'This script must be run with root privileges'
        echo_info 'Please try: sudo ./install.sh'
        exit 1
    fi
}

# Get available themes from themes directory
#----------------------------------------
function get_available_themes() {
    local themes_dir="./themes"
    if [[ ! -d "${themes_dir}" ]]; then
        echo_error "Themes directory not found: ${themes_dir}"
        exit 1
    fi  # Fixed closing bracket here

    # Get directories only, exclude hidden directories
    local available_themes=($(find "${themes_dir}" -mindepth 1 -maxdepth 1 -type d -not -path '*/\.*' -printf "%f\n" | sort))
    
    if [[ ${#available_themes[@]} -eq 0 ]]; then
        echo_error "No themes found in ${themes_dir}"
        exit 1
    fi  # Fixed closing bracket here

    # Add quit option
    available_themes+=('Quit')
    echo "${available_themes[@]}"
}

# Present theme options to user
#----------------------------
function select_theme() {
    local themes=($(get_available_themes))

    echo_info "Available themes:"
    PS3=$(echo_prompt '\nChoose the theme you want to install: ')
    select THEME_NAME in "${themes[@]}"; do
        if [[ "${THEME_NAME}" == "Quit" ]]; then
            echo_info "Exiting installation process..."
            exit 0
        elif [[ -n "${THEME_NAME}" ]]; then
            if [[ -d "./themes/${THEME_NAME}" ]]; then
                splash "Installing ${THEME_NAME} Theme..."
                break
            else
                echo_error "Theme directory not found: ./themes/${THEME_NAME}"
                exit 1
            fi
        else
            echo_warning "Invalid option \"${REPLY}\". Please select a valid number."
        fi
    done
}

# Back up original Grub configuration
#----------------------------------
function backup_grub_config() {
    echo_info "Creating backup of Grub configuration..."
    echo_info "cp -an ${GRUB_CONFIG_PATH} ${GRUB_BACKUP_PATH}"
    cp -an "${GRUB_CONFIG_PATH}" "${GRUB_BACKUP_PATH}"
    
    if [[ -f "${GRUB_BACKUP_PATH}" ]]; then
        echo_success "Backup created at ${GRUB_BACKUP_PATH}"
    else
        echo_warning "Failed to create backup. Proceeding anyway..."
    fi
}

# Copy theme files to Grub themes directory
#----------------------------------------
function install_theme() {
    # Create themes directory if it doesn't exist
    if [[ ! -d "${THEME_DIR}/${THEME_NAME}" ]]; then
        echo_primary "Installing ${THEME_NAME} theme..."

        echo_info "mkdir -p \"${THEME_DIR}/${THEME_NAME}\""
        mkdir -p "${THEME_DIR}/${THEME_NAME}"

        echo_info "cp -a ./themes/\"${THEME_NAME}\"/* \"${THEME_DIR}/${THEME_NAME}\""
        cp -a ./themes/"${THEME_NAME}"/* "${THEME_DIR}/${THEME_NAME}"
        
        if [[ $? -eq 0 ]]; then
            echo_success "Theme files successfully copied"
        else
            echo_error "Failed to copy theme files"
            exit 1
        fi
    else
        echo_info "Theme directory already exists. Skipping file copy..."
    fi
}

# Update Grub configuration file
#-----------------------------
function config_grub() {
    echo_primary '=== Updating Grub Configuration ==='
    
    # Enable Grub menu
    echo_info "Enabling Grub menu..."
    sed -i '/GRUB_TIMEOUT_STYLE=/d' "${GRUB_CONFIG_PATH}"
    sed -i '/GRUB_TERMINAL_OUTPUT=/d' "${GRUB_CONFIG_PATH}" # Fix for issue #16
    echo 'GRUB_TIMEOUT_STYLE="menu"' >> "${GRUB_CONFIG_PATH}"

    # Set Grub timeout
    echo_info "Setting Grub timeout to 60 seconds..."
    sed -i '/GRUB_TIMEOUT=/d' "${GRUB_CONFIG_PATH}"
    echo 'GRUB_TIMEOUT="60"' >> "${GRUB_CONFIG_PATH}"

    # Set theme
    echo_info "Setting ${THEME_NAME} as default theme..."
    sed -i '/GRUB_THEME=/d' "${GRUB_CONFIG_PATH}"
    echo "GRUB_THEME=\"${THEME_DIR}/${THEME_NAME}/theme.txt\"" >> "${GRUB_CONFIG_PATH}"
    
    # Set graphics mode
    echo_info "Setting Grub graphics mode to auto..."
    sed -i '/GRUB_GFXMODE=/d' "${GRUB_CONFIG_PATH}"
    echo 'GRUB_GFXMODE="auto"' >> "${GRUB_CONFIG_PATH}"
    
    echo_success "Grub configuration updated successfully"
}

# Apply configuration changes by updating Grub
#-------------------------------------------
function update_grub() {
    echo_primary 'Applying changes to Grub...'
    
    if [[ -x "$(command -v update-grub)" ]]; then
        echo_info 'Running: update-grub'
        update-grub
    elif [[ -x "$(command -v grub-mkconfig)" ]]; then
        echo_info 'Running: grub-mkconfig -o /boot/grub/grub.cfg'
        grub-mkconfig -o /boot/grub/grub.cfg
    elif [[ -x "$(command -v grub2-mkconfig)" ]]; then
        if [[ -x "$(command -v zypper)" ]]; then
            echo_info 'Running: grub2-mkconfig -o /boot/grub2/grub.cfg'
            grub2-mkconfig -o /boot/grub2/grub.cfg
        elif [[ -x "$(command -v dnf)" ]]; then
            echo_info 'Running: grub2-mkconfig -o /boot/grub2/grub.cfg'
            grub2-mkconfig -o /boot/grub2/grub.cfg
        fi
    else
        echo_error "Could not find a way to update Grub configuration on your system"
        exit 1
    fi
    
    if [[ $? -eq 0 ]]; then
        echo_success "Grub configuration successfully updated"
    else
        echo_error "Failed to update Grub configuration"
        exit 1
    fi
}

# Check and install os-prober if needed
#----------------------------------
function check_os_prober() {
    if ! command -v os-prober &> /dev/null; then
        echo_warning "os-prober is not installed on your system."
        echo_info "os-prober is recommended for detecting other operating systems on your computer"
        echo_info "This helps GRUB show boot options for all installed operating systems"
        
        echo_prompt "Would you like to install os-prober? (y/N): "
        read -r response
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            if command -v pacman &> /dev/null; then
                echo_info "Installing os-prober using pacman..."
                pacman -S --noconfirm os-prober
            elif command -v apt-get &> /dev/null; then
                echo_info "Installing os-prober using apt..."
                apt-get update && apt-get install -y os-prober
            elif command -v dnf &> /dev/null; then
                echo_info "Installing os-prober using dnf..."
                dnf install -y os-prober
            else
                echo_error "Could not determine package manager. Please install os-prober manually."
                return 1
            fi
        else
            echo_info "Skipping os-prober installation..."
            return 0
        fi
    fi
    return 0
}

# Configure os-prober in GRUB
#--------------------------
function configure_os_prober() {
    local grub_config="${GRUB_CONFIG_PATH}"
    local os_prober_line="GRUB_DISABLE_OS_PROBER=false"
    
    if grep -q "^#${os_prober_line}$" "$grub_config"; then
        # Line exists but is commented out - uncomment it
        echo_info "Uncommenting os-prober configuration..."
        sed -i "s/^#${os_prober_line}$/${os_prober_line}/" "$grub_config"
    elif ! grep -q "^${os_prober_line}$" "$grub_config"; then
        # Line doesn't exist at all - add it
        echo_info "Adding os-prober configuration..."
        echo "${os_prober_line}" >> "$grub_config"
    else
        # Line already exists and is not commented - do nothing
        echo_info "os-prober already configured correctly..."
    fi
}

# Main script execution
#--------------------
function main() {
    splash 'Grub With Flair - Theme Installer'

    check_root
    check_os_prober
    configure_os_prober
    select_theme
    backup_grub_config
    install_theme
    config_grub
    update_grub

    echo_success '===================================='
    echo_success '  Grub Theme Installation Complete!'
    echo_success '===================================='
    echo_info "The ${THEME_NAME} theme will be applied at next boot"
}

# Execute main function
main
