#!/bin/bash

# ============================================
# Media Organizer Script for chaos-creation
# Moves and renames movies from ~/Downloads
# to /mnt/media/movies with correct format
# ============================================

DOWNLOADS_DIR="$HOME/Downloads"
MOVIES_DIR="/mnt/media/movies"
SUPPORTED_FORMATS=("mkv" "mp4" "avi" "mov")

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "================================================"
echo "   🎬 Media Organizer - chaos-creation"
echo "================================================"

# Function to clean filename
clean_name() {
    local filename="$1"
    
    # Remove extension
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
    name=$(echo "$name" | sed 's/HDRip//gi')
    name=$(echo "$name" | sed 's/BRRip//gi')
    name=$(echo "$name" | sed 's/x264//gi')
    name=$(echo "$name" | sed 's/x265//gi')
    name=$(echo "$name" | sed 's/HEVC//gi')
    name=$(echo "$name" | sed 's/AAC[0-9.]*//gi')
    name=$(echo "$name" | sed 's/DD[0-9.]*//gi')
    name=$(echo "$name" | sed 's/DTS//gi')
    name=$(echo "$name" | sed 's/\[.*\]//g')
    name=$(echo "$name" | sed 's/(.*YTS.*)//gi')
    name=$(echo "$name" | sed 's/  */ /g')
    name=$(echo "$name" | sed 's/^ //;s/ $//')
    
    echo "$name"
}

# Function to extract year from filename
extract_year() {
    local filename="$1"
    # Look for 4 digit year between 1900-2099
    local year=$(echo "$filename" | grep -oP '(19|20)\d{2}' | head -1)
    echo "$year"
}

# Function to process a movie file
process_movie() {
    local filepath="$1"
    local filename=$(basename "$filepath")
    local extension="${filename##*.}"

    echo ""
    echo -e "${YELLOW}Processing:${NC} $filename"

    # Clean the name
    local cleaned=$(clean_name "$filename")
    local year=$(extract_year "$filename")

    # Remove year from cleaned name if found
    if [ ! -z "$year" ]; then
        cleaned=$(echo "$cleaned" | sed "s/$year//g" | sed 's/  */ /g' | sed 's/^ //;s/ $//')
        local movie_name="$cleaned ($year)"
    else
        # No year found ask user
        echo -e "${YELLOW}No year found for:${NC} $cleaned"
        read -p "Enter year (or press Enter to skip): " year
        if [ ! -z "$year" ]; then
            local movie_name="$cleaned ($year)"
        else
            local movie_name="$cleaned"
        fi
    fi

    echo -e "${GREEN}Movie name:${NC} $movie_name"
    read -p "Is this correct? (y/n/custom): " confirm

    if [ "$confirm" == "n" ]; then
        read -p "Enter correct name (without year): " custom_name
        read -p "Enter year: " custom_year
        movie_name="$custom_name ($custom_year)"
    elif [ "$confirm" == "custom" ]; then
        read -p "Enter full movie name with year e.g. 'Movie Name (2024)': " movie_name
    fi

    # Create directory and move file
    local dest_dir="$MOVIES_DIR/$movie_name"
    local dest_file="$dest_dir/$movie_name.$extension"

    mkdir -p "$dest_dir"
    mv "$filepath" "$dest_file"

    # Fix permissions
    chmod 644 "$dest_file"
    chmod 755 "$dest_dir"

    echo -e "${GREEN}✅ Moved to:${NC} $dest_file"
}

# Fix permissions on existing movies
echo ""
echo "🔧 Fixing permissions on existing movies..."
find "$MOVIES_DIR" -type f -exec chmod 644 {} \;
find "$MOVIES_DIR" -type d -exec chmod 755 {} \;
chown -R shunya:shunya "$MOVIES_DIR"
echo -e "${GREEN}✅ Permissions fixed${NC}"

# Find movie files in Downloads
echo ""
echo "🔍 Scanning Downloads folder..."
found=0

for ext in "${SUPPORTED_FORMATS[@]}"; do
    while IFS= read -r -d '' file; do
        found=$((found + 1))
        process_movie "$file"
    done < <(find "$DOWNLOADS_DIR" -maxdepth 2 -name "*.${ext}" -print0 2>/dev/null)
done

if [ $found -eq 0 ]; then
    echo -e "${YELLOW}No movie files found in $DOWNLOADS_DIR${NC}"
fi

# Show final structure
echo ""
echo "================================================"
echo "   📁 Current Movie Library"
echo "================================================"
tree "$MOVIES_DIR"

echo ""
echo "================================================"
echo -e "${GREEN}   ✅ Done! Trigger Jellyfin scan to update library${NC}"
echo "================================================"


