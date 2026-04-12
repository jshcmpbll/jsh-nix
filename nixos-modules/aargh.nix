{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.aargh;

in {
  options.services.aargh = {
    enable = mkEnableOption "Aargh - VPN-enabled torrent service";
    
    proton = {
      enable = mkEnableOption "Proton VPN WireGuard connection";
      
      configFiles = mkOption {
        type = types.listOf types.path;
        default = [];
        description = ''
          List of WireGuard config file paths to use. Intended for sops-decrypted
          secrets (e.g. config.sops.secrets."protonvpn-us.conf".path). Takes
          precedence over configDir when non-empty.
        '';
        example = [ "/run/secrets/protonvpn-us-ny.conf" "/run/secrets/protonvpn-us-ca.conf" ];
      };

      configDir = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          Path to a directory containing Proton VPN WireGuard .conf files.
          All .conf files will be tried in random order. Use configFiles instead
          when you want to deploy configs via sops-nix.
        '';
        example = "/persist/protonvpn-configs";
      };
      
      interfaceName = mkOption {
        type = types.str;
        default = "protonvpn";
        description = "Name of the WireGuard interface";
      };
      
      connectionTimeout = mkOption {
        type = types.int;
        default = 10;
        description = "Timeout in seconds when testing VPN connection";
      };
      
      retryInterval = mkOption {
        type = types.int;
        default = 30;
        description = "Seconds to wait before retrying failed configs";
      };
      
      enablePortForwarding = mkOption {
        type = types.bool;
        default = true;
        description = "Enable ProtonVPN port forwarding for improved torrent performance";
      };
      
      portForwardingGateway = mkOption {
        type = types.str;
        default = "10.2.0.1";
        description = "ProtonVPN gateway IP for port forwarding requests";
      };
      
      useNetworkNamespace = mkOption {
        type = types.bool;
        default = true;
        description = "Run services in isolated network namespace for complete leak protection";
      };
      
      namespaceName = mkOption {
        type = types.str;
        default = "aargh-vpn";
        description = "Name of the network namespace";
      };
    };
    
    deluge = {
      enable = mkEnableOption "Deluge torrent client";
      
      webPort = mkOption {
        type = types.port;
        default = 8112;
        description = "Port for Deluge web interface";
      };
      
      daemonPort = mkOption {
        type = types.port;
        default = 58846;
        description = "Port for Deluge daemon";
      };
      
      downloadDir = mkOption {
        type = types.path;
        default = "/var/lib/deluge/Downloads";
        description = "Directory for completed downloads";
      };
      
      openFilesLimit = mkOption {
        type = types.int;
        default = 4096;
        description = "Maximum number of open files for Deluge";
      };

      webPassword = mkOption {
        type = types.str;
        default = "deluge";
        description = "Password for Deluge web interface (used by Sonarr to connect)";
      };
    };
    
    sonarr = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Sonarr TV show management";
      };
      
      port = mkOption {
        type = types.port;
        default = 8989;
        description = "Port for Sonarr web interface";
      };
      
      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/sonarr";
        description = "Directory for Sonarr data";
      };
      
      tvDir = mkOption {
        type = types.path;
        default = "/var/lib/media/TV";
        description = "Directory for organized TV shows";
      };
      
      downloadDir = mkOption {
        type = types.path;
        default = "/var/lib/deluge/Downloads";
        description = "Directory where Deluge downloads files";
      };
    };
    
    prowlarr = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Prowlarr indexer manager";
      };

      port = mkOption {
        type = types.port;
        default = 9696;
        description = "Port for Prowlarr web interface";
      };

      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/prowlarr";
        description = "Directory for Prowlarr data";
      };

      indexers = mkOption {
        type = types.listOf types.str;
        default = [ "thepiratebay" "limetorrents" "nyaasi" "showrss" ];
        # Note: "internetarchive" excluded — too slow, causes search timeouts
        description = "List of Prowlarr Cardigann definition names to add as public indexers";
      };
    };

    overseerr = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Overseerr request management";
      };
      
      port = mkOption {
        type = types.port;
        default = 5055;
        description = "Port for Overseerr web interface";
      };
      
      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/overseerr";
        description = "Directory for Overseerr data";
      };
    };
  };
  
  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.proton.enable -> (cfg.proton.configFiles != [] || cfg.proton.configDir != null);
        message = "services.aargh.proton: set configFiles (for sops-deployed configs) or configDir";
      }
      {
        assertion = cfg.deluge.enable -> cfg.proton.enable;
        message = "Deluge requires Proton VPN to be enabled for secure torrenting";
      }
    ];
    
    # Install required packages
    environment.systemPackages = with pkgs; [
      wireguard-tools
      deluge
      sonarr
      curl
      jq
      libnatpmp
      socat
    ] ++ lib.optionals cfg.overseerr.enable [ pkgs.overseerr ];
    
    # Proton VPN service with failover
    systemd.services.aargh-protonvpn = mkIf cfg.proton.enable {
      description = "Aargh Proton VPN with automatic failover";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      
      path = with pkgs; [ wireguard-tools iproute2 coreutils gnugrep gawk curl netcat-gnu dnsutils ];
      
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = cfg.proton.retryInterval;
      };
      
      script = ''
        set -euo pipefail
        
        # Function to parse WireGuard config
        parse_config() {
          local config_file=$1

          # Use awk -F ' = ' to split on ' = ' so base64 '=' padding is preserved.
          # tr -d '\r\n' strips any trailing newline/carriage-return.
          PRIVATE_KEY=$(grep "^PrivateKey" "$config_file" | awk -F ' = ' '{print $2}' | tr -d '\r\n')
          PUBLIC_KEY=$(grep "^PublicKey"  "$config_file" | awk -F ' = ' '{print $2}' | tr -d '\r\n')
          ENDPOINT=$(grep "^Endpoint"    "$config_file" | awk -F ' = ' '{print $2}' | tr -d '\r\n')

          # Address may be "10.x.x.x/32,2a07::.../128" — take only the IPv4 part.
          ADDRESS=$(grep "^Address" "$config_file" | awk -F ' = ' '{print $2}' | cut -d',' -f1 | tr -d '\r\n')

          # Extract endpoint IP for routing
          ENDPOINT_IP=$(echo "$ENDPOINT" | cut -d':' -f1)
        }
        
        # Function to check if VPN server is reachable
        check_server_reachability() {
          local endpoint_ip=$1
          local endpoint_port=$2
          
          echo "Checking server reachability: $endpoint_ip:$endpoint_port"
          
          # Test UDP connectivity to WireGuard port
          if timeout 5 nc -u -z "$endpoint_ip" "$endpoint_port" 2>/dev/null; then
            echo "Server is reachable"
            return 0
          else
            echo "Server appears unreachable"
            return 1
          fi
        }
        
        # Function to setup WireGuard interface
        setup_wireguard() {
          local config_file=$1
          echo "Attempting connection with: $config_file"
          
          parse_config "$config_file"
          
          # Extract port from endpoint
          ENDPOINT_PORT=$(echo "$ENDPOINT" | cut -d':' -f2)
          
          # Check if server is reachable before attempting connection
          if ! check_server_reachability "$ENDPOINT_IP" "$ENDPOINT_PORT"; then
            echo "Skipping unreachable server: $ENDPOINT"
            return 1
          fi
          
          if [ "${toString cfg.proton.useNetworkNamespace}" = "1" ]; then
            # Create namespace once if it doesn't exist; do NOT delete it on restart
            # so deluged (attached via NetworkNamespacePath) stays in the same namespace.
            ip netns add ${cfg.proton.namespaceName} 2>/dev/null || true

            # Delete only the WireGuard interface (if present) so we can reconfigure it.
            ip netns exec ${cfg.proton.namespaceName} ip link del ${cfg.proton.interfaceName} 2>/dev/null || true

            # Create WireGuard interface and move it into the namespace.
            ip link add ${cfg.proton.interfaceName} type wireguard
            ip link set ${cfg.proton.interfaceName} netns ${cfg.proton.namespaceName}

            # Configure WireGuard entirely inside the namespace.
            ip netns exec ${cfg.proton.namespaceName} \
              wg set ${cfg.proton.interfaceName} \
                private-key <(echo "$PRIVATE_KEY") \
                peer "$PUBLIC_KEY" \
                endpoint "$ENDPOINT" \
                persistent-keepalive 25 \
                allowed-ips 0.0.0.0/0

            # Bring up the interface and set address/routing inside the namespace.
            ip netns exec ${cfg.proton.namespaceName} ip addr add "$ADDRESS" dev ${cfg.proton.interfaceName}
            ip netns exec ${cfg.proton.namespaceName} ip link set ${cfg.proton.interfaceName} up
            ip netns exec ${cfg.proton.namespaceName} ip link set lo up
            ip netns exec ${cfg.proton.namespaceName} ip route add default dev ${cfg.proton.interfaceName}

            # Route the VPN endpoint itself via the real gateway (outside namespace).
            DEFAULT_GW=$(ip route | grep default | ${pkgs.gawk}/bin/awk '{print $3}' | head -n1)
            if [ -n "$DEFAULT_GW" ]; then
              ip route add "$ENDPOINT_IP/32" via "$DEFAULT_GW" 2>/dev/null || true
            fi
          else
            # Non-namespace mode: clean up old interface and reconfigure in default namespace.
            ip link del ${cfg.proton.interfaceName} 2>/dev/null || true
            ip link add ${cfg.proton.interfaceName} type wireguard
            wg set ${cfg.proton.interfaceName} \
              private-key <(echo "$PRIVATE_KEY") \
              peer "$PUBLIC_KEY" \
              endpoint "$ENDPOINT" \
              persistent-keepalive 25 \
              allowed-ips 0.0.0.0/0
            ip addr add "$ADDRESS" dev ${cfg.proton.interfaceName}
            ip link set ${cfg.proton.interfaceName} up

            DEFAULT_GW=$(ip route | grep default | ${pkgs.gawk}/bin/awk '{print $3}' | head -n1)
            if [ -n "$DEFAULT_GW" ]; then
              ip route add "$ENDPOINT_IP/32" via "$DEFAULT_GW" 2>/dev/null || true
            fi
          fi
          
          # Wait for handshake
          echo "Waiting for WireGuard handshake..."
          for i in {1..${toString cfg.proton.connectionTimeout}}; do
            if [ "${toString cfg.proton.useNetworkNamespace}" = "1" ]; then
              if ip netns exec ${cfg.proton.namespaceName} wg show ${cfg.proton.interfaceName} | grep -q "latest handshake"; then
                echo "Handshake successful!"
                return 0
              fi
            else
              if wg show ${cfg.proton.interfaceName} | grep -q "latest handshake"; then
                echo "Handshake successful!"
                return 0
              fi
            fi
            sleep 1
          done
          
          echo "Handshake failed for $config_file"
          return 1
        }
        
        # Function to test VPN connectivity with comprehensive checks
        test_connection() {
          echo "Testing VPN connectivity..."
          
          local curl_cmd="curl"
          local ns_exec=""
          
          # Set up namespace execution if needed
          if [ "${toString cfg.proton.useNetworkNamespace}" = "1" ]; then
            ns_exec="ip netns exec ${cfg.proton.namespaceName}"
          else
            curl_cmd="curl --interface ${cfg.proton.interfaceName}"
          fi
          
          # Test 1: Check if we can resolve DNS through VPN
          if ! timeout 5 $ns_exec nslookup google.com 1.1.1.1 > /dev/null 2>&1; then
            echo "DNS resolution test failed"
            return 1
          fi
          
          # Test 2: Try multiple public IP check services through the VPN
          local test_urls=("https://ifconfig.me" "https://ipinfo.io/ip" "https://api.ipify.org")
          local success_count=0
          local vpn_ip=""
          
          for url in "''${test_urls[@]}"; do
            if timeout 10 $ns_exec $curl_cmd --silent --max-time 8 "$url" > /dev/null 2>&1; then
              if [ -z "$vpn_ip" ]; then
                vpn_ip=$($ns_exec $curl_cmd --silent --max-time 8 "$url" 2>/dev/null | head -n1)
              fi
              ((success_count++))
            fi
          done
          
          if [ "$success_count" -ge 2 ]; then
            echo "VPN connection successful! Public IP: $vpn_ip"
            
            # Test 3: Verify we're not leaking by checking no traffic goes through default route
            # This is a safety check to ensure all traffic is routed through VPN
            if command -v ss >/dev/null 2>&1; then
              # Check for any active connections not bound to VPN interface
              local leak_check=$(ss -tuln | grep -v "127.0.0.1\|::1\|${cfg.proton.interfaceName}" | wc -l)
              if [ "$leak_check" -gt 10 ]; then  # Allow some system connections
                echo "Warning: Potential traffic leakage detected"
              fi
            fi
            
            return 0
          else
            echo "VPN connectivity test failed (only $success_count/''${#test_urls[@]} services responded)"
            return 1
          fi
        }
        
        # Function to validate VPN is not leaking
        validate_no_leaks() {
          echo "Performing leak detection test..."
          
          # Get our real public IP (before VPN) if possible
          # This should fail if we're properly configured
          if timeout 5 curl --silent --max-time 3 https://ifconfig.me 2>/dev/null; then
            local non_vpn_ip=$(curl --silent --max-time 3 https://ifconfig.me 2>/dev/null)
            local vpn_ip=$(curl --silent --interface ${cfg.proton.interfaceName} --max-time 3 https://ifconfig.me 2>/dev/null)
            
            if [ "$non_vpn_ip" = "$vpn_ip" ]; then
              echo "LEAK DETECTED: Traffic is not going through VPN!"
              return 1
            else
              echo "Leak test passed: Non-VPN and VPN IPs are different"
            fi
          else
            echo "Leak test passed: Cannot reach internet without VPN interface"
          fi
          
          return 0
        }
        
        # Main loop - try configs in random order
        ${if cfg.proton.configFiles != [] then ''
          # Config files deployed at build time (e.g. via sops-nix)
          mapfile -t CONFIGS < <(printf '%s\n' ${lib.concatStringsSep " " (map lib.escapeShellArg cfg.proton.configFiles)} | shuf)
        '' else ''
          # Scan directory for .conf files at runtime
          CONFIG_DIR="${cfg.proton.configDir}"
          if [ ! -d "$CONFIG_DIR" ]; then
            echo "Error: Config directory $CONFIG_DIR does not exist"
            exit 1
          fi
          mapfile -t CONFIGS < <(find "$CONFIG_DIR" -maxdepth 1 -name "*.conf" | shuf)
          if [ ''${#CONFIGS[@]} -eq 0 ]; then
            echo "Error: No .conf files found in $CONFIG_DIR"
            exit 1
          fi
        ''}
        
        echo "Found ''${#CONFIGS[@]} VPN configuration(s)"
        
        # Try each config until one works
        for config in "''${CONFIGS[@]}"; do
          if setup_wireguard "$config" && test_connection && validate_no_leaks; then
            echo "Successfully connected with: $config"
            echo "VPN is active. Monitoring connection..."
            
            # Keep the connection alive and monitor it
            check_counter=0
            NS_EXEC=""
            if [ "${toString cfg.proton.useNetworkNamespace}" = "1" ]; then
              NS_EXEC="ip netns exec ${cfg.proton.namespaceName}"
            fi
            while true; do
              sleep 30
              check_counter=$((check_counter + 1))

              # Check if interface still exists (inside namespace if applicable)
              if ! $NS_EXEC ip link show ${cfg.proton.interfaceName} &>/dev/null; then
                echo "Interface disappeared. Restarting..."
                exit 1
              fi

              # Check if we still have a recent handshake
              LAST_HANDSHAKE=$($NS_EXEC wg show ${cfg.proton.interfaceName} latest-handshakes | ${pkgs.gawk}/bin/awk '{print $2}' 2>/dev/null)
              if [ -n "$LAST_HANDSHAKE" ]; then
                CURRENT_TIME=$(date +%s)
                TIME_DIFF=$((CURRENT_TIME - LAST_HANDSHAKE))

                if [ "$TIME_DIFF" -gt 180 ]; then
                  echo "No recent handshake ($TIME_DIFF s ago). Connection may be dead. Restarting..."
                  exit 1
                fi
              else
                echo "Could not get handshake info. Connection may be dead. Restarting..."
                exit 1
              fi
              
              # Every 2 minutes, do comprehensive connectivity test
              if [ $((check_counter % 4)) -eq 0 ]; then
                echo "Performing periodic connectivity check..."
                if ! test_connection; then
                  echo "Connectivity test failed. Restarting..."
                  exit 1
                fi
                
                # Every 10 minutes, do leak detection test
                if [ $((check_counter % 20)) -eq 0 ]; then
                  if ! validate_no_leaks; then
                    echo "CRITICAL: Leak detected! Restarting VPN immediately..."
                    exit 1
                  fi
                fi
              fi
            done
          else
            echo "Failed to connect with: $config"
            ip link del ${cfg.proton.interfaceName} 2>/dev/null || true
          fi
        done
        
        echo "All VPN configs failed. Will retry in ${toString cfg.proton.retryInterval} seconds..."
        exit 1
      '';
      
      preStop = ''
        ${pkgs.iproute2}/bin/ip link del ${cfg.proton.interfaceName} 2>/dev/null || true
        if [ "${toString cfg.proton.useNetworkNamespace}" = "1" ]; then
          ${pkgs.iproute2}/bin/ip netns del ${cfg.proton.namespaceName} 2>/dev/null || true
        fi
      '';
    };
    
    # ProtonVPN Port Forwarding service
    systemd.services.aargh-portforward = mkIf (cfg.proton.enable && cfg.proton.enablePortForwarding) {
      description = "Aargh ProtonVPN Port Forwarding";
      after = [ "aargh-protonvpn.service" ];
      requires = [ "aargh-protonvpn.service" ];
      wantedBy = [ "multi-user.target" ];
      
      path = with pkgs; [ libnatpmp curl iproute2 ];
      
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "10s";
        
        # Security settings
        DynamicUser = true;
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        
        # State directory for port info
        StateDirectory = "aargh-portforward";
        StateDirectoryMode = "0755";
      };
      
      script = ''
        set -euo pipefail
        
        PORT_FILE="/var/lib/aargh-portforward/forwarded_port"
        
        # Function to request port forwarding
        request_port_forwarding() {
          echo "Requesting port forwarding from ProtonVPN..."
          
          # Wait for VPN interface to be fully up
          for i in {1..30}; do
            if ip link show ${cfg.proton.interfaceName} &>/dev/null; then
              break
            fi
            echo "Waiting for VPN interface..."
            sleep 2
          done
          
          # Get local IP on VPN interface
          VPN_LOCAL_IP=$(ip -4 addr show ${cfg.proton.interfaceName} | grep inet | awk '{print $2}' | cut -d'/' -f1)
          if [ -z "$VPN_LOCAL_IP" ]; then
            echo "Error: Could not determine VPN local IP"
            return 1
          fi
          
          echo "VPN Local IP: $VPN_LOCAL_IP"
          echo "Gateway IP: ${cfg.proton.portForwardingGateway}"
          
          # Request port mapping using NAT-PMP
          # This requests a random port mapping for 60 seconds
          OUTPUT=$(natpmpc -g ${cfg.proton.portForwardingGateway} -a 0 0 tcp 60 2>&1)
          
          if echo "$OUTPUT" | grep -q "Mapped public port"; then
            # Extract the mapped port from output
            EXTERNAL_PORT=$(echo "$OUTPUT" | grep "Mapped public port" | awk '{print $4}')
            INTERNAL_PORT=$(echo "$OUTPUT" | grep "to local port" | awk '{print $4}')
            
            echo "Port forwarding successful!"
            echo "External port: $EXTERNAL_PORT"
            echo "Internal port: $INTERNAL_PORT"
            
            # Save port info
            echo "$EXTERNAL_PORT" > "$PORT_FILE"
            
            return 0
          else
            echo "Port forwarding request failed: $OUTPUT"
            return 1
          fi
        }
        
        # Function to maintain port forwarding
        maintain_port_forwarding() {
          while true; do
            if request_port_forwarding; then
              # Refresh every 45 seconds (mapping lasts 60 seconds)
              sleep 45
            else
              echo "Port forwarding failed, retrying in 30 seconds..."
              sleep 30
            fi
          done
        }
        
        echo "Starting ProtonVPN port forwarding service..."
        maintain_port_forwarding
      '';
    };
    
    # Deluge service configuration
    services.deluge = mkIf cfg.deluge.enable {
      enable = true;
      web.enable = true;
      web.port = cfg.deluge.webPort;
      
      openFilesLimit = cfg.deluge.openFilesLimit;
    };
    
    # Ensure Deluge starts after VPN is up
    systemd.services.deluged = mkIf cfg.deluge.enable {
      after = [ "aargh-protonvpn.service" ];
      requires = [ "aargh-protonvpn.service" ];
      
      # Additional binding configuration
      serviceConfig = mkMerge [
        { RestartSec = "10s"; }
        (mkIf cfg.proton.useNetworkNamespace {
          # Use systemd's native namespace support — no extra capabilities needed.
          # ip netns add creates the namespace at /run/netns/<name>.
          NetworkNamespacePath = "/run/netns/${cfg.proton.namespaceName}";
        })
      ];
      
      # Configure Deluge to use VPN interface
      preStart = ''
        mkdir -p /var/lib/deluge/.config/deluge

        ${if cfg.proton.useNetworkNamespace then ''
          # Namespace mode: preStart runs inside the VPN namespace (NetworkNamespacePath
          # applies to all exec commands). Wait for protonvpn interface to have an IP,
          # then bind Deluge explicitly to it.
          echo "Waiting for VPN interface..."
          VPN_IP=""
          for i in {1..60}; do
            if ${pkgs.iproute2}/bin/ip link show ${cfg.proton.interfaceName} &>/dev/null; then
              VPN_IP=$(${pkgs.iproute2}/bin/ip -4 addr show ${cfg.proton.interfaceName} | grep inet | ${pkgs.gawk}/bin/awk '{print $2}' | cut -d'/' -f1)
              if [ -n "$VPN_IP" ]; then
                echo "VPN interface ready: $VPN_IP"
                break
              fi
            fi
            sleep 1
          done
          if [ -z "$VPN_IP" ]; then
            echo "Error: VPN interface never got an IP"
            exit 1
          fi

          cat > /var/lib/deluge/.config/deluge/core.conf.tmp <<EOF
{"file": 1, "format": 1}
{"listen_interface": "$VPN_IP", "outgoing_interface": "${cfg.proton.interfaceName}", "upnp": false, "natpmp": false, "enabled_plugins": ["Label"]}
EOF
        '' else ''
          # Non-namespace mode: bind deluge explicitly to the VPN interface IP.
          for i in {1..30}; do
            if ${pkgs.iproute2}/bin/ip link show ${cfg.proton.interfaceName} &>/dev/null; then
              echo "VPN interface is up"
              break
            fi
            echo "Waiting for VPN interface..."
            sleep 1
          done

          VPN_IP=$(${pkgs.iproute2}/bin/ip -4 addr show ${cfg.proton.interfaceName} | grep inet | ${pkgs.gawk}/bin/awk '{print $2}' | cut -d'/' -f1)
          if [ -z "$VPN_IP" ]; then
            echo "Warning: Could not determine VPN IP address"
            exit 1
          fi
          echo "Binding Deluge to VPN IP: $VPN_IP"
          cat > /var/lib/deluge/.config/deluge/core.conf.tmp <<EOF
{"file": 1, "format": 1}
{"listen_interface": "$VPN_IP", "outgoing_interface": "${cfg.proton.interfaceName}", "upnp": false, "natpmp": false, "enabled_plugins": ["Label"]}
EOF
        ''}
        mv /var/lib/deluge/.config/deluge/core.conf.tmp /var/lib/deluge/.config/deluge/core.conf
        chown -R deluge:deluge /var/lib/deluge/.config
        # Ensure download dir is group-readable so sonarr can import completed files
        mkdir -p ${cfg.deluge.downloadDir}
        chmod 775 ${cfg.deluge.downloadDir}
        chown deluge:deluge ${cfg.deluge.downloadDir}
      '';
    };
    
    # Bridge service to connect default namespace to VPN namespace
    systemd.services.aargh-deluge-bridge = mkIf (cfg.deluge.enable && cfg.proton.useNetworkNamespace) {
      description = "Bridge Deluge daemon in VPN namespace to default namespace";
      after = [ "deluged.service" ];
      requires = [ "deluged.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = let
        bridgeScript = pkgs.writeShellScript "deluge-ns-bridge" ''
          DPID=$(${pkgs.systemd}/bin/systemctl show deluged -p MainPID --value)
          exec ${pkgs.util-linux}/bin/nsenter -t "$DPID" -n \
            ${pkgs.socat}/bin/socat STDIO \
            TCP-CONNECT:127.0.0.1:${toString cfg.deluge.daemonPort}
        '';
      in {
        Type = "simple";
        Restart = "always";
        RestartSec = "5s";
        ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:${toString cfg.deluge.daemonPort},reuseaddr,fork EXEC:${bridgeScript}";
      };
    };
    
    systemd.services.deluge-web = mkIf cfg.deluge.enable {
      description = "Deluge BitTorrent Web Interface";
      wantedBy = [ "multi-user.target" ];
      after = if cfg.proton.useNetworkNamespace
              then [ "deluged.service" "aargh-deluge-bridge.service" ]
              else [ "deluged.service" ];
      requires = if cfg.proton.useNetworkNamespace
                 then [ "deluged.service" "aargh-deluge-bridge.service" ]
                 else [ "deluged.service" ];
      serviceConfig = {
        ExecStart = mkForce "${pkgs.deluge}/bin/deluge-web --do-not-daemonize --port ${toString cfg.deluge.webPort}";
        User = "deluge";
        Group = "deluge";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
    
    # Service to monitor port forwarding changes and update Deluge
    systemd.services.aargh-deluge-port-updater = mkIf (cfg.deluge.enable && cfg.proton.enablePortForwarding) {
      description = "Update Deluge with forwarded port changes";
      after = [ "deluged.service" "aargh-portforward.service" ];
      requires = [ "deluged.service" ];
      wants = [ "aargh-portforward.service" ];
      wantedBy = [ "multi-user.target" ];
      
      path = with pkgs; [ curl jq inotify-tools ];
      
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "10s";
        User = "deluge";
        Group = "deluge";
      };
      
      script = ''
        set -euo pipefail
        
        PORT_FILE="/var/lib/aargh-portforward/forwarded_port"
        LAST_PORT=""
        
        update_deluge_port() {
          local new_port=$1
          echo "Updating Deluge to use port: $new_port"
          
          # Update Deluge daemon configuration via API
          # Note: This requires the daemon to be running
          for i in {1..30}; do
            if curl -s http://localhost:${toString cfg.deluge.webPort} > /dev/null 2>&1; then
              break
            fi
            echo "Waiting for Deluge web interface..."
            sleep 2
          done
          
          # Get Deluge session state and update port
          curl -X POST http://localhost:${toString cfg.deluge.webPort}/json \
            -H "Content-Type: application/json" \
            -d "{\"method\": \"core.set_config\", \"params\": [{\"listen_ports\": [$new_port, $new_port], \"random_port\": false}], \"id\": 1}" \
            2>/dev/null || echo "Failed to update Deluge port via API"
        }
        
        echo "Monitoring port forwarding changes for Deluge..."
        
        # Initial port check
        if [ -f "$PORT_FILE" ]; then
          CURRENT_PORT=$(cat "$PORT_FILE" 2>/dev/null || echo "")
          if [ -n "$CURRENT_PORT" ] && [ "$CURRENT_PORT" != "$LAST_PORT" ]; then
            update_deluge_port "$CURRENT_PORT"
            LAST_PORT="$CURRENT_PORT"
          fi
        fi
        
        # Monitor for port file changes
        while true; do
          if inotifywait -e modify,create "$PORT_FILE" 2>/dev/null; then
            sleep 2  # Give time for file write to complete
            
            if [ -f "$PORT_FILE" ]; then
              NEW_PORT=$(cat "$PORT_FILE" 2>/dev/null || echo "")
              if [ -n "$NEW_PORT" ] && [ "$NEW_PORT" != "$LAST_PORT" ]; then
                update_deluge_port "$NEW_PORT"
                LAST_PORT="$NEW_PORT"
              fi
            fi
          fi
        done
      '';
    };
    
    # Sonarr service configuration
    services.sonarr = mkIf cfg.sonarr.enable {
      enable = true;
      dataDir = cfg.sonarr.dataDir;
    };
    
    systemd.services.sonarr = mkIf cfg.sonarr.enable {
      after = [ "deluged.service" ];
      wants = [ "deluged.service" ];
      
      # Configure Sonarr settings
      preStart = ''
        mkdir -p ${cfg.sonarr.dataDir}
        mkdir -p ${cfg.sonarr.tvDir}
        chown -R sonarr:sonarr ${cfg.sonarr.dataDir}
        
        # Wait for Deluge to be ready
        for i in {1..30}; do
          if ${pkgs.curl}/bin/curl -s http://localhost:${toString cfg.deluge.webPort} > /dev/null 2>&1; then
            echo "Deluge web interface is ready"
            break
          fi
          echo "Waiting for Deluge web interface..."
          sleep 2
        done
        
        # Configure Sonarr config if it doesn't exist
        CONFIG_FILE="${cfg.sonarr.dataDir}/config.xml"
        if [ ! -f "$CONFIG_FILE" ]; then
          cat > "$CONFIG_FILE" <<EOF
<Config>
  <Port>${toString cfg.sonarr.port}</Port>
  <SslPort>9898</SslPort>
  <EnableSsl>False</EnableSsl>
  <LaunchBrowser>False</LaunchBrowser>
  <ApiKey></ApiKey>
  <AuthenticationMethod>None</AuthenticationMethod>
  <AuthenticationRequired>DisabledForLocalAddresses</AuthenticationRequired>
  <Branch>main</Branch>
  <LogLevel>Info</LogLevel>
  <SslCertPath></SslCertPath>
  <SslCertPassword></SslCertPassword>
  <UrlBase></UrlBase>
  <InstanceName>Sonarr</InstanceName>
</Config>
EOF
          chown sonarr:sonarr "$CONFIG_FILE"
        fi
      '';
    };
    
    # Configure Sonarr via API after startup
    systemd.services.aargh-sonarr-configure = mkIf (cfg.sonarr.enable && cfg.deluge.enable) {
      description = "Configure Sonarr download client and root folder";
      after = [ "sonarr.service" ];
      wants = [ "sonarr.service" ];
      wantedBy = [ "multi-user.target" ];

      path = with pkgs; [ curl jq gawk ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "sonarr";
        Group = "sonarr";
      };

      script = ''
        set -euo pipefail

        SONARR_URL="http://localhost:${toString cfg.sonarr.port}"

        # Wait for Sonarr API to be ready
        echo "Waiting for Sonarr API..."
        for i in {1..60}; do
          API_KEY=$(awk -F '[<>]' '/<ApiKey>/{print $3}' ${cfg.sonarr.dataDir}/config.xml 2>/dev/null || true)
          if [ -n "$API_KEY" ] && curl -sf "$SONARR_URL/api/v3/system/status" -H "X-Api-Key: $API_KEY" > /dev/null 2>&1; then
            echo "Sonarr API ready"
            break
          fi
          sleep 2
        done

        # Configure Deluge download client
        CLIENTS=$(curl -sf "$SONARR_URL/api/v3/downloadclient" -H "X-Api-Key: $API_KEY")
        if echo "$CLIENTS" | jq -e '.[] | select(.name == "Deluge")' > /dev/null 2>&1; then
          echo "Deluge download client already configured"
        else
          echo "Adding Deluge download client..."
          curl -sf -X POST "$SONARR_URL/api/v3/downloadclient" \
            -H "X-Api-Key: $API_KEY" \
            -H "Content-Type: application/json" \
            -d '{
              "enable": true,
              "protocol": "torrent",
              "priority": 1,
              "name": "Deluge",
              "fields": [
                {"name": "host", "value": "localhost"},
                {"name": "port", "value": ${toString cfg.deluge.webPort}},
                {"name": "urlBase", "value": ""},
                {"name": "password", "value": "${cfg.deluge.webPassword}"},
                {"name": "category", "value": ""},
                {"name": "recentTvPriority", "value": 0},
                {"name": "olderTvPriority", "value": 0},
                {"name": "addPaused", "value": false}
              ],
              "implementationName": "Deluge",
              "implementation": "Deluge",
              "configContract": "DelugeSettings",
              "tags": []
            }'
          echo "Deluge download client added"
        fi

        # Configure TV root folder
        FOLDERS=$(curl -sf "$SONARR_URL/api/v3/rootfolder" -H "X-Api-Key: $API_KEY")
        if echo "$FOLDERS" | jq -e --arg p "${cfg.sonarr.tvDir}" '.[] | select(.path == $p)' > /dev/null 2>&1; then
          echo "Root folder already configured"
        else
          echo "Adding root folder ${cfg.sonarr.tvDir}..."
          curl -sf -X POST "$SONARR_URL/api/v3/rootfolder" \
            -H "X-Api-Key: $API_KEY" \
            -H "Content-Type: application/json" \
            -d "{\"path\": \"${cfg.sonarr.tvDir}\"}"
          echo "Root folder added"
        fi
      '';
    };

    # Prowlarr indexer manager
    services.prowlarr = mkIf cfg.prowlarr.enable {
      enable = true;
      openFirewall = false;
    };

    systemd.services.prowlarr = mkIf cfg.prowlarr.enable {
      after = [ "sonarr.service" ];
      wants = [ "sonarr.service" ];

      # Disable auth for local addresses (same as Sonarr)
      preStart = lib.mkAfter ''
        CONFIG_FILE="${cfg.prowlarr.dataDir}/config.xml"
        if [ -f "$CONFIG_FILE" ]; then
          ${pkgs.gnused}/bin/sed -i \
            -e 's|<AuthenticationMethod>[^<]*</AuthenticationMethod>|<AuthenticationMethod>External</AuthenticationMethod>|' \
            -e 's|<AuthenticationRequired>[^<]*</AuthenticationRequired>|<AuthenticationRequired>DisabledForLocalAddresses</AuthenticationRequired>|' \
            "$CONFIG_FILE"
        fi
      '';
    };

    # Wire Prowlarr → Sonarr automatically
    systemd.services.aargh-prowlarr-configure = mkIf (cfg.prowlarr.enable && cfg.sonarr.enable) {
      description = "Connect Prowlarr to Sonarr";
      after = [ "prowlarr.service" "sonarr.service" ];
      wants = [ "prowlarr.service" "sonarr.service" ];
      wantedBy = [ "multi-user.target" ];

      path = with pkgs; [ curl jq gawk ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        set -euo pipefail

        PROWLARR_URL="http://localhost:${toString cfg.prowlarr.port}"
        SONARR_URL="http://localhost:${toString cfg.sonarr.port}"

        # Wait for Prowlarr API
        echo "Waiting for Prowlarr API..."
        for i in {1..60}; do
          PROWLARR_KEY=$(awk -F '[<>]' '/<ApiKey>/{print $3}' ${cfg.prowlarr.dataDir}/config.xml 2>/dev/null || true)
          if [ -n "$PROWLARR_KEY" ] && curl -sf "$PROWLARR_URL/api/v1/system/status" -H "X-Api-Key: $PROWLARR_KEY" > /dev/null 2>&1; then
            echo "Prowlarr API ready"
            break
          fi
          sleep 2
        done

        # Get Sonarr API key
        SONARR_KEY=$(awk -F '[<>]' '/<ApiKey>/{print $3}' ${cfg.sonarr.dataDir}/config.xml)

        # Check if Sonarr is already added as an application
        APPS=$(curl -sf "$PROWLARR_URL/api/v1/applications" -H "X-Api-Key: $PROWLARR_KEY")
        if echo "$APPS" | jq -e '.[] | select(.name == "Sonarr")' > /dev/null 2>&1; then
          echo "Sonarr already configured in Prowlarr"
        else
          echo "Adding Sonarr to Prowlarr..."
          curl -sf -X POST "$PROWLARR_URL/api/v1/applications" \
            -H "X-Api-Key: $PROWLARR_KEY" \
            -H "Content-Type: application/json" \
            -d "{
              \"name\": \"Sonarr\",
              \"implementation\": \"Sonarr\",
              \"configContract\": \"SonarrSettings\",
              \"syncLevel\": \"addOnly\",
              \"fields\": [
                {\"name\": \"prowlarrUrl\", \"value\": \"$PROWLARR_URL\"},
                {\"name\": \"baseUrl\", \"value\": \"$SONARR_URL\"},
                {\"name\": \"apiKey\", \"value\": \"$SONARR_KEY\"},
                {\"name\": \"syncCategories\", \"value\": [5000,5010,5020,5030,5040,5045,5050,5090]},
                {\"name\": \"animeSyncCategories\", \"value\": [5070]},
                {\"name\": \"syncLevel\", \"value\": \"addOnly\"}
              ],
              \"tags\": []
            }"
          echo "Sonarr added to Prowlarr"
        fi

        # Add public indexers
        EXISTING_INDEXERS=$(curl -sf "$PROWLARR_URL/api/v1/indexer" -H "X-Api-Key: $PROWLARR_KEY")
        SCHEMA=$(curl -sf "$PROWLARR_URL/api/v1/indexer/schema" -H "X-Api-Key: $PROWLARR_KEY")

        add_indexer() {
          local defName=$1
          # Look up display name and implementation from schema
          local name
          name=$(echo "$SCHEMA" | jq -r --arg d "$defName" '.[] | select(.definitionName == $d) | .name' | head -1)
          if [ -z "$name" ]; then
            echo "Warning: no schema found for $defName, skipping"
            return
          fi
          if echo "$EXISTING_INDEXERS" | jq -e --arg n "$name" '.[] | select(.name == $n)' > /dev/null 2>&1; then
            echo "$name already added"
          else
            echo "Adding indexer: $name ($defName)..."
            resp=$(curl -s -w "\n%{http_code}" -X POST "$PROWLARR_URL/api/v1/indexer" \
              -H "X-Api-Key: $PROWLARR_KEY" \
              -H "Content-Type: application/json" \
              -d "{
                \"name\": \"$name\",
                \"implementation\": \"Cardigann\",
                \"configContract\": \"CardigannSettings\",
                \"enable\": true,
                \"protocol\": \"torrent\",
                \"priority\": 25,
                \"appProfileId\": 1,
                \"fields\": [{\"name\": \"definitionFile\", \"value\": \"$defName\"}],
                \"tags\": []
              }")
            http_code=$(echo "$resp" | tail -1)
            if [ "$http_code" = "201" ]; then
              echo "$name added"
            else
              echo "Warning: failed to add $name (HTTP $http_code): $(echo "$resp" | head -1 | jq -r '.[0].errorMessage // .' 2>/dev/null)"
            fi
          fi
        }

        ${lib.concatMapStrings (d: "add_indexer ${lib.escapeShellArg d}\n") cfg.prowlarr.indexers}
      '';
    };

    # Overseerr service configuration
    systemd.services.overseerr = mkIf cfg.overseerr.enable {
      description = "Overseerr request management service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "sonarr.service" ];
      wants = [ "network-online.target" ];
      
      serviceConfig = {
        Type = "simple";
        User = "overseerr";
        Group = "overseerr";
        ExecStart = "${pkgs.overseerr}/bin/overseerr";
        Restart = "on-failure";
        RestartSec = "5s";
        
        # Security settings
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ReadWritePaths = [ cfg.overseerr.dataDir ];
      };
      
      environment = {
        CONFIG_DIRECTORY = cfg.overseerr.dataDir;
        PORT = toString cfg.overseerr.port;
      };
      
      preStart = ''
        mkdir -p ${cfg.overseerr.dataDir}
        chown overseerr:overseerr ${cfg.overseerr.dataDir}
      '';
    };
    
    # Give sonarr read access to deluge's download dir so it can import completed files
    users.users.sonarr = mkIf (cfg.sonarr.enable && cfg.deluge.enable) {
      extraGroups = [ "deluge" ];
    };

    # Create users for services
    users.users.overseerr = mkIf cfg.overseerr.enable {
      isSystemUser = true;
      group = "overseerr";
      home = cfg.overseerr.dataDir;
    };
    
    users.groups.overseerr = mkIf cfg.overseerr.enable { };
    
    # Service integration configuration
    systemd.services.aargh-configure = mkIf (cfg.sonarr.enable && cfg.deluge.enable) {
      description = "Configure Aargh service integrations";
      wantedBy = [ "multi-user.target" ];
      after = [ "sonarr.service" "deluged.service" "deluge-web.service" ];
      wants = [ "sonarr.service" "deluged.service" "deluge-web.service" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      
      path = with pkgs; [ curl jq inotify-tools ];
      
      script = ''
        set -euo pipefail
        
        echo "Configuring Aargh service integrations..."
        
        # Wait for services to be fully ready
        echo "Waiting for Sonarr..."
        for i in {1..60}; do
          if curl -s http://localhost:${toString cfg.sonarr.port}/api/v3/system/status > /dev/null 2>&1; then
            echo "Sonarr is ready"
            break
          fi
          sleep 2
        done
        
        echo "Waiting for Deluge..."
        for i in {1..60}; do
          if curl -s http://localhost:${toString cfg.deluge.webPort} > /dev/null 2>&1; then
            echo "Deluge is ready"
            break
          fi
          sleep 2
        done
        
        # Configure Deluge as download client in Sonarr
        echo "Configuring Sonarr to use Deluge..."
        
        # Check if Deluge download client already exists
        EXISTING_CLIENT=$(curl -s http://localhost:${toString cfg.sonarr.port}/api/v3/downloadclient | jq -r '.[] | select(.name == "Deluge") | .id // empty' || echo "")
        
        if [ -z "$EXISTING_CLIENT" ]; then
          echo "Adding Deluge as download client..."
          curl -X POST http://localhost:${toString cfg.sonarr.port}/api/v3/downloadclient \
            -H "Content-Type: application/json" \
            -d '{
              "enable": true,
              "protocol": "torrent",
              "priority": 1,
              "removeCompletedDownloads": false,
              "removeFailedDownloads": true,
              "name": "Deluge",
              "fields": [
                {"name": "host", "value": "localhost"},
                {"name": "port", "value": ${toString cfg.deluge.daemonPort}},
                {"name": "password", "value": "deluge"},
                {"name": "tvCategory", "value": "tv-sonarr"},
                {"name": "recentTvPriority", "value": 0},
                {"name": "olderTvPriority", "value": 0},
                {"name": "addPaused", "value": false},
                {"name": "useSsl", "value": false}
              ],
              "implementationName": "Deluge",
              "implementation": "Deluge",
              "configContract": "DelugeSettings",
              "tags": []
            }' || echo "Failed to add Deluge client (may already exist)"
        else
          echo "Deluge download client already configured"
        fi
        
        echo "Aargh service integration configuration complete!"
      '';
    };
    
    # Firewall configuration
    networking.firewall = mkIf cfg.enable {
      allowedTCPPorts = 
        (lib.optionals cfg.deluge.enable [ 
          cfg.deluge.webPort 
          cfg.deluge.daemonPort 
        ]) ++
        (lib.optionals cfg.sonarr.enable [ cfg.sonarr.port ]) ++
        (lib.optionals cfg.overseerr.enable [ cfg.overseerr.port ]);
    };
    
    # Create directories
    systemd.tmpfiles.rules = 
      (lib.optionals cfg.deluge.enable [
        "d ${cfg.deluge.downloadDir} 0755 deluge deluge -"
      ]) ++
      (lib.optionals cfg.sonarr.enable [
        "d ${cfg.sonarr.dataDir} 0755 sonarr sonarr -"
        "d ${cfg.sonarr.tvDir} 0755 sonarr sonarr -"
      ]) ++
      (lib.optionals cfg.overseerr.enable [
        "d ${cfg.overseerr.dataDir} 0755 overseerr overseerr -"
      ]);
  };
}
