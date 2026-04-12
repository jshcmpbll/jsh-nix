# NixOS Modules

Custom NixOS modules for this flake. All modules in this directory are automatically
imported via `default.nix` — add any host to `nixosModules.default` in `flake.nix` to
get access to all of them.

---

## Modules

- [privatarr](#privatarr) — VPN-protected media acquisition stack (Sonarr, Prowlarr, Deluge via ProtonVPN)
- [immich-backup](#immich-backup) — Scheduled Immich backup to BackBlaze B2
- [immich-protondrive-backup](#immich-protondrive-backup) — Scheduled Immich backup to ProtonDrive via rclone
- [virtual-desktop-vnc](#virtual-desktop-vnc) — Headless virtual desktop accessible over VNC

---

## privatarr

A VPN-isolated media acquisition stack. Deluge runs inside a dedicated network namespace
so all torrent traffic is forced through ProtonVPN — no leaks are possible even if the
VPN drops. Sonarr and Prowlarr are auto-configured on first boot.

### Services

| Systemd unit | Purpose |
|---|---|
| `privatarr-vpn-namespace` | Creates the network namespace (oneshot, owns its lifetime) |
| `privatarr-protonvpn` | ProtonVPN WireGuard with automatic server failover |
| `privatarr-portforward` | NAT-PMP port forwarding renewal (every 45 s) |
| `privatarr-deluge-bridge` | socat bridge exposing the namespaced daemon port to the host |
| `privatarr-deluge-port-updater` | Polls the forwarded port and applies it to Deluge |
| `privatarr-sonarr-configure` | One-shot: wires Sonarr → Deluge and sets root folder |
| `privatarr-prowlarr-configure` | One-shot: links Prowlarr → Sonarr and adds public indexers |
| `deluged` / `deluge-web` | Deluge daemon and web UI (via upstream NixOS service) |
| `sonarr` | Sonarr (via upstream NixOS service) |
| `prowlarr` | Prowlarr (via upstream NixOS service) |

### Options

```nix
services.privatarr = {
  enable = true;

  proton = {
    enable = true;

    # Supply either a list of sops-decrypted paths or a runtime directory.
    # configFiles takes precedence when non-empty.
    configFiles = [
      config.sops.secrets."protonvpn-us.conf".path
      config.sops.secrets."protonvpn-ca.conf".path
    ];
    configDir = null;             # e.g. "/persist/protonvpn-configs"

    interfaceName = "protonvpn";          # WireGuard interface name
    namespaceName = "privatarr-vpn";      # Network namespace name
    useNetworkNamespace = true;           # Disable only for debugging
    connectionTimeout = 10;               # Seconds to wait for handshake
    retryInterval = 30;                   # Seconds between server retries
    enablePortForwarding = true;          # NAT-PMP via ProtonVPN gateway
    portForwardingGateway = "10.2.0.1";  # ProtonVPN NAT-PMP gateway
  };

  deluge = {
    enable = true;                              # default: true
    webPort = 8112;
    daemonPort = 58846;
    downloadDir = "/var/lib/deluge/Downloads";
    openFilesLimit = 4096;
    webPassword = "deluge";                     # Used by Sonarr to connect
  };

  sonarr = {
    enable = true;                              # default: true
    port = 8989;
    dataDir = "/var/lib/sonarr";
    tvDir = "/var/lib/media/TV";
  };

  prowlarr = {
    enable = false;                             # default: false
    port = 9696;
    dataDir = "/var/lib/prowlarr";
    # Cardigann definition names — Cloudflare-protected sites will fail silently
    indexers = [ "thepiratebay" "limetorrents" "nyaasi" "showrss" ];
  };

  overseerr = {
    enable = false;
    port = 5055;
    dataDir = "/var/lib/overseerr";
  };
};
```

### VPN config files via sops-nix

Encrypt each WireGuard `.conf` as a sops binary secret so private keys never
appear in the Nix store or plaintext on disk:

```nix
sops.secrets."protonvpn-us-ny.conf" = {
  format = "binary";
  sopsFile = ../../secrets/protonvpn-us-ny.conf.enc;
  mode = "0400";
};

services.privatarr.proton.configFiles = [
  config.sops.secrets."protonvpn-us-ny.conf".path
];
```

### Troubleshooting

```bash
# Service overview
systemctl status privatarr-*

# Live VPN logs
journalctl -fu privatarr-protonvpn

# Confirm traffic is going through VPN (runs inside namespace)
ip netns exec privatarr-vpn curl ifconfig.me

# Port forwarding
journalctl -fu privatarr-portforward
cat /run/privatarr-portforward/forwarded_port
```

---

## immich-backup

Backs up `/var/lib/immich` to a BackBlaze B2 bucket on a systemd timer using the
`b2` CLI. Credentials should be supplied via sops-nix `*File` options rather than
inline strings.

### Options

```nix
immich-backup = {
  enable = true;
  bucketName = "my-immich-bucket";

  # Prefer file-based secrets (sops-nix)
  keyIDFile = config.sops.secrets.immich_backup_key_id.path;
  applicationKeyFile = config.sops.secrets.immich_backup_application_key.path;

  # Or inline (stored in Nix store — avoid for production)
  # keyID = "...";
  # applicationKey = "...";

  syncLocation = "/var/lib/immich";   # default
  syncDestination = "/";              # path within bucket
  threads = "4";
  backupSchedule = "daily";
  user = "immich";
};
```

---

## immich-protondrive-backup

Backs up `/var/lib/immich` to ProtonDrive via `rclone` on a systemd timer.
Generates an rclone config at runtime with obscured credentials.

### Options

```nix
immich-protondrive-backup = {
  enable = true;

  # Prefer file-based secrets (sops-nix)
  usernameFile = config.sops.secrets.immich_protondrive_username.path;
  passwordFile = config.sops.secrets.immich_protondrive_password.path;
  mailboxPasswordFile = config.sops.secrets.immich_protondrive_mailbox_password.path;
  otpSecretKeyFile = config.sops.secrets.immich_protondrive_otp_secret_key.path;

  syncLocation = "/var/lib/immich";   # default
  syncDestination = "immich-backup";
  backupSchedule = "daily";
  user = "immich";
};
```

---

## virtual-desktop-vnc

Runs a headless X session (Xvfb + i3 + x11vnc) for machines with no physical display.
Useful for running GUI applications on a server and accessing them remotely.

### Options

```nix
virtual-desktop = {
  enable = true;
  user = "jsh";           # Must already exist
  vncPort = 5900;
  vncListenAddress = "0.0.0.0";
  resolution = "1920x1080x24";
  displayNumber = 99;     # Avoids :0 reserved for physical displays
  windowManager = "i3";   # or "none"

  # Optional i3 config (omit hardware-specific lines)
  i3ConfigFile = /etc/i3/virtual-config;

  vncAuth = {
    enable = false;
    passwordFile = null;  # Created with: x11vnc -storepasswd
  };

  openFirewall = false;
};
```
