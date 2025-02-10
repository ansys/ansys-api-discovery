#!/bin/bash

# Ensure the script exits if any command fails
set -e

# Check if one argument is passed
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <bump-type>"
    echo "<bump-type>: 'minor' or 'major'"
    exit 1
fi

# Assign the argument to a variable
BUMP_TYPE=$1

if [[ "$BUMP_TYPE" != "minor" && "$BUMP_TYPE" != "major" ]]; then
    echo "Error: Bump type must be 'minor' or 'major'."
    exit 1
fi

# Checkout main branch
git checkout main

# Pull the latest changes
git pull

# File containing the version
VERSION_FILE="ansys/api/discovery/VERSION"

if [ ! -f "$VERSION_FILE" ]; then
    echo "Error: VERSION file not found at $VERSION_FILE"
    exit 1
fi

# Extract the current version
CURRENT_DEV_VERSION=$(cat "$VERSION_FILE")
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_DEV_VERSION"

# Calculate new version for release and development
if [ "$BUMP_TYPE" == "major" ]; then
    # VERSION file on main:       0.2.dev0
    # New release VERSION file:   1.0.0
    # New dev VERSION file:       1.1.dev0
    NEW_RELEASE_VERSION="$((MAJOR + 1)).0.0"
    NEW_DEV_VERSION="$((MAJOR + 1)).1.dev0"
    NEW_RELEASE_BRANCH="release/$((MAJOR + 1)).0"
elif [ "$BUMP_TYPE" == "minor" ]; then
    # VERSION file on main:       0.2.dev0
    # New release VERSION file:   0.2.0
    # New dev VERSION file:       0.3.dev0
    NEW_RELEASE_VERSION="$MAJOR.$MINOR.0"
    NEW_DEV_VERSION="$MAJOR.$((MINOR + 1)).dev0"
    NEW_RELEASE_BRANCH="release/$MAJOR.$MINOR"
fi

# Create the release branch and bump the release version
git checkout -b "$NEW_RELEASE_BRANCH"
echo "$NEW_RELEASE_VERSION" > "$VERSION_FILE"
git add "$VERSION_FILE"
git commit -m "release: v$NEW_RELEASE_VERSION"

# Push the release branch
git push origin "$NEW_RELEASE_BRANCH"

# Tag the release
git tag "v$NEW_RELEASE_VERSION"
git push origin "v$NEW_RELEASE_VERSION"

# Return to main and bump the dev version
git checkout main
echo "$NEW_DEV_VERSION" > "$VERSION_FILE"
git add "$VERSION_FILE"
git commit -m "chore: bump dev version to $NEW_DEV_VERSION"

# Push the changes to main
git push origin main

echo "Release branch '$NEW_RELEASE_BRANCH' created with version $NEW_RELEASE_VERSION."
echo "Main branch bumped to development version $NEW_DEV_VERSION."
