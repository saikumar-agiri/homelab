#!/bin/bash

# ============================================
# TV Show Organizer Script for chaos-creation
# Moves and renames TV shows from ~/Downloads
# to /mnt/media/tvshows with correct format
# ============================================

DOWNLOADS_DIR="$HOME/Downloads"
TVSHOWS_DIR="/mnt/media/tvshows"
SUPPORTED_FORMATS=("mkv" "mp4" "avi" "mov")

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "================================================"
echo "   📺 TV Show Organizer - chaos-creation"
echo "================================================"

# Function to clean show name
clean_name() {
    local filename="$1"
    local name="${filename%.*}"

    # Replace dots and underscores with spaces
    name=$(echo "$name" | sed 's/[._]/ /g')

    # Remove common torrent tags
    name=$(echo "$name" | sed 's/1080p//gi')
    name=$(echo "$name" | sed 's/720p//gi')
    name=$(echo "$name" | sed 's/4K//gi')
    name=$(echo "$name" | sed 's/2160p//gi')
    name=$(echo "$name" | sed 's/BluRay//gi')
    name=$(echo "$name" | sed 's/WEBRip//gi')
    name=$(echo "$name" | sed 's/WEB-DL//gi')
    name=$(echo "$name" | sed 's/HDTV//gi')
    name=$(echo "$name" | sed 's/HDRip//gi')
    name=$(echo "$name" | sed 's/BRRip//gi')
    name=$(echo "$name" | sed 's/x264//gi')
    name=$(echo "$name" | sed 's/x265//gi')
    name=$(echo "$name" | sed 's/HEVC//gi')
    name=$(echo "$name" | sed 's/AAC[^ ]*//gi')
    name=$(echo "$name" | sed 's/DD[0-9.]*//gi')
    name=$(echo "$name" | sed 's/DTS//gi')
    name=$(echo "$name" | sed 's/YIFY//gi')
    name=$(echo "$name" | sed 's/YTS[^ ]*//gi')
    name=$(echo "$name" | sed 's/\[.*\]//g')

    # Remove trailing dashes and spaces
    name=$(echo "$name" | sed 's/[-]*$//g')
    name=$(echo "$name" | sed 's/  */ /g')
    name=$(echo "$name" | sed 's/^ //;s/ $//')

    echo "$name"
}

# Function to extract season and episode
extract_season_episode() {
    local filename="$1"
    # Match S01E01 or s01e01 pattern
    local se=$(echo "$filename" | grep -oiP 'S\d{2}E\d{2}' | head -1 | tr '[:lower:]' '[:upper:]')
    echo "$se"
}

extract_season() {
    local se="$1"
    # Extract season number e.g S01 → 01
    echo "$se" | grep -oP '\d{2}' | head -1
}

extract_episode() {
    local se="$1"
    # Extract episode number e.g E01 → 01
    echo "$se" | grep -oP '\d{2}' | tail -1
}

extract_year() {
    local filename="$1"
    local year=$(echo "$filename" | grep -oP '(19|20)\d{2}' | head -1)
    echo "$year"
}

# Function to clean show name (remove S01E01 and everything after)
extract_show_name() {
    local filename="$1"
    local name="${filename%.*}"

    # Remove everything from SxxExx onwards
    name=$(echo "$name" | sed 's/[Ss][0-9][0-9][Ee][0-9][0-9].*//')

    # Replace dots and underscores with spaces
    name=$(echo "$name" | sed 's/[._]/ /g')

    # Trim
    name=$(echo "$name" | sed 's/  */ /g' | sed 's/^ //;s/ $//')

    echo "$name"
}

# Function to process a TV show file
process_episode() {
    local filepath="$1"
    local filename=$(basename "$filepath")
    local extension="${filename##*.}"

    echo ""
    echo -e "${YELLOW}Processing:${NC} $filename"

    # Extract info
    local se=$(extract_season_episode "$filename")
    local show_name=$(extract_show_name "$filename")
    local year=$(extract_year "$filename")

    if [ -z "$se" ]; then
        echo -e "${RED}Could not detect Season/Episode pattern (SxxExx)${NC}"
        read -p "Enter Season number (e.g 01): " season_num
        read -p "Enter Episode number (e.g 01): " episode_num
        se="S${season_num}E${episode_num}"
    fi

    local season_num=$(extract_season "$se")
    local season_folder="Season ${season_num}"

    echo -e "${GREEN}Show name:${NC} $show_name"
    echo -e "${GREEN}Season/Episode:${NC} $se"

    # Confirm show name
    read -p "Is the show name correct? (y/n/custom): " confirm

    if [ "$confirm" == "n" ]; then
        read -p "Enter correct show name: " show_name
        read -p "Enter year (optional, press Enter to skip): " year
    elif [ "$confirm" == "custom" ]; then
        read -p "Enter full show name: " show_name
        read -p "Enter year (optional, press Enter to skip): " year
    fi

    # Add year to show folder if available
    if [ ! -z "$year" ]; then
        local show_folder="$show_name ($year)"
    else
        local show_folder="$show_name"
    fi

    # Create directory structure
    local dest_dir="$TVSHOWS_DIR/$show_folder/$season_folder"
    local dest_file="$dest_dir/$show_name $se.$extension"

    mkdir -p "$dest_dir"
    mv "$filepath" "$dest_file"
    chmod 644 "$dest_file"
    chmod 755 "$dest_dir"
    chmod 755 "$TVSHOWS_DIR/$show_folder"

    echo -e "${GREEN}✅ Moved to:${NC} $dest_file"
}

# Fix permissions on existing shows
echo ""
echo "🔧 Fixing permissions on existing TV shows..."
find "$TVSHOWS_DIR" -type f -exec chmod 644 {} \;
find "$TVSHOWS_DIR" -type d -exec chmod 755 {} \;
chown -R shunya:shunya "$TVSHOWS_DIR" 2>/dev/null
echo -e "${GREEN}✅ Permissions fixed${NC}"

# Find TV show files in Downloads including subdirectories
echo ""
echo "🔍 Scanning Downloads folder for TV shows..."
found=0

for ext in "${SUPPORTED_FORMATS[@]}"; do
    while IFS= read -r -d '' file; do
        filename=$(basename "$file")
        # Only process files with SxxExx pattern
        if echo "$filename" | grep -qiP 'S\d{2}E\d{2}'; then
            found=$((found + 1))
            process_episode "$file"
        fi
    done < <(find "$DOWNLOADS_DIR" -maxdepth 3 -name "*.${ext}" -print0 2>/dev/null)
done

if [ $found -eq 0 ]; then
    echo -e "${YELLOW}No TV show files found in $DOWNLOADS_DIR${NC}"
    echo -e "${YELLOW}Make sure files have SxxExx pattern e.g Breaking.Bad.S01E01.mkv${NC}"
fi

# Show final structure
echo ""
echo "================================================"
echo "   📁 Current TV Show Library"
echo "================================================"
tree "$TVSHOWS_DIR"

echo ""
echo "================================================"
echo -e "${GREEN}   ✅ Done! Trigger Jellyfin scan to update library${NC}"
echo "================================================"
