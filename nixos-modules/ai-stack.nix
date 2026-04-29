{ config, lib, pkgs, latest2, ... }:

with lib;

let
  cfg = config.services.ai-stack;

  hermesProviderType = types.submodule {
    options = {
      baseUrl = mkOption {
        type = types.str;
        description = "OpenAI-compatible base URL for this provider.";
      };
      apiKey = mkOption {
        type = types.str;
        default = "";
        description = "API key (leave empty if not required).";
      };
      model = mkOption {
        type = types.str;
        default = "";
        description = "Default model name for this provider (optional).";
      };
      contextLength = mkOption {
        type = types.int;
        default = 0;
        description = "Context length override (0 = use hermes default).";
      };
    };
  };

  # Build the providers attrset for hermes config.yaml
  hermesProviders = mapAttrs (name: p: {
    base_url = p.baseUrl;
  } // optionalAttrs (p.apiKey != "") { api_key = p.apiKey; }
    // optionalAttrs (p.model != "") { model = p.model; }
    // optionalAttrs (p.contextLength > 0) { context_length = p.contextLength; }
  ) cfg.hermes.extraProviders;

  searxngUrl = "http://${cfg.searxng.listenAddress}:${toString cfg.searxng.port}";
  firecrawlUrl = "http://${cfg.firecrawl.listenAddress}:${toString cfg.firecrawl.port}";
  ollamaUrl = "http://127.0.0.1:${toString cfg.ollama.port}";

