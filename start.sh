#!/bin/bash

CONFIG_FILE=".ssh_settings"

# Function to get user input for port, user, host, and private key path
get_user_input() {
    read -p "Enter the port number for SOCKS proxy (default: 1080): " port
    port=${port:-1080}  # Default to 1080 if empty

    read -p "Enter the SSH username: " user
    while [[ -z "$user" ]]; do
        echo "Username cannot be empty."
        read -p "Enter the SSH username: " user
    done

    read -p "Enter the SSH host (IP or domain): " host
    while [[ -z "$host" ]]; do
        echo "Host cannot be empty."
        read -p "Enter the SSH host: " host
    done

    read -p "Enter the path to your private key (default: ~/.ssh/id_rsa): " key_path
    key_path=${key_path:-~/.ssh/id_rsa}  # Default to ~/.ssh/id_rsa if empty

    # Expand tilde (~) if used
    key_path=$(eval echo "$key_path")

    # Ensure the private key file exists
    if [ ! -f "$key_path" ]; then
        echo "Error: Private key file not found at '$key_path'."
        exit 1
    fi
}

# Check if configuration file exists
if [ -f "$CONFIG_FILE" ]; then
    # Read existing values
    source "$CONFIG_FILE"

    echo "Saved configuration:"
    echo "Port: $port"
    echo "User: $user"
    echo "Host: $host"
    echo "Key Path: $key_path"

    # Ask if user wants to use saved settings
    read -p "Use these settings? (y/n): " use_saved
    if [ "$use_saved" != "y" ]; then
        get_user_input
    fi
else
    get_user_input
fi

# Save settings
cat <<EOF > "$CONFIG_FILE"
port=$port
user=$user
host=$host
key_path=$key_path
EOF

# Check if autossh is installed
if ! command -v autossh &> /dev/null; then
    echo "Error: autossh is not installed. Please install it first."
    exit 1
fi

# Start autossh with SOCKS proxy
echo "Starting autossh with SOCKS proxy on port $port..."
autossh -M 0 -N -D "$port" -o "ServerAliveInterval 60" -o "ServerAliveCountMax 3" -i "$key_path" "$user@$host" &

echo "SOCKS proxy running on 127.0.0.1:$port"

