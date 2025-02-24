#!/bin/bash

# Exit if any command fails
set -e

# Check if a version argument is provided
if [ -z "$1" ]; then
    echo "Error: Please provide a version number (e.g., 1.0.0)"
    exit 1
fi

NEW_VERSION=$1

# Validate version format (simple check)
if ! [[ $NEW_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must be in format X.Y.Z (e.g., 1.0.0)"
    exit 1
fi

# Ensure we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "Error: Must be on main branch to publish"
    exit 1
fi

# Ensure working directory is clean
if [ -n "$(git status --porcelain)" ]; then
    echo "Error: Working directory is not clean. Please commit or stash changes."
    exit 1
fi

# Pull latest changes
echo "Pulling latest changes from main..."
git pull origin main

# Run tests
echo "Running tests..."
./scripts/build-and-test.sh

# Create and push tag
echo "Creating and pushing tag v$NEW_VERSION..."
git tag "$NEW_VERSION"
git push origin "$NEW_VERSION"

echo "✨ Successfully published version $NEW_VERSION!"
echo "Package can now be used with: "
echo ".package(url: \"$(git config --get remote.origin.url)\", from: \"$NEW_VERSION\")," 