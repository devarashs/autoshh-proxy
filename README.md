# SSH SOCKS Proxy Manager

## Description

This script is a simple and user-friendly tool to manage SSH SOCKS proxy connections. It simplifies the process of creating and maintaining secure tunnels, allowing you to bypass certain network restrictions or improve your connection quality by routing your traffic through a remote server. It was primarily tested on Ubuntu.

**Key Features:**

- **Easy Setup:** Simplifies the process of establishing an SSH SOCKS proxy.
- **Configuration Management:** Saves proxy configurations for easy reuse.
- **Multiple Proxy Support:** Manage and switch between multiple proxy configurations.
- **Connection Management:** Start, stop, and list running proxy connections.
- **Dependency Installation:** Automatically installs required dependencies (autossh, net-tools).
- **Proxy Editing and Deletion**: Allows users to modify and delete saved proxy configurations.
- **Tested on Ubuntu**: This script has been tested and is known to work well on Ubuntu systems. It _may_ work on other Linux distributions, but this is not guaranteed.

## Goal

The primary goal of this script is to provide a convenient way to:

- **Bypass Network Restrictions:** Access content or services that might be blocked by your local network.
- **Improve Network Quality:** Route your internet traffic through a server with a better connection to a specific destination.
- **Secure Your Connection:** Encrypt your internet traffic, protecting it from eavesdropping on untrusted networks (like public Wi-Fi).

## Use Cases

Here are a few examples of how this script can be used:

- Accessing region-restricted content.
- Bypassing firewalls or network filtering.
- Securing your connection when using public Wi-Fi.
- Improving network latency for specific online services.

## Important Disclaimer

**Use with care and for educational purposes only.**

This script is intended to be used for legitimate purposes, such as:

- **Educational exploration of network protocols.**
- **Accessing resources for which you have proper authorization.**
- **Improving your network security and privacy.**

**It is crucial to understand and respect the terms of service of any network or service you access.** Unauthorized use of this script to bypass restrictions or access resources without permission is strictly prohibited and may be illegal.

The author(s) of this script are not responsible for any misuse or illegal activities performed by users. This tool is provided "as is," without any warranty or guarantee of suitability for any specific purpose. Users are solely responsible for ensuring their use of this script complies with all applicable laws and regulations.

## Usage

1.  **Download the script:** Download the `start.sh` script to your local machine.
2.  **Make it executable:** `chmod +x start.sh`
3.  **Run the script:** `./start.sh`
4.  **Follow the prompts:** The script will guide you through the process of setting up and managing your SSH SOCKS proxy connections.

## Dependencies

The script requires the following dependencies:

- `autossh`: For creating and maintaining the SSH tunnel.
- `net-tools`: For network utilities (e.g., `netstat`).
- `sed`: For text manipulation.
- `stat`: For retrieving file status.
- `ps`: For listing processes
- `grep`: For searching within files
- `pkill`: For killing processes by name

The script includes a function to automatically install these dependencies if they are not already installed.

## Configuration

Proxy configurations are saved in `$HOME/.ssh_settings/proxies.conf`. This file should not be manually edited. Use the script's menu options to manage your proxy configurations.

## Support

This script is provided as-is. While I've done my best to make it user-friendly and robust, I cannot provide extensive support. If you encounter problems, please double-check your configuration and ensure you have all the necessary dependencies installed.
