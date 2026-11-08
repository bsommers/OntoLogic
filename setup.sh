#!/bin/bash
set -euo pipefail

# setup.sh - Install dependencies for OntoLogic

# Display the sick logo from logo.txt with Cyan/Green gradient style colors
if [ -f "logo.txt" ]; then
    echo -e "\033[1;36m"
    cat logo.txt
    echo -e "\033[0m\033[1;32m"
    echo "       OntoLogic: Logic as Code for the IoT Edge      "
    echo -e "\033[0m"
else
    echo "OntoLogic Setup"
fi

echo "Updating package lists..."
sudo apt-get update

echo "Installing haskell-stack and docker-compose..."
sudo apt-get install -y haskell-stack docker-compose

echo "Checking versions..."
stack --version
docker-compose --version

# --- SDKMAN Setup ---
if [ ! -d "$HOME/.sdkman" ]; then
    echo "Installing SDKMAN..."
    TMP_INSTALLER="$(mktemp /tmp/sdkman_install_XXXXXX.sh)"
    curl -sSL "https://get.sdkman.io" -o "$TMP_INSTALLER"
    bash "$TMP_INSTALLER"
    rm -f "$TMP_INSTALLER"
else
    echo "SDKMAN already installed."
fi

# Source SDKMAN
if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    echo "Installing Java 17..."
    sdk install java 17.0.9-tem 2>/dev/null || echo "Java 17 already installed or failed to install."
    echo "Installing Gradle..."
    sdk install gradle 8.4 2>/dev/null || echo "Gradle 8.4 already installed or failed to install."
fi

echo "Setup complete. Please run: source \"$HOME/.sdkman/bin/sdkman-init.sh\""
