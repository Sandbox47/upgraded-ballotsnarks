#!/bin/bash

# Ensure the script is run inside a Git repository
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: This script must be run inside a Git repository."
    exit 1
fi

# Generate a list of ignored files using git check-ignore
IGNORED_FILES=$(git ls-files --ignored --exclude-standard -o)

# Check if there are any ignored files
if [ -z "$IGNORED_FILES" ]; then
    echo "No ignored files found."
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