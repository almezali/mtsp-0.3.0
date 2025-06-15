#!/bin/bash

# MTSP - Music Terminal Shell Player
# Version: 0.3.1
# Dependencies: mpv, socat, jq, youtube-dl (for Soundcloud support)

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Global variables
MUSIC_DIR="$HOME/Music"
CURRENT_TRACK=""
IS_PLAYING=0
REPEAT_MODE=0
SHUFFLE_MODE=0
PLAYLIST=()
PLAYLIST_TITLES=()
HISTORY=()
SUPPORTED_FORMATS=("mp3" "wav" "flac" "m4a" "ogg")
CURRENT_INDEX=0

# Function to display the ASCII art banner
show_banner() {
    echo -e "${GREEN}"
    echo "███╗   ███╗████████╗███████╗██████╗"
    echo "████╗ ████║╚══██╔══╝██╔════╝██╔══██╗"
    echo "██╔████╔██║   ██║   ███████╗██████╔╝"
    echo "██║╚██╔╝██║   ██║   ╚════██║██╔═══╝"
    echo "██║ ╚═╝ ██║   ██║   ███████║██║"
    echo "╚═╝     ╚═╝   ╚═╝   ╚══════╝╚═╝"
    echo -e "${NC}"
    echo "Music Terminal Shell Player v0.3.0"
    echo "--------------------------------"
}

# Function to display controls
show_controls() {
    echo -e "\n${BOLD}Controls:${NC}"
    echo "p - Play/Pause               + - Volume up"
    echo "n - Next track              - - Volume down"
    echo "b - Previous track          v - View playlist"
    echo "r - Toggle repeat           c - Clear playlist"
    echo "s - Toggle shuffle          h - Show this help"
    echo "l - Load playlist           q - Quit"
    echo "f - Load folder"
    echo "a - Add files"
    echo "u - Add Soundcloud URL"
    echo "o - Play online URL or m3u"
}

# Function to check dependencies
check_dependencies() {
    local missing_deps=0
    for cmd in mpv socat jq youtube-dl; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${RED}Error: $cmd is not installed${NC}"
            missing_deps=1
        fi
    done
    
    if [ $missing_deps -eq 1 ]; then
        echo -e "${YELLOW}Please install missing dependencies:${NC}"
        echo "sudo apt-get install mpv socat jq youtube-dl"
        exit 1
    fi
}

# Function to send commands to mpv
mpv_command() {
    echo '{ "command": '"$1"' }' | socat - /tmp/mpvsocket &> /dev/null
}

