#!/bin/bash

# MTSP - Music Terminal Shell Player
# Version: 0.3.8
# Dependencies: mpv, socat, jq, youtube-dl (for Soundcloud support)
# Requires: fzf (for interactive file browsing)

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

# Main radio stations
RADIO_URLS=(
    "http://178.33.135.244:20095/"
    "https://audio.nrpstream.com/listen/nogoumfm/radio.mp3"
    "https://n09.radiojar.com/8s5u5tpdtwzuv"
)
RADIO_NAMES=(
    "Tes3enat FM"
    "Nogoum FM"
    "Cairo Q FM"
)

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
    echo "Music Terminal Shell Player v0.3.8"
    echo "--------------------------------"
}

# Function to display controls
show_controls() {
    echo -e "\n${BOLD}Controls:${NC}"
    echo "1 - Play Tes3enat FM         2 - Play Nogoum FM         3 - Play Cairo Q FM"
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
    echo "m - Browse files interactively"
}

# Function to check dependencies
check_dependencies() {
    local missing_deps=0
    for cmd in mpv socat jq youtube-dl fzf; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${RED}Error: $cmd is not installed${NC}"
            missing_deps=1
        fi
    done
    
    if [ $missing_deps -eq 1 ]; then
        echo -e "${YELLOW}Please install missing dependencies:${NC}"
        echo "sudo apt-get install mpv socat jq youtube-dl fzf"
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
    
    # تشغيل الأغنية التالية تلقائياً عند الانتهاء
    ( 
        while true; do
            sleep 1
            if ! pgrep -f "mpv --no-video --input-ipc-server=/tmp/mpvsocket" > /dev/null; then
                next_index=$(get_next_track)
                if [ "$next_index" -ge 0 ] && [ "$next_index" -ne "$CURRENT_INDEX" ]; then
                    CURRENT_INDEX=$next_index
                    play_music "${PLAYLIST[$CURRENT_INDEX]}"
                fi
                break
            fi
        done
    ) &
}

