# jsh-nix

Personal NixOS configuration managed as a flake. Covers multiple machines, custom NixOS modules, packaged applications, and dotfiles.

![desktop](https://imgur.com/03ESIC1.png)

## Hosts

| Host | Hardware | Role |
|---|---|---|
| `jsh-server` | Desktop workstation | Primary dev machine; i3, polybar, VNC, Docker |
| `jsh-lenovo` | ThinkPad T14 AMD Gen3 | Laptop; i3, Docker, VNC |
| `jsh-mm` | Mac Mini | Media machine; Immich, MinIO, ZFS, Plex, Grafana metrics, sops-nix secrets |
| `jsh-mms` | Mac Mini Silver | Secondary media machine; privatarr (VPN torrents), Seerr, Authentik; mounts mm NFS shares |
| `pool` | Headless box | Spotify system |

## Structure

```
flake.nix              # Flake inputs and host definitions
hosts/                 # Per-host NixOS configurations
  generic-config.nix   # Shared desktop config imported by server + lenovo
  server/
  lenovo/
  mm/
  mms/
  pool/
nixos-modules/         # Custom reusable NixOS modules
dots/                  # Dotfiles (i3, polybar, rofi, vim, zsh, tmux, …)
apps/                  # Nix-packaged applications
scripts/               # Shell utility scripts
users/                 # User account definitions
lib/                   # Flake helpers
secrets/               # sops-nix encrypted secrets
```

## Custom NixOS Modules

See [`nixos-modules/README.md`](nixos-modules/README.md) for full options documentation.

| Module | Description |
|---|---|
| `privatarr` | VPN-isolated media acquisition stack (Sonarr, Radarr, Prowlarr, Deluge via ProtonVPN network namespace) |
| `immich-backup` | Scheduled Immich backup to BackBlaze B2 |
| `immich-protondrive-backup` | Scheduled Immich backup to ProtonDrive via rclone |
| `virtual-desktop-vnc` | Headless virtual desktop (Xvfb + i3 + x11vnc) for machines without a physical display |
| `ai-stack` | Local AI inference stack with Hermes provider support |
| `kiro-gateway` | AI gateway service (kiro-gateway) |
| `firecrawl` | Web scraping service |

## Packages

| Package | Language | Description |
|---|---|---|
| `finvizrec` | Python | Finance screener using finvizfinance |
| `receipt-api` | Rust | REST API for managing receipt data with PostgreSQL |

Build with:
```bash
nix build .#finvizrec
nix build .#receipt-api
```

## Dotfiles

Desktop configuration shared across `jsh-server` and `jsh-lenovo`.

### i3 Keyboard Shortcuts

| Shortcut | Function |
|---|---|
| `mod+p` | Screenshot all screens and save to home directory |
| `mod+shift+p` | Screenshot focused window |
| `mod+space` | rofi launcher (applications and scripts) |

### Polybar

Status bar at the bottom of the screen. Configured to show CPU usage, memory usage, disk usage, workspace, date, and time.

### Picom

Compositor for window shadows and effects. If screen sharing in Zoom produces a shadow artifact, run `pkill picom` to work around it.

## Scripts

| Script | Description |
|---|---|
| `brightness` | Adjust screen brightness across all connected monitors |
| `copy-img` | Interactive screenshot selection, copied to clipboard |
| `screens` | Configure multi-monitor layout by display resolution |
| `ip` | Print current public IP address |
| `jumpd` | Launch Jump Desktop client via Wine |
| `sf-mono` | Install SF Mono font from system |

## Deploying

```bash
# Rebuild and switch on the current machine
sudo nixos-rebuild switch --flake .#<hostname>

# Build without switching
nixos-rebuild build --flake .#<hostname>
```

## Secrets

Secrets are managed with [sops-nix](https://github.com/Mic92/sops-nix). Encrypted files live in `secrets/` and are decrypted at activation time using the host's SSH host key.
