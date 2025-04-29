#!/bin/bash

# Configuration file (hidden in user's home directory)
CONFIG_DIR="$HOME/.ssh_settings"
SOCKS_DEFAULT_PORT=1080
SSH_DEFAULT_PORT=22 # Define default SSH port
KEY_DEFAULT_PATH="$HOME/.ssh/id_rsa"
SOCKS_BIND_ADDRESS="127.0.0.1" # Define bind address
CONFIG_FILE="$CONFIG_DIR/proxies.conf" # Store proxy list here
AUTOSSH_PIDS_FILE="$CONFIG_DIR/autossh_pids" # Store running autossh PIDs

# Function to display current configuration
display_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        echo "Current configuration:"
        echo "  Port: $port"
        echo "  User: $user"
        echo "  Host: $host"
        echo "  SSH Port: $ssh_port" # Show SSH Port
        echo "  Key Path: $key_path"
    else
        echo "No saved configuration found."
    fi
}

# Function to get user input for SSH settings
get_user_input() {
    read -p "Enter the port number for SOCKS proxy (default: $SOCKS_DEFAULT_PORT): " port
    port="${port:-$SOCKS_DEFAULT_PORT}"
    # Validate port number
    if [[ ! "$port" =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
        echo "Invalid port number. Using default: $SOCKS_DEFAULT_PORT"
        port="$SOCKS_DEFAULT_PORT"
    fi

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

    read -p "Enter the SSH port (default: $SSH_DEFAULT_PORT): " ssh_port
    ssh_port="${ssh_port:-$SSH_DEFAULT_PORT}"
    # Validate SSH port number
    if [[ ! "$ssh_port" =~ ^[0-9]+$ ]] || (( ssh_port < 1 || ssh_port > 65535 )); then
        echo "Invalid SSH port number. Using default: $SSH_DEFAULT_PORT"
        ssh_port="$SSH_DEFAULT_PORT"
    fi


    read -p "Enter the path to your private key (default: $KEY_DEFAULT_PATH): " key_path
    key_path="${key_path:-$KEY_DEFAULT_PATH}"

    # Expand tilde (~) if used - using standard parameter expansion
    key_path=$(echo "$key_path")

    # Ensure the private key file exists and has correct permissions
    if [ ! -f "$key_path" ]; then
        echo "Error: Private key file not found at '$key_path'."
        exit 1
    elif [[ ! -O "$key_path" ]]; then # Check if owned by the user.
        echo "Warning: Private key file '$key_path' is not owned by you. This might be a security risk."
    elif [[ $(stat -c "%a" "$key_path") != "600" && $(stat -c "%a" "$key_path") != "400" ]]; then
        echo "Warning: Private key file '$key_path' has incorrect permissions.  It should be 600 or 400."
    fi
}

# Function to save the configuration
save_config() {
    mkdir -p "$CONFIG_DIR" # Ensure the directory exists
    # Use a more descriptive filename like proxies.conf
    cat <<EOF > "$CONFIG_FILE"
port="$port"
user="$user"
host="$host"
ssh_port="$ssh_port" # Save SSH Port
key_path="$key_path"
EOF
    chmod 600 "$CONFIG_FILE" # Restrict permissions.  Important for config files.
    echo "Configuration saved to '$CONFIG_FILE'."
}

# Install dependencies if not already installed
install_dependencies() {
    echo "Installing necessary dependencies..."
    # List of required packages
    local packages=("autossh" "net-tools" "sed" "stat" "ps" "grep" "pkill")

    # Check if the package manager is available
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y "${packages[@]}"
    elif command -v yum &> /dev/null; then
        sudo yum install -y "${packages[@]}"
    elif command -v pacman &> /dev/null; then
        sudo pacman -Sy --noconfirm "${packages[@]}"
    else
        echo "Error: No supported package manager found. Please install the dependencies manually."
        return 1
    fi

    echo "Dependencies installed successfully."
    return 0
}

# Function to add a proxy to the list
add_proxy() {
    read -p "Enter a title for this proxy: " title
    while [[ -z "$title" ]]; do
        echo "Title cannot be empty."
        read -p "Enter a title for this proxy: " title
    done

    get_user_input # Get the proxy details

    # Append to the proxies.conf file
    echo "$title:$port:$user:$host:$ssh_port:$key_path" >> "$CONFIG_FILE" # Save ssh port
    echo "Proxy '$title' added."
}

# Function to list available proxies
list_proxies() {
    if [ ! -f "$CONFIG_FILE" ] || [ ! -s "$CONFIG_FILE" ]; then
        echo "No proxies configured."
        return
    fi
    echo "Available Proxies:"
    awk -F':' '{print NR " - " $1}' "$CONFIG_FILE" # Numbered list
}

# Function to get a proxy from the list
get_proxy() {
    list_proxies
    read -p "Enter the number of the proxy to select (0 to add new): " choice
    if [[ "$choice" -eq 0 ]]; then
        add_proxy
        return 0 # Return 0 to indicate a new proxy was added.
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        echo "Invalid choice."
        return 1 # Return 1 for an error.
    fi

    local proxy_data=$(awk -v choice="$choice" 'NR==choice {print}' "$CONFIG_FILE")
    if [[ -z "$proxy_data" ]]; then
        echo "Invalid proxy number."
        return 1
    fi
    IFS=':' read -r title port user host ssh_port key_path <<<"$proxy_data" # Read ssh port
    echo "Selected proxy: $title"
    return 0 # Return 0 for success
}

# Function to start the autossh tunnel
start_autossh() {
    if ! command -v autossh &> /dev/null; then
        echo "Error: autossh is not installed. Please install it first."
        exit 1
    fi

    # Check if the port is in use
    if netstat -an | grep -q "$SOCKS_BIND_ADDRESS:$port"; then
        echo "Error: Port $port is already in use.  Please choose a different port."
        return 1 # Return 1 to indicate failure
    fi

    echo "Starting autossh with SOCKS proxy on $SOCKS_BIND_ADDRESS:$port..."
    autossh -M 0 -N -D "$SOCKS_BIND_ADDRESS:$port" \
            -p "$ssh_port" \
            -o "ServerAliveInterval 60" \
            -o "ServerAliveCountMax 3" \
            -o "StrictHostKeyChecking=no" \
            -o "UserKnownHostsFile=/dev/null" \
            -i "$key_path" "$user@$host" &
    AUTOSSH_PID=$! # Capture the process ID of autossh
    if [ -z "$AUTOSSH_PID" ]; then
      echo "Error: autossh failed to start."
      return 1
    fi
    echo "SOCKS proxy running on $SOCKS_BIND_ADDRESS:$port (PID: $AUTOSSH_PID)"
    # Store the PID and title
    mkdir -p "$CONFIG_DIR" #make sure directory exists
    echo "$AUTOSSH_PID:$title" >> "$AUTOSSH_PIDS_FILE" # Append PID and title
    return 0
}

# Function to stop the autossh tunnel
stop_autossh() {
    if [ -n "$AUTOSSH_PID" ]; then # Check if variable is set
        local pid="${AUTOSSH_PID%%:*}" # Extract only the PID
        local title="${AUTOSSH_PID#*:}" # Extract the title
        echo "Stopping autossh (PID: $pid)..."
        if kill "$pid" &> /dev/null; then
            echo "autossh stopped."
        else
            echo "autossh may not have stopped correctly. PID: $pid"
            pkill -f "autossh -M 0 -N -D $SOCKS_BIND_ADDRESS:$port -p $ssh_port -i $key_path $user@$host" > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                echo "Stopped lingering autossh process."
            else
                echo "Failed to stop lingering autossh process."
            fi
        fi

        # Check if the process is still running
        if ! ps -p "$pid" &> /dev/null; then
            echo "Removing stale PID $pid from the running proxies file."
            sed -i "/^$pid:/d" "$AUTOSSH_PIDS_FILE"
        fi

        unset AUTOSSH_PID # Unset the variable
    else
        echo "No autossh process to stop."
    fi
}

# Function to list running proxies
list_running_proxies() {
    if [ ! -f "$AUTOSSH_PIDS_FILE" ] || [ ! -s "$AUTOSSH_PIDS_FILE" ]; then
        echo "No running proxies."
        return
    fi
    echo "Running Proxies:"
    awk -F':' '{print NR " - " $2 " (PID: " $1 ")"} END{ print "" }' "$AUTOSSH_PIDS_FILE"
}

# Function to show the logs or check the health of a running proxy.
show_proxy_status() {
    list_running_proxies #show the running proxies
    read -p "Enter the number of the proxy to check: " choice
    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        echo "Invalid choice."
        return
    fi

    local pid_data=$(awk -v choice="$choice" 'NR==choice {print}' "$AUTOSSH_PIDS_FILE")
    if [[ -z "$pid_data" ]]; then
        echo "Invalid proxy number."
        return
    fi
    IFS=':' read -r pid title <<<"$pid_data"

    # Check if the process is running
    if ps -p "$pid" &> /dev/null; then
        echo "Proxy '$title' (PID: $pid) is running."
        # You could add more sophisticated checks here, like checking network connectivity
        #  through the proxy, but that's beyond the basics.
    else
        echo "Proxy '$title' (PID: $pid) is NOT running."
        #  Remove from file
        sed -i "/^$pid:/d" "$AUTOSSH_PIDS_FILE"
    fi
}

# Function to edit a proxy
edit_proxy() {
    list_proxies
    read -p "Enter the number of the proxy to edit: " choice
    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        echo "Invalid choice."
        return
    fi

    local proxy_data=$(awk -v choice="$choice" 'NR==choice {print}' "$CONFIG_FILE")
    if [[ -z "$proxy_data" ]]; then
        echo "Invalid proxy number."
        return
    fi

    IFS=':' read -r title port user host ssh_port key_path <<<"$proxy_data" # Read ssh port

    echo "Current settings for proxy '$title':"
    echo "  Port: $port"
    echo "  User: $user"
    echo "  Host: $host"
    echo "  SSH Port: $ssh_port"
    echo "  Key Path: $key_path"

    # Get new values, defaulting to the old ones
    read -p "Enter new port number (default: $port): " new_port
    port="${new_port:-$port}"
     if [[ ! "$port" =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
        echo "Invalid port number. Using default: $SOCKS_DEFAULT_PORT"
        port="$SOCKS_DEFAULT_PORT"
    fi


    read -p "Enter new username (default: $user): " new_user
    user="${new_user:-$user}"
    while [[ -z "$user" ]]; do
        echo "Username cannot be empty."
        read -p "Enter new username: " user
    done

    read -p "Enter new host (default: $host): " new_host
    host="${new_host:-$host}"
     while [[ -z "$host" ]]; do
        echo "Host cannot be empty."
        read -p "Enter new host: " host
    done

    read -p "Enter new SSH port (default: $ssh_port): " new_ssh_port
    ssh_port="${new_ssh_port:-$ssh_port}"
    if [[ ! "$ssh_port" =~ ^[0-9]+$ ]] || (( ssh_port < 1 || ssh_port > 65535 )); then
        echo "Invalid SSH port number. Using default: $SSH_DEFAULT_PORT"
        ssh_port="$SSH_DEFAULT_PORT"
    fi

    read -p "Enter new key path (default: $key_path): " new_key_path
    key_path="${new_key_path:-$key_path}"
    key_path=$(echo "$key_path")
     if [ ! -f "$key_path" ]; then
        echo "Error: Private key file not found at '$key_path'."
        exit 1
    elif [[ ! -O "$key_path" ]]; then # Check if owned by the user.
        echo "Warning: Private key file '$key_path' is not owned by you. This might be a security risk."
    elif [[ $(stat -c "%a" "$key_path") != "600" && $(stat -c "%a" "$key_path") != "400" ]]; then
        echo "Warning: Private key file '$key_path' has incorrect permissions.  It should be 600 or 400."
    fi

    # Update the line in the config file
    sed -i "s/^$title:$old_port:$old_user:$old_host:$old_ssh_port:$old_key_path$/$title:$port:$user:$host:$ssh_port:$key_path/" "$CONFIG_FILE" #save ssh port
    echo "Proxy '$title' updated."
}

# Function to delete a proxy
delete_proxy() {
    list_proxies
    read -p "Enter the number of the proxy to delete: " choice
    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        echo "Invalid choice."
        return
    fi

    local proxy_data=$(awk -v choice="$choice" 'NR==choice {print}' "$CONFIG_FILE")
     if [[ -z "$proxy_data" ]]; then
        echo "Invalid proxy number."
        return
    fi
    IFS=':' read -r title port user host ssh_port key_path <<<"$proxy_data" #get title and ssh port

    # Stop the proxy if it's running
    local running_pid=$(awk -F':' -v title="$title" '$2==title {print $1}' "$AUTOSSH_PIDS_FILE")
    if [ -n "$running_pid" ]; then
        echo "Stopping proxy '$title' (PID: $running_pid) before deleting..."
        kill "$running_pid"
        wait "$running_pid"
        if [ $? -eq 0 ]; then
            echo "Proxy '$title' stopped."
            sed -i "/^$running_pid:/d" "$AUTOSSH_PIDS_FILE" # Remove from running list
        else
            echo "Proxy '$title' may not have stopped.  Removing from list anyway."
            # Try to kill any autossh process for this host and port.
            pkill -f "autossh -M 0 -N -D $SOCKS_BIND_ADDRESS:$port -p $ssh_port -i $key_path $user@$host"
            if [ $? -eq 0 ]; then
               echo "Stopped lingering autossh process."
               sed -i "/^$running_pid:/d" "$AUTOSSH_PIDS_FILE"
            else
               echo "Failed to stop lingering autossh process."
            fi
        fi
    fi
    # Delete the line from the config file
    sed -i "$choice d" "$CONFIG_FILE"
    echo "Proxy '$title' deleted."
}



# Trap Ctrl+C for graceful shutdown
trap stop_autossh SIGINT SIGTERM

# Main script logic
while true; do
    echo "SSH SOCKS Proxy Manager"
    echo "1 - Start a autossh proxy"
    echo "2 - List opened proxies"
    echo "3 - Close a proxy"
    echo "4 - Edit a proxy" # Added edit
    echo "5 - Delete a proxy" # added delete
    echo "6 - Install dependencies"
    echo "0 - Exit"
    read -p "Enter your choice: " choice

    case "$choice" in
        1)
            if get_proxy; then #returns 0 on success
              if start_autossh; then
                 : # No further action needed on success
              else
                echo "Failed to start proxy."
              fi
            fi
            ;;
        2)
            list_running_proxies
            ;;
        3)
            list_running_proxies
            read -p "Enter the number of the proxy to close: " proxy_to_close
            if ! [[ "$proxy_to_close" =~ ^[0-9]+$ ]]; then
                echo "Invalid choice."
            else
                pid_to_close=$(awk -v choice="$proxy_to_close" 'NR==choice {print $1}' "$AUTOSSH_PIDS_FILE")
                if [ -n "$pid_to_close" ]; then
                    AUTOSSH_PID=$pid_to_close #set the global variable
                    stop_autossh
                else
                    echo "invalid proxy number"
                fi
            fi
            ;;
        4)
            edit_proxy
            ;;
        5)
            delete_proxy
            ;;
        6)
            if install_dependencies; then
                echo "Dependencies installed successfully."
            else
                echo "Failed to install dependencies."
            fi
            ;;
        0)
            echo "Exiting..."
            break
            ;;
        *)
            echo "Invalid choice."
            ;;
    esac
done
