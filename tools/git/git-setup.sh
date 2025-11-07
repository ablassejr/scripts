#!/bin/bash
set -e

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "Error: git is not installed. Please install git first."
    exit 1
fi

git config --global user.email "ablassecode@outlook.com"
git config --global user.name "Ablasse Kingcaid-Ouedraogo"
git config --global push.autoSetupRemote true
git config --global branch.autoSetupMerge simple

echo "Git configuration completed successfully!"