# Function to add track to history
add_to_history() {
    HISTORY+=("$1")
    if [ ${#HISTORY[@]} -gt 50 ]; then
        HISTORY=("${HISTORY[@]:1}")
    fi
}

# Function to get next track index
get_next_track() {
    if [ $SHUFFLE_MODE -eq 1 ]; then
        echo $((RANDOM % ${#PLAYLIST[@]}))
    else
        local next=$((CURRENT_INDEX + 1))
        if [ $next -ge ${#PLAYLIST[@]} ]; then
            if [ $REPEAT_MODE -eq 1 ]; then
                echo 0
            else
                echo -1
            fi
        else
            echo $next
        fi
    fi
}

# Function to get previous track index
get_previous_track() {
    if [ $SHUFFLE_MODE -eq 1 ]; then
        echo $((RANDOM % ${#PLAYLIST[@]}))
    else
        local prev=$((CURRENT_INDEX - 1))
        if [ $prev -lt 0 ]; then
            if [ $REPEAT_MODE -eq 1 ]; then
                echo $((${#PLAYLIST[@]} - 1))
            else
                echo -1
            fi
        else
            echo $prev
        fi
    fi
}

# Function to display playlist as a table
show_playlist() {
    if [ ${#PLAYLIST[@]} -eq 0 ]; then
        echo -e "${YELLOW}Playlist is empty${NC}"
        return
    fi

    echo -e "\n${BOLD}Current Playlist:${NC}"
    printf "${BOLD}%-4s %-50s %-10s${NC}\n" "№" "Title" "Status"
    echo "────────────────────────────────────────────────────────────"
    
    for i in "${!PLAYLIST[@]}"; do
        local status=""
        local title="${PLAYLIST_TITLES[$i]:-$(basename "${PLAYLIST[$i]}")}"
        
        if [ "${PLAYLIST[$i]}" = "$CURRENT_TRACK" ]; then
            if [ $IS_PLAYING -eq 1 ]; then
                status="▶ Playing"
            else
                status="❚❚ Paused"
            fi
            printf "${GREEN}%-4s %-50s %-10s${NC}\n" "$((i+1))" "$title" "$status"
        else
            printf "%-4s %-50s %-10s\n" "$((i+1))" "$title" "$status"
        fi
    done
    echo "────────────────────────────────────────────────────────────"
}

# Function to load a folder
load_folder() {
    echo -e "\n${YELLOW}Enter folder path (or press Enter for $MUSIC_DIR):${NC}"
    read folder_path
    
    if [ -z "$folder_path" ]; then
        folder_path="$MUSIC_DIR"
    fi
    
    if [ ! -d "$folder_path" ]; then
        echo -e "${RED}Error: Directory not found${NC}"
        return 1
    fi
    
    local count=0
    while IFS= read -r -d '' file; do
        PLAYLIST+=("$file")
        PLAYLIST_TITLES+=("$(basename "$file")")
        ((count++))
    done < <(find "$folder_path" -type f \( -name "*.mp3" -o -name "*.wav" -o -name "*.flac" -o -name "*.m4a" -o -name "*.ogg" \) -print0)
    
    echo -e "${GREEN}Added $count files to playlist${NC}"
    if [ ${#PLAYLIST[@]} -eq $count ]; then
        CURRENT_INDEX=0
        play_music "${PLAYLIST[0]}"
    fi
}

# Function to add Soundcloud track
add_soundcloud() {
    local url="$1"
    echo -e "${YELLOW}Fetching Soundcloud track...${NC}"
    
    # Get track info using youtube-dl
    local track_info=$(youtube-dl -j "$url" 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Could not fetch Soundcloud track${NC}"
        return 1
    fi
    
    local title=$(echo "$track_info" | jq -r '.title')
    PLAYLIST+=("$url")
    PLAYLIST_TITLES+=("$title")
    
    echo -e "${GREEN}Added to playlist: $title${NC}"
    if [ ${#PLAYLIST[@]} -eq 1 ]; then
        CURRENT_INDEX=0
        play_music "$url"
    fi
}

# Function to load and play m3u playlist or online URL
load_online_url_or_m3u() {
    echo -e "\n${YELLOW}Enter online URL or m3u playlist link:${NC}"
    read online_url
    if [[ "$online_url" == *.m3u || "$online_url" == *.m3u8 ]]; then
        echo -e "${YELLOW}Fetching m3u playlist...${NC}"
        mapfile -t m3u_tracks < <(curl -s "$online_url" | grep -Eo 'https?://[^\r\n]+' | grep -vE '\.m3u8?$')
        if [ ${#m3u_tracks[@]} -eq 0 ]; then
            echo -e "${RED}No tracks found in m3u playlist${NC}"
            return 1
        fi
        for track in "${m3u_tracks[@]}"; do
            PLAYLIST+=("$track")
            PLAYLIST_TITLES+=("$(basename "$track")")
        done
        echo -e "${GREEN}Added ${#m3u_tracks[@]} tracks from m3u playlist${NC}"
        if [ ${#PLAYLIST[@]} -eq ${#m3u_tracks[@]} ]; then
            CURRENT_INDEX=0
            play_music "${PLAYLIST[0]}"
        fi
    else
        # Assume direct online URL
        PLAYLIST+=("$online_url")
        PLAYLIST_TITLES+=("$online_url")
        echo -e "${GREEN}Added online URL to playlist${NC}"
        if [ ${#PLAYLIST[@]} -eq 1 ]; then
            CURRENT_INDEX=0
            play_music "$online_url"
        fi
    fi
}

# Function to play music
play_music() {
    local source="$1"
    CURRENT_TRACK="$source"
    
    # Kill existing mpv instance if it exists
    pkill -f "mpv --no-video --input-ipc-server=/tmp/mpvsocket"
    rm -f /tmp/mpvsocket
    
    if [[ "$source" == *"soundcloud.com"* ]]; then
        mpv --no-video --input-ipc-server=/tmp/mpvsocket "$source" &
    elif [[ "$source" == http* ]]; then
        mpv --no-video --input-ipc-server=/tmp/mpvsocket "$source" &
    elif [ -f "$source" ]; then
        mpv --no-video --input-ipc-server=/tmp/mpvsocket "$source" &
    else
        echo -e "${RED}Error: Invalid source${NC}"
        return 1
    fi
    
    IS_PLAYING=1
    add_to_history "$source"
    
    local title="${PLAYLIST_TITLES[$CURRENT_INDEX]:-$(basename "$source")}"
    echo -e "${GREEN}Now playing: $title${NC}"
    show_playlist
}

# Main loop
main() {
    check_dependencies
    show_banner
    show_controls
    
    while true; do
        read -n 1 -s key
        case "$key" in
            p)
                if [ $IS_PLAYING -eq 1 ]; then
                    mpv_command '["set_property", "pause", true]'
                    IS_PLAYING=0
                    show_playlist
                elif [ -n "$CURRENT_TRACK" ]; then
                    mpv_command '["set_property", "pause", false]'
                    IS_PLAYING=1
                    show_playlist
                fi
                ;;
            n)
                next_index=$(get_next_track)
                if [ $next_index -ge 0 ]; then
                    CURRENT_INDEX=$next_index
                    play_music "${PLAYLIST[$CURRENT_INDEX]}"
                fi
                ;;
            b)
                prev_index=$(get_previous_track)
                if [ $prev_index -ge 0 ]; then
                    CURRENT_INDEX=$prev_index
                    play_music "${PLAYLIST[$CURRENT_INDEX]}"
                fi
                ;;
            r)
                REPEAT_MODE=$((1 - REPEAT_MODE))
                if [ $REPEAT_MODE -eq 1 ]; then
                    echo -e "\n${GREEN}Repeat: On${NC}"
                else
                    echo -e "\n${YELLOW}Repeat: Off${NC}"
                fi
                ;;
            s)
                SHUFFLE_MODE=$((1 - SHUFFLE_MODE))
                if [ $SHUFFLE_MODE -eq 1 ]; then
                    echo -e "\n${GREEN}Shuffle: On${NC}"
                else
                    echo -e "\n${YELLOW}Shuffle: Off${NC}"
                fi
                ;;
            v)
                show_playlist
                ;;
            h)
                show_controls
                ;;
            f)
                load_folder
                ;;
            u)
                echo -e "\n${YELLOW}Enter Soundcloud URL:${NC}"
                read soundcloud_url
                add_soundcloud "$soundcloud_url"
                ;;
            o)
                load_online_url_or_m3u
                ;;
            +)
                mpv_command '["add", "volume", 5]'
                ;;
            -)
                mpv_command '["add", "volume", -5]'
                ;;
            c)
                PLAYLIST=()
                PLAYLIST_TITLES=()
                echo -e "\n${YELLOW}Playlist cleared${NC}"
                ;;
            q)
                echo -e "\n${YELLOW}Goodbye!${NC}"
                pkill -f "mpv --no-video --input-ipc-server=/tmp/mpvsocket"
                rm -f /tmp/mpvsocket
                exit 0
                ;;
        esac
    done
}

# Start the player
main
