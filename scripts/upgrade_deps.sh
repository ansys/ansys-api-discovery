#!/bin/bash

# Ensure the script exits if any command fails
set -e

# Check if one argument is passed
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <package-name>"
    echo "Example: $0 ansys-api-geometry"
    exit 1
fi

# Assign the argument to a variable
PACKAGE_NAME=$1

echo "Upgrading $PACKAGE_NAME to latest version..."

# Check if curl and jq are available
if ! command -v curl &> /dev/null; then
    echo "Error: curl is required but not installed"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed"
    exit 1
fi

# Check if the package exists on PyPI and get latest version
echo "Fetching latest version from PyPI..."
LATEST_VERSION=$(curl -s "https://pypi.org/pypi/$PACKAGE_NAME/json" | jq -r '.info.version')

if [ $? -ne 0 ]; then
    echo "Error: Failed to fetch package info from PyPI"
    exit 1
fi

if [ "$LATEST_VERSION" == "null" ] || [ -z "$LATEST_VERSION" ]; then
    echo "Error: Could not find version for package $PACKAGE_NAME"
    echo "Please check that the package name is correct and exists on PyPI"
    exit 1
fi

echo "Latest version found: $LATEST_VERSION"

# Files to update - with respect to this script file location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYPROJECT_FILE="$SCRIPT_DIR/../pyproject.toml"
SETUP_FILE="$SCRIPT_DIR/../setup.py"

# Update pyproject.toml
echo "Updating $PYPROJECT_FILE..."
# Use sed to replace the package version in pyproject.toml
# This handles both == and >= patterns
sed -i.tmp "s/\"$PACKAGE_NAME[=<>!]*[0-9.]*\"/\"$PACKAGE_NAME==$LATEST_VERSION\"/g" "$PYPROJECT_FILE"
rm -f "$PYPROJECT_FILE.tmp"

# Update setup.py
echo "Updating $SETUP_FILE..."
# Use sed to replace the package version in setup.py
# This handles both == and >= patterns in the install_requires list
sed -i.tmp "s/\"$PACKAGE_NAME[=<>!]*[0-9.]*\"/\"$PACKAGE_NAME==$LATEST_VERSION\"/g" "$SETUP_FILE"
rm -f "$SETUP_FILE.tmp"

# Verify changes
echo ""
echo "Changes made:"
echo "============="

echo ""
echo "In $PYPROJECT_FILE:"
grep "$PACKAGE_NAME" "$PYPROJECT_FILE" || echo "Package not found in $PYPROJECT_FILE"

echo ""
echo "In $SETUP_FILE:"
grep "$PACKAGE_NAME" "$SETUP_FILE" || echo "Package not found in $SETUP_FILE"

echo ""
echo "Upgrade completed successfully!"
echo "Package $PACKAGE_NAME has been updated to version $LATEST_VERSION"

# Submit a pull request with the changes - create a branch, commit, push, and open PR
# Only if there are changes to commit
if git diff --quiet "$PYPROJECT_FILE" "$SETUP_FILE"; then
    echo "No changes detected in $PYPROJECT_FILE or $SETUP_FILE. Exiting without creating a PR."
    exit 0
else
    echo "Changes detected. Proceeding to create a pull request."
fi

BRANCH_NAME="upgrade/$PACKAGE_NAME-to-$LATEST_VERSION"
git checkout -b "$BRANCH_NAME"
git add "$PYPROJECT_FILE" "$SETUP_FILE"
git commit -m "build: upgrade $PACKAGE_NAME to $LATEST_VERSION"
git push origin "$BRANCH_NAME"

# Create the pull request
gh pr create --title "build: upgrade $PACKAGE_NAME to $LATEST_VERSION" --body "This PR upgrades $PACKAGE_NAME to version $LATEST_VERSION." --head "$BRANCH_NAME" --base main
if [ $? -ne 0 ]; then
    echo "Error: Failed to create pull request"
    exit 1
else
    echo "Pull request created successfully."
fi