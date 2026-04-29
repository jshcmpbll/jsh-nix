{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.firecrawl;

  firecrawl-python = pkgs.python311.withPackages (ps: with ps; [
    playwright
    fastapi
    uvicorn
    html2text
    httpx
    anyio
  ]);

  firecrawl-script = pkgs.writeTextFile {
    name = "firecrawl-shim";
    destination = "/firecrawl_shim.py";
    text = ''
      import asyncio
      import html as html_module
      import os
      import re
      from typing import Any, Dict, List

      import html2text
      import httpx
      import uvicorn
      from fastapi import FastAPI, Request
      from playwright.async_api import async_playwright

      app = FastAPI()

      _playwright_ctx = None
      _browser = None
      _lock = asyncio.Lock()

      SEARXNG_URL = os.getenv("SEARXNG_URL", "")

      CHROMIUM_ARGS = [
          "--no-sandbox",
          "--disable-setuid-sandbox",
          "--disable-dev-shm-usage",
          "--disable-accelerated-2d-canvas",
          "--no-first-run",
          "--no-zygote",
          "--disable-gpu",
      ]

      async def get_browser():
          global _playwright_ctx, _browser
          async with _lock:
              if _browser is None or not _browser.is_connected():
                  _playwright_ctx = await async_playwright().start()
                  _browser = await _playwright_ctx.chromium.launch(
                      headless=True,
                      args=CHROMIUM_ARGS,
                  )
          return _browser


      def extract_title(html_content: str) -> str:
          m = re.search(r"<title[^>]*>(.*?)</title>", html_content, re.IGNORECASE | re.DOTALL)
          return html_module.unescape(m.group(1).strip()) if m else ""


      def to_markdown(html_content: str, strip_nav: bool = False) -> str:
          h = html2text.HTML2Text()
          h.ignore_links = False
          h.ignore_images = True
          h.body_width = 0
          md = h.handle(html_content)
          if strip_nav:
              # Drop leading lines that are nav/menu noise (short link-heavy lines)
              # Find the first paragraph-like line (>80 chars or looks like prose)
              lines = md.splitlines()
              start = 0
              consecutive_short = 0
              for i, line in enumerate(lines):
                  stripped = line.strip()
                  if len(stripped) > 100:
                      start = i
                      break
                  if stripped and not stripped.startswith("#"):
                      consecutive_short += 1
                  else:
                      consecutive_short = 0
              md = "\n".join(lines[start:])
          return md


      async def do_scrape(url: str, formats: List[str], timeout_ms: int) -> Dict[str, Any]:
          browser = await get_browser()
          context = await browser.new_context(
              user_agent=(
                  "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
                  "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
              ),
          )
          page = await context.new_page()
          try:
              response = await page.goto(url, wait_until="networkidle", timeout=timeout_ms)
              html_content = await page.content()
              status_code = response.status if response else 200
          finally:
              await page.close()
              await context.close()

          result: Dict[str, Any] = {
              "metadata": {
                  "title": extract_title(html_content),
                  "sourceURL": url,
                  "statusCode": status_code,
              }
          }
          if "markdown" in formats or not formats:
              result["markdown"] = to_markdown(html_content)
          if "html" in formats:
              result["html"] = html_content
          if "rawHtml" in formats:
              result["rawHtml"] = html_content

          return {"success": True, "data": result}


      async def scrape_text(url: str, max_chars: int = 4000) -> str:
          try:
              browser = await get_browser()
              context = await browser.new_context(
                  user_agent=(
                      "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
                      "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
                  ),
              )
              page = await context.new_page()
              try:
                  await page.goto(url, wait_until="networkidle", timeout=15000)
                  html_content = await page.content()
              finally:
                  await page.close()
                  await context.close()
              md = to_markdown(html_content, strip_nav=True)
              lines = [l for l in md.splitlines() if l.strip()]
              text = "\n".join(lines)
              return text[:max_chars]
          except Exception:
              return ""


      async def do_search(query: str, limit: int) -> Dict[str, Any]:
          if not SEARXNG_URL:
              return {
                  "success": False,
                  "error": (
                      "web_search is not available (no search API configured). "
                      "If you have a specific URL, use web_extract with that URL instead."
                  ),
                  "data": [],
              }

          params = {
              "q": query,
              "format": "json",
              "categories": "general",
          }
          async with httpx.AsyncClient(timeout=15.0) as client:
              resp = await client.get(SEARXNG_URL + "/search", params=params)
              resp.raise_for_status()
              data = resp.json()

          results = data.get("results", [])[:limit]

          # Scrape the top result to include inline content
          top_content = ""
          if results:
              top_content = await scrape_text(results[0].get("url", ""), max_chars=3000)

          formatted = []
          for i, r in enumerate(results):
              entry = {
                  "url": r.get("url", ""),
                  "title": r.get("title", ""),
                  "description": r.get("content", ""),
              }
              if i == 0 and top_content:
                  entry["content"] = top_content
              formatted.append(entry)

          return {"success": True, "data": formatted}


      @app.post("/v1/scrape")
      @app.post("/v2/scrape")
      async def scrape(request: Request):
          body = await request.json()
          url = body.get("url", "")
          formats: List[str] = body.get("formats", ["markdown"])
          timeout_ms = int(body.get("timeout", 30000))
          return await do_scrape(url, formats, timeout_ms)


      @app.post("/v1/search")
      @app.post("/v2/search")
      async def search(request: Request):
          body = await request.json()
          query = body.get("query", "")
          limit = int(body.get("limit", body.get("numResults", 5)))
          return await do_search(query, limit)


      @app.get("/health")
      async def health():
          return {"status": "healthy"}


      if __name__ == "__main__":
          host = os.getenv("HOST", "127.0.0.1")
          port = int(os.getenv("PORT", "3002"))
          uvicorn.run(app, host=host, port=port)
    '';
  };

in
{
  options.services.firecrawl = {
    enable = mkEnableOption "Firecrawl web scraping service (playwright-python shim)";

    port = mkOption {
      type = types.port;
      default = 3002;
      description = "Port for the Firecrawl API to listen on.";
    };

    listenAddress = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Address to bind the Firecrawl API to.";
    };

    searxngUrl = mkOption {
      type = types.str;
      default = "";
      description = "Base URL of a SearXNG instance for web_search. Empty disables search.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open firewall for the Firecrawl API port.";
    };
  };

  config = mkIf cfg.enable {
    users.users.firecrawl = {
      isSystemUser = true;
      group = "firecrawl";
      description = "Firecrawl service user";
    };
    users.groups.firecrawl = { };

    systemd.services.firecrawl = {
      description = "Firecrawl web scraping API (playwright-python)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
        HOST = cfg.listenAddress;
        PORT = toString cfg.port;
        SEARXNG_URL = cfg.searxngUrl;
      };

      serviceConfig = {
        Type = "simple";
        User = "firecrawl";
        Group = "firecrawl";
        ExecStart = "${firecrawl-python}/bin/python ${firecrawl-script}/firecrawl_shim.py";
        Restart = "on-failure";
        RestartSec = "5s";
        NoNewPrivileges = true;
        PrivateTmp = true;
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];
  };
}
