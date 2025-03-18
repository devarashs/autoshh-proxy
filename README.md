# SOCKS Proxy via AutoSSH

A lightweight Bash script to set up a SOCKS5 proxy using `autossh`. Ideal for users who need a simple, persistent proxy tunnel through an SSH server.

## Features

- Establishes a SOCKS5 proxy via an SSH tunnel.
- Automatically reconnects using `autossh`.
- Saves connection settings for convenience.
- Minimal dependencies (just `autossh`).

## Requirements

- A **VPS** or remote server with SSH access.
- A **private SSH key** to authenticate.
- `autossh` installed on your local machine.

## Installation

Ensure `autossh` is installed:

```sh
sudo apt update && sudo apt install autossh  # Debian/Ubuntu
brew install autossh  # macOS
```

Clone this repository and navigate to the script location:

```sh
git clone https://github.com/devarashs/autoshh-proxy.git
cd autoshh-proxy
chmod +x start.sh  # Make script executable
```

## Usage

Run the script and follow the prompts:

```sh
./start.sh
```

It will ask for:

- The **SOCKS5 port** (default: 1080)
- Your **SSH username**
- The **SSH host** (VPS IP or domain)
- The **path to your SSH private key** (default: `~/.ssh/id_rsa`)

Once started, the proxy will be available at:

```
127.0.0.1:<chosen-port>
```

To use it, configure your browser or system to route traffic through the SOCKS5 proxy.

## Example (Manual SSH Command)

Alternatively, you can achieve the same result with a manual command:

```sh
autossh -M 0 -N -D 1080 -o "ServerAliveInterval 60" -o "ServerAliveCountMax 3" -i ~/.ssh/id_rsa user@your-vps-ip
```

## Notes

- Ensure your **SSH key is properly configured** and the remote server allows port forwarding.
- If the connection drops, `autossh` will attempt to reconnect automatically.

## License

GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007
