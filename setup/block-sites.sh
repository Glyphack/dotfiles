#!/bin/bash

# Define the path to the hosts file
HOSTS_FILE="/etc/hosts"

# List of default sites to block
DEFAULT_SITES=("x.com" "instagram.com")

# Function to block a website
block_site() {
    local site=$1
    echo "Blocking $site..."

    # Check if the site is already blocked
    if grep -q "127.0.0.1 $site" "$HOSTS_FILE"; then
        echo "$site is already blocked."
    else
        # Add entries to block the site and its www variant
        echo "127.0.0.1 $site" | sudo tee -a "$HOSTS_FILE" > /dev/null
        echo "127.0.0.1 www.$site" | sudo tee -a "$HOSTS_FILE" > /dev/null
        echo "$site has been blocked."
    fi
}

# Function to flush DNS cache
flush_dns() {
    echo "Flushing DNS cache..."
    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder
    echo "DNS cache flushed."
}

# Block default sites
for site in "${DEFAULT_SITES[@]}"; do
    block_site "$site"
done

# Block additional sites provided as arguments
for site in "$@"; do
    block_site "$site"
done

# Flush DNS cache to apply changes
flush_dns

echo "All specified sites have been blocked."

