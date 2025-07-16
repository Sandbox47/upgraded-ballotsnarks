#!/bin/bash

# Ensure the script is run inside a Git repository
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: This script must be run inside a Git repository."
    exit 1
fi

# Get the root directory of the Git repository
GIT_ROOT=$(git rev-parse --show-toplevel)

# Define the exclusion list file relative to the Git root
EXCLUSION_FILE="$GIT_ROOT/.gitkeep"

# Generate a list of ignored files
IGNORED_FILES=$(git ls-files --ignored --exclude-standard -o)

# Find directories that contain only ignored files or are empty
IGNORED_DIRS=$(find . -type d -not -path "./.git/*" | while read -r dir; do
    if [[ -z $(git check-ignore "$dir" 2>/dev/null) ]]; then
        continue  # Skip directories that are not ignored
    fi
    if [[ -z $(find "$dir" -type f 2>/dev/null) ]]; then
        echo "$dir"  # Only include if directory is empty or contains only ignored files
    fi
done)

# Merge files and directories into a single list
IGNORED_ITEMS="$IGNORED_FILES
$IGNORED_DIRS"

# If there is an exclusion file, filter out those files and directories
if [[ -f "$EXCLUSION_FILE" ]]; then
    echo "Using $EXCLUSION_FILE to exclude specific files and directories."
    
    # Convert .gitkeep patterns to proper regex
    EXCLUDE_REGEX=$(sed 's/\./\\./g; s/\*/.*/g' "$EXCLUSION_FILE")
    
    # Filter ignored items using regex
    IGNORED_ITEMS=$(echo "$IGNORED_ITEMS" | grep -vE "$EXCLUDE_REGEX")
fi

# Check if there are any remaining files or directories to delete
if [ -z "$IGNORED_ITEMS" ]; then
    echo "No ignored files or directories found to delete."
    exit 0
fi

# Print files and directories to be deleted
echo "The following ignored files and directories will be deleted:"
echo "$IGNORED_ITEMS"

# Ask for confirmation
read -p "Are you sure you want to delete these files and directories? (y/N) " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Aborting."
    exit 0
fi

# Delete the ignored files and directories
echo "$IGNORED_ITEMS" | xargs rm -rf

echo "Ignored files and directories deleted successfully."