# Function to browse files interactively
browse_files() {
    local start_dir="/"
    local current_dir="$start_dir"
    while true; do
        # بناء قائمة بسيطة: اسم ظاهر مع أيقونة فقط + مسار كامل
        declare -A path_map
        local items=()
        while IFS= read -r entry; do
            local base="$(basename "$entry")"
            if [ -d "$entry" ]; then
                items+=("📁 $base")
                path_map["📁 $base"]="$entry"
            elif [[ "$entry" == *.m3u || "$entry" == *.m3u8 ]]; then
                items+=("📄 $base")
                path_map["📄 $base"]="$entry"
            elif [[ "$entry" == *.mp3 || "$entry" == *.wav || "$entry" == *.flac || "$entry" == *.m4a || "$entry" == *.ogg ]]; then
                items+=("🎵 $base")
                path_map["🎵 $base"]="$entry"
            fi
        done < <(find "$current_dir" -maxdepth 1 -mindepth 1 \( -type d -o -type f \( -iname "*.mp3" -o -iname "*.wav" -o -iname "*.flac" -o -iname "*.m4a" -o -iname "*.ogg" -o -iname "*.m3u" -o -iname "*.m3u8" \) \) 2>/dev/null | sort)
        # أضف خيار العودة للخلف إذا لم تكن في الجذر
        if [ "$current_dir" != "/" ]; then
            items=(".." "${items[@]}")
            path_map[".."]=".."
        fi
        # استخدم fzf للاستعراض المتعدد
        local selected=$(printf '%s\n' "${items[@]}" | fzf --multi --prompt="Browse: $current_dir > ")
        [ -z "$selected" ] && echo -e "${YELLOW}No selection.${NC}" && return
        # إذا اختار العودة للخلف فقط
        if [ "$selected" = ".." ]; then
            current_dir="$(dirname "$current_dir")"
            continue
        fi
        # إذا اختار عنصر واحد فقط وهو مجلد، ادخل إليه
        if [ $(echo "$selected" | wc -l) -eq 1 ] && [ "${path_map[$selected]}" != "" ] && [ -d "${path_map[$selected]}" ]; then
            current_dir="${path_map[$selected]}"
            continue
        fi
        # معالجة كل اختيار
        local all_files=()
        while IFS= read -r entry; do
            local realpath="${path_map[$entry]}"
            if [ "$realpath" = ".." ]; then
                continue
            elif [ -d "$realpath" ]; then
                while IFS= read -r f; do
                    all_files+=("$f")
                done < <(find "$realpath" -type f \( -iname "*.mp3" -o -iname "*.wav" -o -iname "*.flac" -o -iname "*.m4a" -o -iname "*.ogg" \) 2>/dev/null)
            elif [[ "$realpath" == *.m3u || "$realpath" == *.m3u8 ]]; then
                while IFS= read -r m3uline; do
                    [[ "$m3uline" =~ ^#.*$ || -z "$m3uline" ]] && continue
                    all_files+=("$m3uline")
                done < "$realpath"
            elif [ -f "$realpath" ]; then
                all_files+=("$realpath")
            fi
        done <<< "$selected"
        if [ ${#all_files[@]} -eq 0 ]; then
            echo -e "${YELLOW}No playable files found.${NC}"
            return
        fi
        PLAYLIST=("${all_files[@]}")
        PLAYLIST_TITLES=()
        for f in "${PLAYLIST[@]}"; do
            PLAYLIST_TITLES+=("$(basename "$f")")
        done
        CURRENT_INDEX=0
        play_music "${PLAYLIST[0]}"
        return
    done
}

# دالة استعراض وتحميل ملفات البلايليست m3u/m3u8
load_playlist_fzf() {
    local selected
    selected=$(find / -mount -type f \( -iname "*.m3u" -o -iname "*.m3u8" \) 2>/dev/null | fzf --multi --prompt="Select playlist(s): ")
    [ -z "$selected" ] && echo -e "${YELLOW}No playlist selected.${NC}" && return
    local all_tracks=()
    while IFS= read -r m3u; do
        while IFS= read -r line; do
            [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
            all_tracks+=("$line")
        done < "$m3u"
    done <<< "$selected"
    if [ ${#all_tracks[@]} -eq 0 ]; then
        echo -e "${YELLOW}No tracks found in playlist(s).${NC}"
        return
    fi
    PLAYLIST=("${all_tracks[@]}")
    PLAYLIST_TITLES=()
    for f in "${PLAYLIST[@]}"; do
        PLAYLIST_TITLES+=("$(basename "$f")")
    done
    CURRENT_INDEX=0
    play_music "${PLAYLIST[0]}"
}

# دالة إضافة ملفات موسيقية إلى قائمة التشغيل
add_files_fzf() {
    local selected
    selected=$(find / -mount -type f \( -iname "*.mp3" -o -iname "*.wav" -o -iname "*.flac" -o -iname "*.m4a" -o -iname "*.ogg" \) 2>/dev/null | fzf --multi --prompt="Select music file(s): ")
    [ -z "$selected" ] && echo -e "${YELLOW}No files selected.${NC}" && return
    local new_files=()
    while IFS= read -r file; do
        new_files+=("$file")
    done <<< "$selected"
    if [ ${#new_files[@]} -eq 0 ]; then
        echo -e "${YELLOW}No valid files selected.${NC}"
        return
    fi
    PLAYLIST+=("${new_files[@]}")
    for f in "${new_files[@]}"; do
        PLAYLIST_TITLES+=("$(basename "$f")")
    done
    # إذا كانت قائمة التشغيل كانت فارغة قبل الإضافة، شغل أول ملف
    if [ ${#PLAYLIST[@]} -eq ${#new_files[@]} ]; then
        CURRENT_INDEX=0
        play_music "${PLAYLIST[0]}"
    else
        echo -e "${GREEN}Added ${#new_files[@]} file(s) to playlist.${NC}"
        show_playlist
    fi
}

# Main loop
main() {
    check_dependencies
    show_banner
    show_controls
    local menu_index=0
    local menu_items=("Tes3enat FM" "Nogoum FM" "Cairo Q FM")
    while true; do
        read -rsn1 key
        case "$key" in
            1)
                PLAYLIST=("${RADIO_URLS[0]}")
                PLAYLIST_TITLES=("${RADIO_NAMES[0]}")
                CURRENT_INDEX=0
                play_music "${RADIO_URLS[0]}"
                ;;
            2)
                PLAYLIST=("${RADIO_URLS[1]}")
                PLAYLIST_TITLES=("${RADIO_NAMES[1]}")
                CURRENT_INDEX=0
                play_music "${RADIO_URLS[1]}"
                ;;
            3)
                PLAYLIST=("${RADIO_URLS[2]}")
                PLAYLIST_TITLES=("${RADIO_NAMES[2]}")
                CURRENT_INDEX=0
                play_music "${RADIO_URLS[2]}"
                ;;
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
            m)
                browse_files
                ;;
            l)
                load_playlist_fzf
                ;;
            a)
                add_files_fzf
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
