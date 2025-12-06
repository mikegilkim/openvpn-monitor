# 🔐 OpenVPN Monitor

Real-time OpenVPN connection monitoring. Track clients, bandwidth, and activity.

## Install

```bash
curl -sSL https://raw.githubusercontent.com/mikegilkim/openvpn-monitor/main/install.sh | sudo bash
```

## Usage

```bash
vpn
```

## Features

### 📊 Real-Time Monitoring
- **Connected Clients** - Live list of all VPN users
- **Bandwidth Tracking** - Upload/download per client
- **Connection Duration** - How long each client has been connected
- **IP Information** - Real IP, VPN IP, and country location
- **Traffic Stats** - Total server bandwidth usage

### 📈 Detailed Client Info
Each connected client shows:
- 🌍 Real IP address + port (with country)
- 🔒 Assigned VPN IP (IPv4/IPv6)
- ⏱️ Connection time (formatted: 2d 5h 30m)
- 📥 Downloaded data
- 📤 Uploaded data
- 📊 Total traffic

### 🗂️ Server Statistics
- Active connections count
- Server configuration (port, protocol, subnet)
- Routing table
- Recent connection/disconnection events
- Authentication failures
- Server load and interface stats

## Screenshot

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                      OPENVPN MONITOR DASHBOARD                               ║
╚══════════════════════════════════════════════════════════════════════════════╝

▶ CONNECTED CLIENTS OVERVIEW
────────────────────────────────────────────────────────────────────────────────
  Total Connected:     3
  Total Downloaded:    1.24GB
  Total Uploaded:      456.78MB
  Total Traffic:       1.69GB

▶ CONNECTED CLIENTS

┌─ Client: user1
│
├── Real IP:          103.45.12.89:54321 (China)
├── VPN IP:           10.8.0.6
├── Connected:        2h 34m 12s
├── Downloaded:       523.45MB
├── Uploaded:         178.92MB
└── Total Traffic:    702.37MB
```

## Requirements

- **Linux** (Ubuntu, Debian, CentOS, RHEL)
- **OpenVPN** installed and configured
- **Root/sudo access**
- **bc** (auto-installed)

Optional:
- **geoiplookup** - For country detection

## Quick Setup

**1. Install OpenVPN** (if not installed):
```bash
sudo apt install openvpn -y
```

**2. Install the dashboard**:
```bash
curl -sSL https://raw.githubusercontent.com/mikegilkim/openvpn-monitor/main/install.sh | sudo bash
```

**3. Run it**:
```bash
vpn
```

## Configuration

The installer automatically configures OpenVPN logging. If you need manual setup:

**Edit OpenVPN config** (`/etc/openvpn/server/server.conf`):
```conf
status /var/log/openvpn/openvpn-status.log
log /var/log/openvpn/openvpn.log
```

**Restart OpenVPN**:
```bash
sudo systemctl restart openvpn-server@server
```

## Country Detection

For geographic location of client IPs:

```bash
sudo apt install geoip-bin geoip-database -y
```

Dashboard will automatically detect and use it.

## Manual Install

```bash
wget https://raw.githubusercontent.com/mikegilkim/openvpn-monitor/main/vpn-dashboard.sh
chmod +x vpn-dashboard.sh
sudo mv vpn-dashboard.sh /usr/local/bin/vpn-dashboard
echo "alias vpn='sudo /usr/local/bin/vpn-dashboard'" >> ~/.bashrc
source ~/.bashrc
```

## Troubleshooting

**"OpenVPN is not installed"**
```bash
sudo apt install openvpn -y
```

**"No clients showing up"**
- Check OpenVPN is running: `sudo systemctl status openvpn-server@server`
- Verify logging is configured in `/etc/openvpn/server/server.conf`
- Check log files exist: `ls -la /var/log/openvpn/`

**"Command not found: vpn"**
```bash
source ~/.bashrc
```

**"Permission denied"**
```bash
sudo vpn
```

## What Data is Tracked?

✅ **Connection Info** - Client name, IPs, connection time  
✅ **Bandwidth** - Real-time upload/download per client  
✅ **Activity Logs** - Connections, disconnections, auth failures  
✅ **Routing** - VPN IP assignments and routes  
✅ **Server Stats** - Load, interface traffic, max capacity  

❌ **NOT Tracked** - Websites visited, DNS queries, packet contents

*For website/DNS tracking, you'd need additional tools like Squid proxy or DNS logging.*

## Use Cases

Perfect for:
- 👨‍💼 VPN server administrators
- 🏢 Small business VPN monitoring
- 🏠 Home server management
- 🎓 Learning VPN administration
- 🔒 Security auditing

## License

MIT - Use freely, modify as needed.

