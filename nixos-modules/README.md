# Aargh - Secure VPN-Protected Media Automation Suite

A comprehensive NixOS module providing secure, VPN-protected torrenting with automated media management. Features leak-proof network isolation, automatic ProtonVPN failover, and a complete media request/download/organization pipeline.

## 🔒 Security Features

- **Zero-leak guarantee** with network namespace isolation
- **Automatic VPN failover** across multiple ProtonVPN servers
- **Continuous connectivity monitoring** with leak detection
- **Port forwarding** for optimal torrent performance
- **Interface binding** ensures all traffic goes through VPN

## 📦 Included Services

- **ProtonVPN** - WireGuard-based VPN with automatic failover
- **Deluge** - Torrent client (VPN-isolated)
- **Sonarr** - TV show management and automation  
- **Overseerr** - User-friendly request interface for Plex users

## 🚀 Quick Start

### 1. Add Module to Your Configuration

```nix
# In your flake-based NixOS configuration
{
  imports = [
    inputs.self.nixosModules.default
  ];

  services.aargh = {
    enable = true;
    
    proton = {
      enable = true;
      configDir = "/etc/nixos/protonvpn-configs";
    };
  };
}
```

### 2. Set Up ProtonVPN Configurations

1. **Download WireGuard configs** from your ProtonVPN account:
   - Login to ProtonVPN web interface
   - Go to Downloads → WireGuard configuration
   - Download multiple server configs for failover

2. **Place configs on your server**:
   ```bash
   sudo mkdir -p /etc/nixos/protonvpn-configs
   sudo cp *.conf /etc/nixos/protonvpn-configs/
   sudo chmod 600 /etc/nixos/protonvpn-configs/*.conf
   ```

### 3. Deploy

```bash
sudo nixos-rebuild switch
```

### 4. Access Services

After deployment, access via web interfaces:

- **Deluge**: `http://your-server:8112` (password: `deluge`)
- **Sonarr**: `http://your-server:8989`
- **Overseerr**: `http://your-server:5055`

## ⚙️ Configuration Options

### Basic Configuration

```nix
services.aargh = {
  enable = true;
  
  # VPN Configuration (Required)
  proton = {
    enable = true;
    configDir = "/path/to/protonvpn-configs";
    
    # Optional VPN settings
    interfaceName = "protonvpn";           # Default
    connectionTimeout = 10;                # Seconds
    retryInterval = 30;                    # Seconds between config retries
    useNetworkNamespace = true;            # Enable ultimate leak protection
    namespaceName = "aargh-vpn";           # Namespace name
    
    # Port forwarding (improves torrent performance)
    enablePortForwarding = true;           # Default: enabled
    portForwardingGateway = "10.2.0.1";   # ProtonVPN gateway
  };
  
  # Deluge (Torrent Client)
  deluge = {
    # Note: Automatically enabled when aargh is enabled
    webPort = 8112;                        # Web interface port
    daemonPort = 58846;                    # Daemon port
    downloadDir = "/var/lib/deluge/Downloads";
    openFilesLimit = 4096;
  };
  
  # Sonarr (TV Show Management) 
  sonarr = {
    # Note: Automatically enabled when aargh is enabled
    port = 8989;
    dataDir = "/var/lib/sonarr";
    tvDir = "/var/lib/media/TV";           # Where organized shows go
    downloadDir = "/var/lib/deluge/Downloads"; # Where Deluge downloads
  };
  
  # Overseerr (Request Management)
  overseerr = {
    # Note: Automatically enabled when aargh is enabled  
    port = 5055;
    dataDir = "/var/lib/overseerr";
  };
};
```

### Advanced Configuration

```nix
services.aargh = {
  enable = true;
  
  proton = {
    enable = true;
    configDir = "/etc/nixos/protonvpn-configs";
    
    # Disable network namespace isolation (not recommended)
    useNetworkNamespace = false;
    
    # Disable port forwarding
    enablePortForwarding = false;
    
    # Custom retry timing
    connectionTimeout = 20;    # Wait longer for connections
    retryInterval = 60;        # Wait longer between retries
  };
  
  # Custom directories
  deluge.downloadDir = "/mnt/storage/downloads";
  sonarr.tvDir = "/mnt/storage/media/TV";
  overseerr.dataDir = "/mnt/storage/overseerr";
};
```

## 🔧 Initial Setup

### 1. Configure Deluge (Automated)
The Sonarr → Deluge integration is **automatically configured**. No manual setup needed!

