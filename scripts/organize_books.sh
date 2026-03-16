#!/bin/bash

# ============================================
# Book Organizer Script for chaos-creation
# Moves and renames books from ~/Downloads
# to /mnt/media/books with correct format
# ============================================

DOWNLOADS_DIR="$HOME/Downloads"
BOOKS_DIR="/mnt/media/books"
SUPPORTED_FORMATS=("epub" "pdf" "cbz" "cbr" "m4b" "mp3")

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "================================================"
echo "   📚 Book Organizer - chaos-creation"
echo "================================================"

clean_name() {
    local filename="$1"
    local name="${filename%.*}"

    # Replace dots and underscores with spaces
    name=$(echo "$name" | sed 's/[._]/ /g')

    # Remove common tags
    name=$(echo "$name" | sed 's/\[.*\]//g')
    name=$(echo "$name" | sed 's/(epub)//gi')
    name=$(echo "$name" | sed 's/(pdf)//gi')
    name=$(echo "$name" | sed 's/retail//gi')
    name=$(echo "$name" | sed 's/ebook//gi')
    name=$(echo "$name" | sed 's/[-]*$//g')
    name=$(echo "$name" | sed 's/  */ /g')
    name=$(echo "$name" | sed 's/^ //;s/ $//')

    echo "$name"
}

extract_year() {
    local filename="$1"
    local year=$(echo "$filename" | grep -oP '(19|20)\d{2}' | head -1)
    echo "$year"
}

get_category() {
    local extension="$1"
    case "$extension" in
        epub|pdf)
            echo "Books"
            ;;
        cbz|cbr)
            echo "Comics"
            ;;
        mp3|m4b)
            echo "Audiobooks"
            ;;
        *)
            echo "Books"
            ;;
    esac
}

process_book() {
    local filepath="$1"
    local filename=$(basename "$filepath")
    local extension="${filename##*.}"
    local category=$(get_category "$extension")

    echo ""
    echo -e "${YELLOW}Processing:${NC} $filename"
    echo -e "${YELLOW}Type:${NC} $category"

    local cleaned=$(clean_name "$filename")
    local year=$(extract_year "$filename")

    echo -e "${GREEN}Book name:${NC} $cleaned"

    # Ask for details
    read -p "Is the book name correct? (y/n/custom): " confirm

    if [ "$confirm" == "n" ]; then
        read -p "Enter correct book title: " cleaned
    elif [ "$confirm" == "custom" ]; then
        read -p "Enter full book title: " cleaned
    fi

    # Ask for author
    read -p "Enter author name (or press Enter to skip): " author

    # Ask for category
    echo "Categories: 1) Books  2) Comics  3) Audiobooks  4) Custom"
    read -p "Select category (1-4) [default: $category]: " cat_choice

    case "$cat_choice" in
        1) category="Books" ;;
        2) category="Comics" ;;
        3) category="Audiobooks" ;;
        4) read -p "Enter custom category: " category ;;
        *) ;; # keep default
    esac

    # Build destination path
    if [ ! -z "$author" ]; then
        local dest_dir="$BOOKS_DIR/$category/$author"
    else
        local dest_dir="$BOOKS_DIR/$category"
    fi

    # Add year if available
    if [ ! -z "$year" ]; then
        local dest_file="$dest_dir/$cleaned ($year).$extension"
    else
        local dest_file="$dest_dir/$cleaned.$extension"
    fi

    mkdir -p "$dest_dir"
    mv "$filepath" "$dest_file"
    chmod 644 "$dest_file"
    chmod 755 "$dest_dir"

    echo -e "${GREEN}✅ Moved to:${NC} $dest_file"
}

# Fix permissions on existing books
echo ""
echo "🔧 Fixing permissions on existing books..."
find "$BOOKS_DIR" -type f -exec chmod 644 {} \;
find "$BOOKS_DIR" -type d -exec chmod 755 {} \;
chown -R shunya:shunya "$BOOKS_DIR" 2>/dev/null
echo -e "${GREEN}✅ Permissions fixed${NC}"

# Find book files in Downloads
echo ""
echo "🔍 Scanning Downloads folder for books..."
found=0

for ext in "${SUPPORTED_FORMATS[@]}"; do
    while IFS= read -r -d '' file; do
        found=$((found + 1))
        process_book "$file"
    done < <(find "$DOWNLOADS_DIR" -maxdepth 3 -name "*.${ext}" -print0 2>/dev/null)
done

if [ $found -eq 0 ]; then
    echo -e "${YELLOW}No book files found in $DOWNLOADS_DIR${NC}"
    echo -e "${YELLOW}Supported formats: epub, pdf, cbz, cbr, mp3, m4b${NC}"
fi

# Show final structure
echo ""
echo "================================================"
echo "   📁 Current Book Library"
echo "================================================"
tree "$BOOKS_DIR"

echo ""
echo "================================================"
echo -e "${GREEN}   ✅ Done! Trigger Jellyfin scan to update library${NC}"
echo "================================================"
