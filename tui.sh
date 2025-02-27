#!/usr/bin/env bash

# Configuration
THEME_DIR="./themes"
PREVIEW_FILE="preview.png"
INSTALL_SCRIPT="./install.sh"
declare -a THEMES
SELECTED_INDEX=0
TERMINAL_WIDTH=$(tput cols)
TERMINAL_HEIGHT=$(tput lines)
LIST_WIDTH=$((TERMINAL_WIDTH/3))
PREVIEW_WIDTH=$((TERMINAL_WIDTH - LIST_WIDTH - 3))
PREVIEW_HEIGHT=$((TERMINAL_HEIGHT - 10))  # Adjusted for new header/footer

# Color definitions
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BRIGHT_BLUE=$(tput setaf 12)
ORANGE=$(tput setaf 208)
RESET=$(tput sgr0)
BOLD=$(tput bold)

# Gradient colors for title
GRADIENT=($(seq 21 28 | xargs -I{} tput setaf {}))
GRADIENT_LEN=${#GRADIENT[@]}

# Cleanup function
cleanup() {
    tput cnorm
    stty echo
    tput rmcup 2>/dev/null
    clear
    exit 0
}

# Trap signals
trap cleanup EXIT INT TERM

# Check dependencies
check_dependencies() {
    if ! command -v kitty &> /dev/null; then
        echo "${YELLOW}Warning: Kitty terminal not detected. Image previews disabled.${RESET}"
        return 1
    fi
    if ! command -v toilet &> /dev/null || ! command -v boxes &> /dev/null; then
        echo "${YELLOW}Warning: 'toilet' or 'boxes' not found. Some visual enhancements disabled.${RESET}"
        return 1
    fi
    return 0
}

# Load available themes
load_themes() {
    local theme_dirs=("$THEME_DIR"/*)
    THEMES=()
    for dir in "${theme_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            THEMES+=("$(basename "$dir")")
        fi
    done
    ((${#THEMES[@]})) || {
        echo "${RED}Error: No themes found in $THEME_DIR${RESET}"
        exit 1
    }
}

# Handle terminal resize
handle_resize() {
    TERMINAL_WIDTH=$(tput cols)
    TERMINAL_HEIGHT=$(tput lines)
    LIST_WIDTH=$((TERMINAL_WIDTH/3))
    PREVIEW_WIDTH=$((TERMINAL_WIDTH - LIST_WIDTH - 3))
    PREVIEW_HEIGHT=$((TERMINAL_HEIGHT - 10))
    draw_borders
    draw_theme_list
    show_preview "${THEMES[SELECTED_INDEX]}"
}

# Draw decorative header
draw_header() {
    local title=" GRUB WITH FLARE "
    local title_len=${#title}
    local padding=$(( (TERMINAL_WIDTH - title_len) / 2 ))
    
    # Top border
    echo -ne "${BLUE}╔"
    printf "%0.s═" $(seq 1 $((TERMINAL_WIDTH - 2)))
    echo -ne "╗${RESET}"
    
    # Title row
    echo -ne "${BLUE}║${RESET}"
    printf "%${padding}s" ""
    for ((i=0; i<${#title}; i++)); do
        echo -ne "${BLUE}${BOLD}${title:$i:1}${RESET}"
    done
    printf "%$((TERMINAL_WIDTH - padding - title_len - 2))s"
    echo -ne "${BLUE}║${RESET}"
    
    # # Bottom border
    echo -ne "${BLUE}║"
    printf "%0.s═" $(seq 1 $((TERMINAL_WIDTH - 2)))
    echo -ne "║${RESET}"
}

# Updated UI framework
draw_borders() {
    clear
    draw_header
    
    # # Main content box
    # tput cup 4 0
    # echo -ne "${BLUE}╔"
    # printf "%0.s═" $(seq 1 $((LIST_WIDTH - 1)))
    # echo -ne "╦"
    # printf "%0.s═" $(seq 1 $((PREVIEW_WIDTH - 1)))
    # echo -ne "╗${RESET}"
    
    # # Column headers with better positioning
    tput cup 3 $((LIST_WIDTH / 2 - 10))
    echo -ne "${BOLD}${CYAN}Available Themes (${#THEMES[@]})${RESET}"
    
    tput cup 5 0
    echo -ne "${BLUE}"
    # printf "%0.s═" $(seq 1 $((LIST_WIDTH - 150)))
    echo -ne ""
    printf "%0.s═" $(seq 1 $((PREVIEW_WIDTH - 54)))
    echo -ne "${RESET}"
    
    
    # tput cup 3 $((LIST_WIDTH + PREVIEW_WIDTH / 2 - 6))
    # echo -ne "${BOLD}${CYAN}Theme Preview${RESET}"
    
    
    
    # Footer - Top border
    tput cup $((TERMINAL_HEIGHT - 3)) 0
    echo -ne "${BLUE}║"
    printf "%0.s═" $(seq 1 $((TERMINAL_WIDTH - 2)))
    echo -ne "║${RESET}"
    
    # Help text in a box
    tput cup $((TERMINAL_HEIGHT - 2)) 0
    echo -ne "${BLUE}║${RESET}"
    
    # Center the help text
    local help_text="↑/↓: Navigate  |  Enter: Install  |  Q: Quit"
    local help_len=${#help_text}
    local help_padding=$(( (TERMINAL_WIDTH - help_len - 2) / 2 ))
    
    printf "%${help_padding}s" ""
    echo -ne "${BOLD}${YELLOW}↑/↓: Navigate${RESET}  |  ${GREEN}Enter: Install${RESET}  |  ${RED}Q: Quit${RESET}"
    printf "%$(( TERMINAL_WIDTH - help_padding - help_len - 2 ))s" ""
    echo -ne "${BLUE}║${RESET}"
    
    # Bottom border
    tput cup $((TERMINAL_HEIGHT - 1)) 0
    echo -ne "${BLUE}╚"
    printf "%0.s═" $(seq 1 $((TERMINAL_WIDTH - 2)))
    echo -ne "╝${RESET}"
}

# Enhanced theme list display
draw_theme_list() {
    local start_idx=0
    local max_items=$((TERMINAL_HEIGHT - 10))
    tput cup 6 0
    for ((i=0; i<max_items+4; i++)); do
        tput cup $((i + 3)) 0
        echo -ne "${BLUE}║${RESET}"
    done

    
    for ((i=0; i<max_items; i++)); do
        tput cup $((i + 6)) 2
        local idx=$((start_idx + i))
        if ((idx < ${#THEMES[@]})); then
            if ((idx == SELECTED_INDEX)); then
                # Selected item effect
                echo -ne "${GREEN}▶ ${THEMES[idx]} "
                printf "%$((LIST_WIDTH - ${#THEMES[idx]} - 5))s" " "
                echo -ne "${WHITE}${RESET}"
            else
                # Unselected items
                echo -ne "  ${BLUE}${THEMES[idx]}${RESET}"
                printf "%$((LIST_WIDTH - ${#THEMES[idx]} - 2))s" " "
            fi
        fi
    done
}

# Enhanced preview display
show_preview() {
    local theme="$1"
    local preview_path="$THEME_DIR/$theme/$PREVIEW_FILE"
    
    # Clear preview area with style
    tput cup 6 $((LIST_WIDTH + 2))
    echo -ne "${BLUE}║${RESET}"
    for ((i=3; i<TERMINAL_HEIGHT-3; i++)); do
        tput cup $i $((LIST_WIDTH + 2))
        
        echo -ne "${BLUE}║${RESET}"
        
        printf "%$((PREVIEW_WIDTH - 2))s" " "
        tput cup $i $((TERMINAL_WIDTH - 1))
        echo -ne "${BLUE}║${RESET}"
    done

    # Dynamic image scaling
    local img_width=$((PREVIEW_WIDTH - 4))
    local img_height=$((PREVIEW_HEIGHT - 2))
    
    if [[ -f "$preview_path" ]]; then
        if check_dependencies; then
            kitty +kitten icat --silent \
                --scale-up \
                --place "${img_width}x${img_height}@$((LIST_WIDTH + 4))x6" \
                "$preview_path"
        else
            tput cup $((TERMINAL_HEIGHT/2)) $((LIST_WIDTH + (PREVIEW_WIDTH/2) - 12))
            echo -ne "${YELLOW}╭$(printf "%0.s─" $(seq 1 23))╮${RESET}"
            tput cup $((TERMINAL_HEIGHT/2 + 1)) $((LIST_WIDTH + (PREVIEW_WIDTH/2) - 12))
            echo -ne "${YELLOW}│ Preview requires Kitty terminal │${RESET}"
            tput cup $((TERMINAL_HEIGHT/2 + 2)) $((LIST_WIDTH + (PREVIEW_WIDTH/2) - 12))
            echo -ne "${YELLOW}╰$(printf "%0.s─" $(seq 1 23))╯${RESET}"
        fi
    else
        tput cup $((TERMINAL_HEIGHT/2)) $((LIST_WIDTH + (PREVIEW_WIDTH/2) - 10))
        echo -ne "${RED}╔$(printf "%0.s═" $(seq 1 21))╗${RESET}"
        tput cup $((TERMINAL_HEIGHT/2 + 1)) $((LIST_WIDTH + (PREVIEW_WIDTH/2) - 10))
        echo -ne "${RED}║ Preview unavailable ║${RESET}"
        tput cup $((TERMINAL_HEIGHT/2 + 2)) $((LIST_WIDTH + (PREVIEW_WIDTH/2) - 10))
        echo -ne "${RED}╚$(printf "%0.s═" $(seq 1 21))╝${RESET}"
    fi
}

# Fancy installation handler
install_theme() {
    local theme="${THEMES[SELECTED_INDEX]}"
    clear
    
    # ASCII art animation
    echo -ne "${CYAN}"
    toilet -f future "Installing..." | boxes -d cat -a c
    echo -ne "${RESET}"
    
    echo -ne "\n${BOLD}${BLUE}»»» ${WHITE}Theme: ${MAGENTA}${theme}${RESET}\n"
    
    if ! sudo "$INSTALL_SCRIPT" <<<"$((SELECTED_INDEX + 1))"; then
        echo -ne "\n${RED}"
        toilet -f pagga " FAILED! " | boxes -d tjc
        echo -ne "${RESET}"
        read -rp "Press any key to continue..."
        return 1
    fi
    
    echo -ne "\n${GREEN}"
    toilet -f ivrit " SUCCESS! " | boxes -d spring
    echo -ne "${RESET}"
    read -rp "Press any key to continue..."
    return 0
}

# Main loop with visual enhancements
main() {
    tput smcup 2>/dev/null
    tput civis
    stty -echo
    trap handle_resize SIGWINCH
    load_themes
    handle_resize
    
    while true; do
        draw_borders
        draw_theme_list
        show_preview "${THEMES[SELECTED_INDEX]}"
        
        read -rsn1 input
        case "$input" in
            $'\x1b') 
                read -rsn2 -t 1 input
                case "$input" in
                    '[A') ((SELECTED_INDEX > 0)) && ((SELECTED_INDEX--)) ;;
                    '[B') ((SELECTED_INDEX < ${#THEMES[@]} - 1)) && ((SELECTED_INDEX++)) ;;
                esac
                ;;
            "") install_theme
                handle_resize ;;
            q|Q) cleanup ;;
        esac
    done
}

# Entry point
if [[ "$(id -u)" -ne 0 ]]; then
    echo "${RED}This script must be run as root${RESET}"
    exit 1
fi

main