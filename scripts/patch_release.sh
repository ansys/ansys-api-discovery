#!/bin/bash

# Ensure the script exits if any command fails
set -e

# Checkout main branch
git checkout main

# Pull the latest changes
git pull

# Fetch all tags
git fetch --tags

# Get the latest release tag
LATEST_RELEASE=$(git tag --list "v*" --sort=-version:refname | head -n 1)

# Parse major and minor version numbers
if [[ "$LATEST_RELEASE" =~ ^v([0-9]+)\.([0-9]+)\.[0-9]+$ ]]; then
  MAJOR="${BASH_REMATCH[1]}"
  MINOR="${BASH_REMATCH[2]}"
  RELEASE_BRANCH="release/${MAJOR}.${MINOR}"
  echo "Latest release tag: $LATEST_RELEASE"
  echo "Associated release branch: $RELEASE_BRANCH"
else
  echo "Error: Unable to parse the latest release tag."
  exit 1
fi

# Checkout release branch
git checkout $RELEASE_BRANCH

# Merge the main branch
if ! git merge main --commit --no-edit; then
  # Check if there are merge conflicts
  if git status --porcelain | grep -q "^UU\|^AA\|^DD"; then
    # Check if VERSION file has conflicts
    if git status --porcelain | grep -q "^UU ansys/api/discovery/VERSION$"; then
      # Resolve VERSION file conflict by taking ours
      git checkout --ours ansys/api/discovery/VERSION
      git add ansys/api/discovery/VERSION
      
      # Check if there are other conflicts besides VERSION file
      if git status --porcelain | grep -q "^UU\|^AA\|^DD" | grep -v "ansys/api/discovery/VERSION"; then
        echo "Error: Merge conflicts detected in files other than VERSION. Please resolve manually."
        git merge --abort
        exit 1
      fi
      
      # Complete the merge
      git commit --no-edit
    else
      echo "Error: Merge conflicts detected. Please resolve manually."
      git merge --abort
      exit 1
    fi
  fi
fi

# Automatically bump the patch version (Y)
VERSION_FILE="ansys/api/discovery/VERSION"
if [ ! -f "$VERSION_FILE" ]; then
    echo "Error: VERSION file not found at $VERSION_FILE"
    exit 1
fi

# Extract current version and bump Y
CURRENT_VERSION=$(cat "$VERSION_FILE")
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
NEW_VERSION="$MAJOR.$MINOR.$((PATCH + 1))"

# Update the VERSION file
echo "$NEW_VERSION" > "$VERSION_FILE"

# Commit the release bump
git add "$VERSION_FILE"
git commit -m "release: v$NEW_VERSION"

# Push to origin
git push origin $RELEASE_BRANCH

# Tag the release
git tag "v$NEW_VERSION"
git push origin "v$NEW_VERSION"

# Checkout main again
git checkout main
