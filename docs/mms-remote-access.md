# mms Remote Access Plan

Expose privatarr services (Seerr, Sonarr, Radarr, Deluge) externally via rathole tunnel,
with OAuth2 authentication managed by Authentik.

## Architecture

```
Browser → rathole (TLS) → nginx (port 80) → services
                                ↕ auth_request
                           oauth2-proxy → Authentik → Google / GitHub / etc.
```

- **rathole** handles TLS termination on the server side — nginx on mms uses plain HTTP
- **nginx** reverse-proxies each service; virtualHost routing by `Host:` header lets rathole
  map each public subdomain to the right service
- **oauth2-proxy** sits between nginx and the services via `auth_request`; sessions are shared
  across all virtualHosts via a single cookie domain
- **Authentik** is the identity provider — manages users, sends invitation emails via ProtonMail SMTP,
  supports multiple upstream OAuth providers (Google, GitHub, etc.)

## Services and ports

| Service  | Internal port | Purpose              |
|----------|--------------|----------------------|
| Seerr    | 5055         | Family-facing request UI (has own auth) |
| Sonarr   | 8989         | TV management        |
| Radarr   | 7878         | Movie management     |
| Deluge   | 8112         | Torrent client       |
| Authentik | 9000        | Identity provider    |

## Authentik — NixOS module status

`services.authentik` is **not in nixpkgs 25.05 or unstable** as of April 2026.
It needs to come from an external flake. Find the correct flake URL before implementing
(likely `github:nix-community/authentik-nix` — verify before adding).

Requires PostgreSQL and Redis as dependencies (module may wire these up automatically).

## Nix config to add to mms/configuration.nix

```nix
sops.secrets."oauth2-proxy-env" = {};  # OAUTH2_PROXY_CLIENT_ID, CLIENT_SECRET, COOKIE_SECRET
sops.secrets."authentik-env" = {};     # see sops section below

services.postgresql = {
  enable = true;
  ensureDatabases = [ "authentik" ];
  ensureUsers = [{ name = "authentik"; ensureDBOwnership = true; }];
};

services.redis.servers.authentik = {
  enable = true;
  port = 6379;
};

services.authentik = {
  enable = true;
  environmentFile = config.sops.secrets."authentik-env".path;
  settings = {
    postgresql.host = "/run/postgresql";
    redis.host = "127.0.0.1";
    # email config lives in authentik-env sops secret
  };
};

services.oauth2-proxy = {
  enable = true;
  provider = "oidc";
  oidcIssuerUrl = "http://localhost:9000/application/o/privatarr/";
  keyFile = config.sops.secrets."oauth2-proxy-env".path;
  cookie.secure = true;
  upstream = [ "static://202" ];
  nginx.virtualHosts = { "seerr" = {}; "sonarr" = {}; "radarr" = {}; "deluge" = {}; };
};

services.nginx = {
  enable = true;
  recommendedProxySettings = true;
  virtualHosts = {
    "seerr"  = { default = true; locations."/" = { proxyPass = "http://127.0.0.1:5055"; proxyWebsockets = true; }; };
    "sonarr" = { locations."/" = { proxyPass = "http://127.0.0.1:8989"; proxyWebsockets = true; }; };
    "radarr" = { locations."/" = { proxyPass = "http://127.0.0.1:7878"; proxyWebsockets = true; }; };
    "deluge" = { locations."/" = { proxyPass = "http://127.0.0.1:8112"; proxyWebsockets = true; }; };
  };
};
```

## sops secrets required

### `authentik-env`

```
AUTHENTIK_SECRET_KEY=<generate: python3 -c 'import os,base64; print(base64.b64encode(os.urandom(60)).decode())'>
AUTHENTIK_EMAIL__HOST=smtp.protonmail.ch
AUTHENTIK_EMAIL__PORT=587
AUTHENTIK_EMAIL__USERNAME=me@jshcmpbll.com
AUTHENTIK_EMAIL__FROM=me@jshcmpbll.com
AUTHENTIK_EMAIL__USE_TLS=true
AUTHENTIK_EMAIL__PASSWORD=<protonmail smtp token>
```

### `oauth2-proxy-env`

Get client ID/secret from Authentik after first boot (Applications → Providers → Create OAuth2/OIDC provider).

```
OAUTH2_PROXY_CLIENT_ID=<from Authentik>
OAUTH2_PROXY_CLIENT_SECRET=<from Authentik>
OAUTH2_PROXY_COOKIE_SECRET=<generate: python3 -c 'import os,base64; print(base64.b64encode(os.urandom(32)).decode())'>
```

## First-boot steps (Authentik)

1. Deploy config
2. Visit `http://jsh-mms:9000/if/flow/initial-setup/` to create admin account
3. Create an OAuth2/OIDC provider named `privatarr` — note the client ID and secret
4. Add those to `oauth2-proxy-env` sops secret and redeploy
5. Invite users via Users → Invitations — generates a link to send manually (or via email if SMTP configured)

## nginx virtualHost routing with rathole

Each public hostname in rathole should forward to `http://jsh-mms:80` with the corresponding
`Host:` header. Example rathole server config:

```toml
[server.services.seerr]
type = "http"
bind_addr = "0.0.0.0:80"

[server.services.sonarr]
type = "http"
bind_addr = "0.0.0.0:8081"
```

nginx then routes by `server_name` matching the public domain.
