#!/bin/bash

# OpenVPN Monitor Dashboard
# Comprehensive real-time VPN connection monitoring

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'
BOLD='\033[1m'

# Box drawing characters
TL='╔'
TR='╗'
BL='╚'
BR='╝'
H='═'
V='║'

print_line() {
    local width=$1
    local char=$2
    printf "${char}%.0s" $(seq 1 $width)
}

print_header() {
    local text="$1"
    local width=80
    local text_len=${#text}
    local padding=$(( (width - text_len - 2) / 2 ))
    
    echo -e "${GREEN}${TL}$(print_line $((width-2)) $H)${TR}${NC}"
    printf "${GREEN}${V}${NC}"
    printf "%*s" $padding
    echo -ne "${WHITE}${BOLD}${text}${NC}"
    printf "%*s" $((width - text_len - padding - 2))
    echo -e "${GREEN}${V}${NC}"
    echo -e "${GREEN}${BL}$(print_line $((width-2)) $H)${BR}${NC}"
}

print_section() {
    local text="$1"
    echo ""
    echo -e "${YELLOW}${BOLD}▶ ${text}${NC}"
    echo -e "${YELLOW}$(print_line 80 '─')${NC}"
}

format_bytes() {
    local bytes=$1
    if [ -z "$bytes" ] || [ "$bytes" -eq 0 ]; then
        echo "0B"
    elif [ $bytes -lt 1024 ]; then
        echo "${bytes}B"
    elif [ $bytes -lt 1048576 ]; then
        printf "%.2fKB" $(echo "scale=2; $bytes / 1024" | bc)
    elif [ $bytes -lt 1073741824 ]; then
        printf "%.2fMB" $(echo "scale=2; $bytes / 1048576" | bc)
    else
        printf "%.2fGB" $(echo "scale=2; $bytes / 1073741824" | bc)
    fi
}

format_duration() {
    local seconds=$1
    local days=$((seconds / 86400))
    local hours=$(((seconds % 86400) / 3600))
    local mins=$(((seconds % 3600) / 60))
    local secs=$((seconds % 60))
    
    if [ $days -gt 0 ]; then
        echo "${days}d ${hours}h ${mins}m"
    elif [ $hours -gt 0 ]; then
        echo "${hours}h ${mins}m ${secs}s"
    elif [ $mins -gt 0 ]; then
        echo "${mins}m ${secs}s"
    else
        echo "${secs}s"
    fi
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    clear
    print_header "OPENVPN MONITOR DASHBOARD"
    echo ""
    echo -e "${RED}${BOLD}Error: This script requires root privileges${NC}"
    echo ""
    echo -e "${WHITE}Run with:${NC}"
    echo -e "  ${CYAN}sudo vpn${NC}"
    echo ""
    exit 1
fi

# Check if OpenVPN is installed
if ! command -v openvpn &> /dev/null; then
    clear
    print_header "OPENVPN MONITOR DASHBOARD"
    echo ""
    echo -e "${RED}${BOLD}Error: OpenVPN is not installed!${NC}"
    echo ""
    echo -e "${WHITE}Install OpenVPN with:${NC}"
    echo -e "  ${CYAN}sudo apt install openvpn -y${NC}"
    echo ""
    exit 1
fi

clear

# Detect OpenVPN service type
OPENVPN_SERVICE=""
if systemctl list-units --type=service | grep -q "openvpn-server@"; then
    OPENVPN_SERVICE="openvpn-server@server"
elif systemctl list-units --type=service | grep -q "openvpn@"; then
    OPENVPN_SERVICE="openvpn@server"
elif systemctl list-units --type=service | grep -q "openvpn.service"; then
    OPENVPN_SERVICE="openvpn"
fi

# Check OpenVPN status
if [ -n "$OPENVPN_SERVICE" ] && systemctl is-active --quiet $OPENVPN_SERVICE; then
    STATUS="${GREEN}●${NC} ${BOLD}RUNNING${NC}"
    UPTIME=$(systemctl show $OPENVPN_SERVICE --property=ActiveEnterTimestamp --value)
else
    STATUS="${RED}●${NC} ${BOLD}STOPPED${NC}"
    UPTIME="N/A"
fi

# Get OpenVPN version
OPENVPN_VERSION=$(openvpn --version 2>/dev/null | head -1 | awk '{print $2}')

# Status log file
STATUS_LOG="/var/log/openvpn/openvpn-status.log"
if [ ! -f "$STATUS_LOG" ]; then
    STATUS_LOG="/etc/openvpn/openvpn-status.log"
fi
if [ ! -f "$STATUS_LOG" ]; then
    STATUS_LOG="/var/log/openvpn-status.log"
fi

# Main log file
MAIN_LOG="/var/log/openvpn/openvpn.log"
if [ ! -f "$MAIN_LOG" ]; then
    MAIN_LOG="/var/log/openvpn.log"
fi

print_header "OPENVPN MONITOR DASHBOARD"

# Server Status
print_section "SERVER STATUS"
echo -e "  Status: $STATUS"
echo -e "  ${WHITE}Version:${NC}         ${CYAN}$OPENVPN_VERSION${NC}"
if [ "$UPTIME" != "N/A" ]; then
    echo -e "  ${WHITE}Running since:${NC}   ${CYAN}$UPTIME${NC}"
fi

# Server Configuration
print_section "SERVER CONFIGURATION"

# Get server config
if [ -f /etc/openvpn/server/server.conf ]; then
    CONFIG_FILE="/etc/openvpn/server/server.conf"
elif [ -f /etc/openvpn/server.conf ]; then
    CONFIG_FILE="/etc/openvpn/server.conf"
else
    CONFIG_FILE=""
fi

if [ -n "$CONFIG_FILE" ]; then
    PORT=$(grep -E "^port " "$CONFIG_FILE" | awk '{print $2}')
    PROTO=$(grep -E "^proto " "$CONFIG_FILE" | awk '{print $2}')
    VPN_SUBNET=$(grep -E "^server " "$CONFIG_FILE" | awk '{print $2}')
    
    echo -e "  ${WHITE}Port:${NC}            ${CYAN}${PORT:-1194}${NC}"
    echo -e "  ${WHITE}Protocol:${NC}        ${CYAN}${PROTO:-udp}${NC}"
    echo -e "  ${WHITE}VPN Subnet:${NC}      ${CYAN}${VPN_SUBNET:-10.8.0.0/24}${NC}"
fi

# Get server IP
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "N/A")
echo -e "  ${WHITE}Public IP:${NC}       ${CYAN}$SERVER_IP${NC}"

# Connected Clients Overview
print_section "CONNECTED CLIENTS OVERVIEW"

TOTAL_CLIENTS=0
TOTAL_RX=0
TOTAL_TX=0

if [ -f "$STATUS_LOG" ]; then
    # Count connected clients
    TOTAL_CLIENTS=$(grep "^CLIENT_LIST" "$STATUS_LOG" 2>/dev/null | wc -l)
    
    # Calculate total bandwidth
    while read line; do
        RX=$(echo "$line" | awk '{print $6}')
        TX=$(echo "$line" | awk '{print $7}')
        TOTAL_RX=$((TOTAL_RX + RX))
        TOTAL_TX=$((TOTAL_TX + TX))
    done < <(grep "^CLIENT_LIST" "$STATUS_LOG" 2>/dev/null)
fi

echo -e "  ${WHITE}Total Connected:${NC}     ${GREEN}${BOLD}$TOTAL_CLIENTS${NC}"
echo -e "  ${WHITE}Total Downloaded:${NC}    ${BLUE}$(format_bytes $TOTAL_RX)${NC}"
echo -e "  ${WHITE}Total Uploaded:${NC}      ${MAGENTA}$(format_bytes $TOTAL_TX)${NC}"
echo -e "  ${WHITE}Total Traffic:${NC}       ${CYAN}$(format_bytes $((TOTAL_RX + TOTAL_TX)))${NC}"

# Connected Clients Details
print_section "CONNECTED CLIENTS"

if [ $TOTAL_CLIENTS -eq 0 ]; then
    echo -e "  ${GRAY}No clients currently connected${NC}"
else
    echo ""
    
    # Parse status log for client info
    grep "^CLIENT_LIST" "$STATUS_LOG" 2>/dev/null | while read line; do
        # Parse CLIENT_LIST format
        CN=$(echo "$line" | awk '{print $2}')
        REAL_IP=$(echo "$line" | awk '{print $3}' | cut -d':' -f1)
        REAL_PORT=$(echo "$line" | awk '{print $3}' | cut -d':' -f2)
        VPN_IP=$(echo "$line" | awk '{print $4}')
        VPN_IPV6=$(echo "$line" | awk '{print $5}')
        RX=$(echo "$line" | awk '{print $6}')
        TX=$(echo "$line" | awk '{print $7}')
        CONNECTED_SINCE=$(echo "$line" | awk '{print $8}')
        
        # Calculate connection duration
        if [ -n "$CONNECTED_SINCE" ]; then
            CURRENT_TIME=$(date +%s)
            CONNECTED_TIME=$(date -d "$CONNECTED_SINCE" +%s 2>/dev/null || date -j -f "%Y-%m-%d %H:%M:%S" "$CONNECTED_SINCE" +%s 2>/dev/null)
            if [ -n "$CONNECTED_TIME" ]; then
                DURATION=$((CURRENT_TIME - CONNECTED_TIME))
                DURATION_STR=$(format_duration $DURATION)
            else
                DURATION_STR="Unknown"
            fi
        else
            DURATION_STR="Unknown"
        fi
        
        # Format bytes
        RX_FORMATTED=$(format_bytes $RX)
        TX_FORMATTED=$(format_bytes $TX)
        TOTAL_FORMATTED=$(format_bytes $((RX + TX)))
        
        # Try to get country info
        COUNTRY=""
        if command -v geoiplookup &> /dev/null; then
            COUNTRY=$(geoiplookup $REAL_IP 2>/dev/null | head -1 | awk -F': ' '{print $2}' | cut -d',' -f1)
            if [ ! -z "$COUNTRY" ] && [ "$COUNTRY" != "IP Address not found" ]; then
                COUNTRY=" ${GRAY}($COUNTRY)${NC}"
            else
                COUNTRY=""
            fi
        fi
        
        echo -e "${CYAN}${BOLD}┌─ Client: $CN${NC}"
        echo -e "${CYAN}│${NC}"
        echo -e "${CYAN}├──${NC} ${WHITE}Real IP:${NC}          ${YELLOW}$REAL_IP:$REAL_PORT${NC}$COUNTRY"
        echo -e "${CYAN}├──${NC} ${WHITE}VPN IP:${NC}           ${GREEN}$VPN_IP${NC}"
        if [ "$VPN_IPV6" != "0" ]; then
            echo -e "${CYAN}├──${NC} ${WHITE}VPN IPv6:${NC}         ${GREEN}$VPN_IPV6${NC}"
        fi
        echo -e "${CYAN}├──${NC} ${WHITE}Connected:${NC}        ${CYAN}$DURATION_STR${NC}"
        echo -e "${CYAN}├──${NC} ${WHITE}Downloaded:${NC}       ${BLUE}$RX_FORMATTED${NC}"
        echo -e "${CYAN}├──${NC} ${WHITE}Uploaded:${NC}         ${MAGENTA}$TX_FORMATTED${NC}"
        echo -e "${CYAN}└──${NC} ${WHITE}Total Traffic:${NC}    ${BOLD}$TOTAL_FORMATTED${NC}"
        echo ""
    done
fi

# Routing Table
print_section "ROUTING TABLE"

if [ -f "$STATUS_LOG" ]; then
    ROUTES=$(grep "^ROUTING_TABLE" "$STATUS_LOG" 2>/dev/null | wc -l)
    if [ $ROUTES -gt 0 ]; then
        echo ""
        printf "  ${WHITE}%-20s %-20s %-20s${NC}\n" "VPN IP" "Client" "Last Activity"
        echo -e "  ${WHITE}$(print_line 78 '─')${NC}"
        
        grep "^ROUTING_TABLE" "$STATUS_LOG" 2>/dev/null | while read line; do
            VPN_IP=$(echo "$line" | awk '{print $2}')
            CN=$(echo "$line" | awk '{print $3}')
            LAST_REF=$(echo "$line" | awk '{print $5}')
            
            printf "  ${CYAN}%-20s${NC} ${GREEN}%-20s${NC} ${GRAY}%-20s${NC}\n" "$VPN_IP" "$CN" "$LAST_REF"
        done
    else
        echo -e "  ${GRAY}No routing entries${NC}"
    fi
else
    echo -e "  ${GRAY}Status log not found${NC}"
fi

# Recent Connections
print_section "RECENT CONNECTION ACTIVITY (Last 10)"

if [ -f "$MAIN_LOG" ]; then
    RECENT=$(grep -E "MULTI.*Initialization Sequence Completed|Connection reset|SIGTERM" "$MAIN_LOG" 2>/dev/null | tail -10)
    
    if [ -n "$RECENT" ]; then
        echo "$RECENT" | while read line; do
            TIMESTAMP=$(echo "$line" | awk '{print $1, $2, $3, $4, $5, $6}')
            
            if echo "$line" | grep -q "Initialization Sequence Completed"; then
                echo -e "  ${WHITE}$TIMESTAMP${NC} ${GREEN}✓ Client connected${NC}"
            elif echo "$line" | grep -q "Connection reset"; then
                echo -e "  ${WHITE}$TIMESTAMP${NC} ${RED}✗ Client disconnected${NC}"
            elif echo "$line" | grep -q "SIGTERM"; then
                echo -e "  ${WHITE}$TIMESTAMP${NC} ${YELLOW}⚠ Server restart${NC}"
            fi
        done
    else
        echo -e "  ${GRAY}No recent activity${NC}"
    fi
else
    echo -e "  ${GRAY}Log file not found${NC}"
fi

# Authentication Failures
print_section "AUTHENTICATION FAILURES (Last 10)"

if [ -f "$MAIN_LOG" ]; then
    FAILURES=$(grep -i "TLS Error\|authentication failed\|AUTH_FAILED" "$MAIN_LOG" 2>/dev/null | tail -10)
    
    if [ -n "$FAILURES" ]; then
        echo "$FAILURES" | while read line; do
            TIMESTAMP=$(echo "$line" | awk '{print $1, $2, $3, $4, $5, $6}')
            echo -e "  ${WHITE}$TIMESTAMP${NC} ${RED}Failed authentication attempt${NC}"
        done
    else
        echo -e "  ${GREEN}No authentication failures${NC}"
    fi
else
    echo -e "  ${GRAY}Log file not found${NC}"
fi

# Server Statistics
print_section "SERVER STATISTICS"

if [ -f "$STATUS_LOG" ]; then
    MAX_CLIENTS=$(grep "^max_clients" "$STATUS_LOG" 2>/dev/null | awk '{print $2}')
    
    # Get interface statistics
    TUN_INTERFACE=$(ip link | grep tun | awk '{print $2}' | cut -d':' -f1 | head -1)
    
    if [ -n "$TUN_INTERFACE" ]; then
        TUN_RX=$(cat /sys/class/net/$TUN_INTERFACE/statistics/rx_bytes 2>/dev/null || echo 0)
        TUN_TX=$(cat /sys/class/net/$TUN_INTERFACE/statistics/tx_bytes 2>/dev/null || echo 0)
        
        echo -e "  ${WHITE}VPN Interface:${NC}       ${CYAN}$TUN_INTERFACE${NC}"
        echo -e "  ${WHITE}Interface RX:${NC}        ${BLUE}$(format_bytes $TUN_RX)${NC}"
        echo -e "  ${WHITE}Interface TX:${NC}        ${MAGENTA}$(format_bytes $TUN_TX)${NC}"
    fi
    
    if [ -n "$MAX_CLIENTS" ]; then
        echo -e "  ${WHITE}Max Clients:${NC}         ${CYAN}$MAX_CLIENTS${NC}"
    fi
    
    # Get server load
    LOAD=$(uptime | awk -F'load average:' '{print $2}' | xargs)
    echo -e "  ${WHITE}Server Load:${NC}         ${YELLOW}$LOAD${NC}"
fi

# Quick Actions
print_section "QUICK ACTIONS"
echo -e "  ${WHITE}View live logs:${NC}              ${CYAN}sudo tail -f $MAIN_LOG${NC}"
echo -e "  ${WHITE}View status log:${NC}             ${CYAN}sudo cat $STATUS_LOG${NC}"
echo -e "  ${WHITE}Restart OpenVPN:${NC}             ${CYAN}sudo systemctl restart $OPENVPN_SERVICE${NC}"
echo -e "  ${WHITE}Check OpenVPN status:${NC}        ${CYAN}sudo systemctl status $OPENVPN_SERVICE${NC}"
echo -e "  ${WHITE}Disconnect specific client:${NC}  ${CYAN}sudo pkill -f 'openvpn.*<client-name>'${NC}"
echo -e "  ${WHITE}View active connections:${NC}     ${CYAN}sudo ss -tunap | grep :1194${NC}"

# Footer
echo ""
echo -e "${GREEN}$(print_line 80 '═')${NC}"
echo -e "${WHITE}  Secure VPN monitoring  |  Run ${CYAN}vpn${WHITE} anytime  |  Press Ctrl+C to exit${NC}"
echo -e "${GREEN}$(print_line 80 '═')${NC}"
echo ""
echo -e "${CYAN}                        ╔══════════════════════════════╗${NC}"
echo -e "${CYAN}                        ║${NC} ${BOLD}${MAGENTA}★${NC} ${BOLD}${WHITE}Created by${NC} ${BOLD}${CYAN}mikegilkim${NC} ${BOLD}${MAGENTA}★${NC} ${CYAN}║${NC}"
echo -e "${CYAN}                        ║${NC}   ${BLUE}facebook.com/mikegilkim${NC}   ${CYAN}║${NC}"
echo -e "${CYAN}                        ╚══════════════════════════════╝${NC}"
echo ""