in
{
  options.services.ai-stack = {
    enable = mkEnableOption "Local AI stack (Ollama + Hermes + SearXNG + Firecrawl + Open WebUI)";

    ollama = {
      enable = mkOption { type = types.bool; default = true; };
      port = mkOption { type = types.port; default = 11434; };
      acceleration = mkOption {
        type = types.enum [ "cuda" "rocm" "none" ];
        default = "none";
        description = "GPU acceleration backend.";
      };
      keepAlive = mkOption { type = types.str; default = "30m"; };
      package = mkOption {
        type = types.nullOr types.package;
        default = null;
        description = "Ollama package override. Null uses the nixpkgs default.";
      };
    };

    searxng = {
      enable = mkOption { type = types.bool; default = true; };
      port = mkOption { type = types.port; default = 8888; };
      listenAddress = mkOption { type = types.str; default = "127.0.0.1"; };
    };

    firecrawl = {
      enable = mkOption { type = types.bool; default = true; };
      port = mkOption { type = types.port; default = 3002; };
      listenAddress = mkOption { type = types.str; default = "127.0.0.1"; };
    };

    hermes = {
      enable = mkOption { type = types.bool; default = true; };
      defaultModel = mkOption {
        type = types.str;
        default = "qwen2.5:32b";
        description = "Default Ollama model to use.";
      };
      contextLength = mkOption { type = types.int; default = 131072; };
      ollamaNumCtx = mkOption { type = types.int; default = 32768; };
      apiPort = mkOption { type = types.port; default = 8642; };
      systemPrompt = mkOption {
        type = types.str;
        default = "";
        description = "System prompt override. Empty uses the built-in default.";
      };
      extraProviders = mkOption {
        type = types.attrsOf hermesProviderType;
        default = { };
        description = "Additional named providers (e.g. kiro) passed to hermes config.";
        example = literalExpression ''
          {
            kiro = {
              baseUrl = "http://127.0.0.1:8000/v1";
            };
          }
        '';
      };
      environment = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Extra environment variables for the hermes service.";
      };
      environmentFiles = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Files containing additional environment variables (for secrets).";
      };
    };

    openWebUI = {
      enable = mkOption { type = types.bool; default = true; };
      openFirewall = mkOption { type = types.bool; default = false; };
      host = mkOption { type = types.str; default = "0.0.0.0"; };
    };
  };

  config = mkIf cfg.enable {

    # Build the provider-name list for the system prompt
    services.ai-stack.hermes.systemPrompt = mkDefault ''
      You are Hermes, a personal AI assistant running locally.

      ## Core behavior
      - Act immediately. Never ask "would you like me to..." or "shall I..." — just do it.
      - Answer directly with what you know or find. No preamble, no permission-seeking.
      - Do NOT suggest terminal commands for the user to run. Use your own tools (web_search, web_extract) to get information yourself.

      ## Inference providers
      - Default (${cfg.hermes.defaultModel} via Ollama): personal tasks, general questions, anything non-work.
      ${concatStringsSep "\n      " (mapAttrsToList (name: p:
        "- ${name} (${if p.model != "" then p.model else "custom"} via ${name}): switch with /model ${if p.model != "" then p.model else "..."} --provider ${name}"
      ) cfg.hermes.extraProviders)}

      ## Web access
      You have a self-hosted Firecrawl instance. You CAN fetch live web pages.
      - web_search: search by keyword. Results include title, URL, description, and full page content for the top result.
      - web_extract: fetch a specific URL and get its full content as markdown.

      ### Hard rules for web tool use
      1. READ the results you get before calling any tool again. The top search result includes full page content.
      2. Maximum 3 web_search calls per user request. Rephrasing the same query counts toward the limit.
      3. If searching twice hasn't worked, call web_extract on the best URL from your results — don't search again.
      4. Once you have relevant content, STOP calling tools and write your answer immediately.
      5. Never ask the user if they want you to search — just search, read, and answer.
    '';

    # --- Ollama ---
    services.ollama = mkIf cfg.ollama.enable ({
      enable = true;
      acceleration = if cfg.ollama.acceleration == "none" then null else cfg.ollama.acceleration;
      environmentVariables = {
        OLLAMA_KEEP_ALIVE = cfg.ollama.keepAlive;
      };
    } // optionalAttrs (cfg.ollama.package != null) {
      package = cfg.ollama.package;
    });

    # --- SearXNG ---
    services.searx = mkIf cfg.searxng.enable {
      enable = true;
      package = pkgs.searxng;
      settings = {
        server = {
          port = cfg.searxng.port;
          bind_address = cfg.searxng.listenAddress;
          secret_key = "hermes-firecrawl-searx";
        };
        search = {
          safe_search = 0;
          default_lang = "en";
          formats = [ "html" "json" ];
        };
        engines = mkForce [
          { name = "google"; engine = "google"; language = "en"; }
          { name = "duckduckgo"; engine = "duckduckgo"; }
          { name = "bing"; engine = "bing"; }
          { name = "wikipedia"; engine = "wikipedia"; language = "en"; }
        ];
      };
    };

    # --- Firecrawl ---
    services.firecrawl = mkIf cfg.firecrawl.enable {
      enable = true;
      port = cfg.firecrawl.port;
      listenAddress = cfg.firecrawl.listenAddress;
      searxngUrl = if cfg.searxng.enable then searxngUrl else "";
    };

    # --- Hermes ---
    services.hermes-agent = mkIf cfg.hermes.enable {
      enable = true;
      addToSystemPackages = true;
      settings = {
        toolsets = [ "all" ];
        model = {
          provider = "custom";
          default = cfg.hermes.defaultModel;
          base_url = "${ollamaUrl}/v1";
          context_length = cfg.hermes.contextLength;
          ollama_num_ctx = cfg.hermes.ollamaNumCtx;
        };
        ollama = {
          base_url = ollamaUrl;
        };
        providers = hermesProviders;
        agent.system_prompt = cfg.hermes.systemPrompt;
      };
      environment = {
        API_SERVER_ENABLED = "true";
      } // optionalAttrs cfg.firecrawl.enable {
        FIRECRAWL_API_URL = firecrawlUrl;
      } // cfg.hermes.environment;
      environmentFiles = cfg.hermes.environmentFiles;
    };

    # --- Open WebUI ---
    services.open-webui = mkIf cfg.openWebUI.enable {
      enable = true;
      package = pkgs.open-webui;
      environment = {
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";
        SCARF_NO_ANALYTICS = "True";
        WEBUI_AUTH = "False";
        ENABLE_OLLAMA_API = boolToString cfg.ollama.enable;
        ENABLE_WEB_SEARCH = boolToString cfg.searxng.enable;
        WEB_SEARCH_RESULT_COUNT = "5";
        RAG_TEMPLATE = ''
          ### Task:
          Answer the user query using ONLY the provided context. The context contains live web search results fetched right now.

          ### Rules:
          - Treat the context as ground truth. It reflects current, real-world information.
          - Do NOT say you cannot access the internet or that your knowledge has a cutoff — the context already contains fresh data.
          - Do NOT fall back to training data if the context addresses the question.
          - If the context does not contain enough information to answer, say so explicitly and summarise what the context does say.
          - Cite sources inline as [1], [2] etc. when source ids are present.

          <context>
          {{CONTEXT}}
          </context>

          <user_query>
          {{QUERY}}
          </user_query>
        '';
      } // optionalAttrs cfg.ollama.enable {
        OLLAMA_BASE_URL = ollamaUrl;
      } // optionalAttrs cfg.hermes.enable {
        OPENAI_API_BASE_URLS = "http://127.0.0.1:${toString cfg.hermes.apiPort}/v1";
        OPENAI_API_KEYS = "hermes";
      } // optionalAttrs cfg.searxng.enable {
        WEB_SEARCH_ENGINE = "searxng";
        SEARXNG_QUERY_URL = "${searxngUrl}/search?q=<query>&format=json";
      } // optionalAttrs cfg.firecrawl.enable {
        FIRECRAWL_API_BASE_URL = firecrawlUrl;
        FIRECRAWL_API_KEY = "local";
      };
      host = cfg.openWebUI.host;
      openFirewall = cfg.openWebUI.openFirewall;
    };
  };
}
