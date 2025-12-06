#!/bin/bash

# OpenVPN Monitor Dashboard Installer
# One-line install: curl -sSL https://raw.githubusercontent.com/mikegilkim/openvpn-monitor/main/install.sh | sudo bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${GREEN}${BOLD}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         OpenVPN Monitor Dashboard Installer v1.0               ║"
echo "║         Comprehensive VPN connection monitoring                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

# Check if OpenVPN is installed
echo -e "${BLUE}[1/4]${NC} Checking for OpenVPN..."
if ! command -v openvpn &> /dev/null; then
    echo -e "${YELLOW}⚠ Warning: OpenVPN is not installed${NC}"
    echo -e "${YELLOW}   The dashboard will install, but you need OpenVPN to see data${NC}"
    echo -e "${WHITE}   Install OpenVPN with: ${CYAN}sudo apt install openvpn -y${NC}"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo -e "${GREEN}✓ OpenVPN is installed${NC}"
fi

# Install bc for calculations
echo -e "${BLUE}[2/4]${NC} Installing dependencies..."
if ! command -v bc &> /dev/null; then
    apt-get update -qq
    apt-get install -y bc > /dev/null 2>&1
    echo -e "${GREEN}✓ Installed bc${NC}"
else
    echo -e "${GREEN}✓ Dependencies already installed${NC}"
fi

# Download the dashboard script
echo -e "${BLUE}[3/4]${NC} Installing OpenVPN monitor dashboard..."

cat > /usr/local/bin/vpn-dashboard << 'VPN_EOF'
[DASHBOARD_SCRIPT_CONTENT_GOES_HERE]
VPN_EOF

echo -e "${GREEN}✓ Dashboard script installed${NC}"

# Make executable
chmod +x /usr/local/bin/vpn-dashboard
echo -e "${GREEN}✓ Script is now executable${NC}"

# Add alias
echo -e "${BLUE}[4/4]${NC} Adding 'vpn' alias..."

add_alias() {
    local file=$1
    if [ -f "$file" ]; then
        if ! grep -q "alias vpn=" "$file"; then
            echo "" >> "$file"
            echo "# OpenVPN Monitor Dashboard alias" >> "$file"
            echo "alias vpn='sudo /usr/local/bin/vpn-dashboard'" >> "$file"
            echo -e "${GREEN}  ✓ Added alias to $file${NC}"
        else
            echo -e "${YELLOW}  ⚠ Alias already exists in $file${NC}"
        fi
    fi
}

add_alias "/root/.bashrc"

for user_home in /home/*; do
    if [ -d "$user_home" ]; then
        username=$(basename "$user_home")
        add_alias "$user_home/.bashrc"
        if grep -q "alias vpn=" "$user_home/.bashrc" 2>/dev/null; then
            chown $username:$username "$user_home/.bashrc" 2>/dev/null || true
        fi
    fi
done

if [ -f /etc/bash.bashrc ]; then
    add_alias "/etc/bash.bashrc"
fi

# Configure OpenVPN logging (if needed)
echo ""
echo -e "${BLUE}Checking OpenVPN logging configuration...${NC}"

CONFIG_UPDATED=false

# Check for server config
if [ -f /etc/openvpn/server/server.conf ]; then
    CONFIG_FILE="/etc/openvpn/server/server.conf"
elif [ -f /etc/openvpn/server.conf ]; then
    CONFIG_FILE="/etc/openvpn/server.conf"
else
    CONFIG_FILE=""
fi

if [ -n "$CONFIG_FILE" ]; then
    # Check if status log is configured
    if ! grep -q "^status " "$CONFIG_FILE"; then
        echo "status /var/log/openvpn/openvpn-status.log" >> "$CONFIG_FILE"
        CONFIG_UPDATED=true
        echo -e "${GREEN}✓ Added status log configuration${NC}"
    fi
    
    # Check if main log is configured
    if ! grep -q "^log " "$CONFIG_FILE"; then
        echo "log /var/log/openvpn/openvpn.log" >> "$CONFIG_FILE"
        CONFIG_UPDATED=true
        echo -e "${GREEN}✓ Added main log configuration${NC}"
    fi
    
    # Create log directory
    mkdir -p /var/log/openvpn
    
    if [ "$CONFIG_UPDATED" = true ]; then
        echo -e "${YELLOW}⚠ OpenVPN configuration updated. Restart required:${NC}"
        echo -e "  ${CYAN}sudo systemctl restart openvpn-server@server${NC}"
    else
        echo -e "${GREEN}✓ Logging is already configured${NC}"
    fi
else
    echo -e "${YELLOW}⚠ OpenVPN config not found. Manual configuration may be needed.${NC}"
fi

# Final message
echo ""
echo -e "${GREEN}${BOLD}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              Installation Complete! 🎉 🔐                      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${WHITE}To use the VPN monitor, run:${NC}"
echo -e "  ${CYAN}${BOLD}vpn${NC}"
echo ""
echo -e "${WHITE}Or directly:${NC}"
echo -e "  ${CYAN}sudo /usr/local/bin/vpn-dashboard${NC}"
echo ""
echo -e "${YELLOW}Note: You may need to reload your shell:${NC}"
echo -e "  ${CYAN}source ~/.bashrc${NC}"
echo ""
echo -e "${WHITE}What you'll see:${NC}"
echo -e "  👥 Connected clients with real IPs and VPN IPs"
echo -e "  📊 Bandwidth usage per client (upload/download)"
echo -e "  ⏱️  Connection duration for each client"
echo -e "  🌍 Country detection (if geoiplookup installed)"
echo -e "  📝 Recent connection activity and auth failures"
echo -e "  📈 Server statistics and routing table"
echo ""
echo -e "${BLUE}Optional: Install GeoIP for country detection:${NC}"
echo -e "  ${CYAN}sudo apt install geoip-bin geoip-database -y${NC}"
echo ""
echo -e "${GREEN}Monitor your VPN connections in real-time! 🚀${NC}"
echo ""