### 2. Configure Overseerr
1. Open `http://your-server:5055`
2. Complete the initial setup wizard
3. Add Sonarr service:
   - **Service Type**: Sonarr
   - **Server**: `localhost` 
   - **Port**: `8989`
   - **API Key**: Found in Sonarr settings

### 3. Configure Sonarr
1. Open `http://your-server:8989`  
2. Add indexers (torrent sites):
   - Settings → Indexers → Add Indexer
   - Add your preferred torrent indexers
3. Set up quality profiles as desired
4. The Deluge download client is **already configured automatically**

## 🛠️ Troubleshooting

### Check Service Status
```bash
# Check all aargh services
sudo systemctl status aargh-*

# Check individual services
sudo systemctl status aargh-protonvpn
sudo systemctl status deluged
sudo systemctl status sonarr
sudo systemctl status overseerr
```

### Check VPN Connection
```bash
# View VPN interface
sudo ip addr show protonvpn

# Check if running in namespace
sudo ip netns list

# Test connectivity through VPN
sudo ip netns exec aargh-vpn curl ifconfig.me
```

### View Logs
```bash
# VPN service logs
sudo journalctl -u aargh-protonvpn -f

# Deluge logs  
sudo journalctl -u deluged -f

# Port forwarding logs
sudo journalctl -u aargh-portforward -f
```

### Common Issues

#### "No VPN configs found"
- Ensure `.conf` files are in the `configDir` path
- Check file permissions: `sudo ls -la /etc/nixos/protonvpn-configs/`

#### "All VPN servers failed"
- ProtonVPN servers may be temporarily down
- Try downloading fresh configs from ProtonVPN
- Check if your subscription supports the server locations

#### "Deluge can't connect"
- VPN may not be fully established yet
- Check: `sudo systemctl status aargh-protonvpn`
- Services automatically restart when VPN reconnects

#### Port forwarding not working
- Ensure your ProtonVPN plan supports port forwarding
- Some servers don't support port forwarding - try different configs
- Check logs: `sudo journalctl -u aargh-portforward`

#### Web interface connection issues (with network namespace)
- The module uses a socat bridge to connect web interfaces to namespaced services
- Check bridge status: `sudo systemctl status aargh-deluge-bridge`
- If issues persist, consider disabling namespace isolation: `useNetworkNamespace = false`

## 🔒 Security Notes

### Network Isolation
- **Default**: Deluge runs in isolated network namespace
- **Zero leaks**: Impossible for traffic to bypass VPN
- **Kill switch**: Services stop if VPN fails

### Leak Prevention
- Continuous monitoring detects any potential leaks
- Automatic VPN restart on connectivity issues  
- Interface binding ensures VPN-only traffic

### Recommended Security Practices
- Use strong, unique passwords for all services
- Consider putting services behind a reverse proxy with authentication
- Regularly update ProtonVPN configurations
- Monitor logs for unusual activity

## 📊 Default Ports

| Service    | Port | Purpose           |
|------------|------|-------------------|
| Deluge Web | 8112 | Web interface     |
| Deluge Daemon | 58846 | Daemon API    |
| Sonarr     | 8989 | Web interface     |
| Overseerr  | 5055 | Web interface     |

## 🔄 File Transfer to Plex

For transferring completed media to your Plex server:

### Option 1: rsync (Simple)
```bash
# Add to a cron job or systemd timer
rsync -av /var/lib/media/TV/ user@plex-server:/path/to/plex/TV/
```

### Option 2: NFS/SMB Mount
```nix
# Mount Plex server storage directly
fileSystems."/mnt/plex" = {
  device = "plex-server:/path/to/media";
  fsType = "nfs";
};

# Then configure Sonarr to organize directly to mounted path
services.aargh.sonarr.tvDir = "/mnt/plex/TV";
```

### Option 3: Syncthing (Continuous)
```nix
services.syncthing = {
  enable = true;
  # Configure to sync media directories
};
```

## 📝 Development

The module is designed to be:
- **Self-contained**: Everything needed for secure torrenting
- **Fail-safe**: Automatic restarts and leak protection
- **User-friendly**: Minimal configuration required
- **Extensible**: Easy to add new arr* services

## 🆘 Support

For issues:
1. Check logs with `journalctl`
2. Verify VPN connectivity
3. Ensure ProtonVPN configs are valid and current
4. Check file permissions and disk space

## 📄 License

This module is part of the jsh-nix repository and follows its licensing terms.