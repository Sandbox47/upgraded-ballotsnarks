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

# If there is an exclusion file, filter out those files
# If there is an exclusion file, filter out those files
if [[ -f "$EXCLUSION_FILE" ]]; then
    echo "Using $EXCLUSION_FILE to exclude specific files."

    # Convert .gitkeep patterns to proper regex
    EXCLUDE_REGEX=$(sed 's/\./\\./g; s/\*/.*/g' "$EXCLUSION_FILE")

    # Filter ignored files using regex
    IGNORED_FILES=$(echo "$IGNORED_FILES" | grep -vE "$EXCLUDE_REGEX")
fi


# Check if there are any remaining files to delete
if [ -z "$IGNORED_FILES" ]; then
    echo "No ignored files found to delete."
    exit 0
fi

# Print files to be deleted
echo "The following ignored files will be deleted:"
echo "$IGNORED_FILES"

# Ask for confirmation
read -p "Are you sure you want to delete these files? (y/N) " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Aborting."
    exit 0
fi

# Delete the ignored files
echo "$IGNORED_FILES" | xargs rm -rf

echo "Ignored files deleted successfully."