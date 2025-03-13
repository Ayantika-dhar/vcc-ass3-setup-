#!/bin/bash

echo "🚀 Updating system package list..."
sudo apt update -y

echo "📦 Installing prerequisites..."
sudo apt install -y curl software-properties-common

echo "🔍 Checking if Node.js is already installed..."
if command -v node > /dev/null 2>&1; then
    echo "✅ Node.js is already installed. Version: $(node -v)"
    exit 0
fi

echo "🌍 Adding Node.js 16.x LTS repository..."
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -

echo "⬇️ Installing Node.js and npm..."
sudo apt install -y nodejs

echo "🔍 Verifying installation..."
node -v
npm -v

echo "✅ Node.js and npm installed successfully!"
