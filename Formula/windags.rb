class Windags < Formula
  desc "DAG orchestration + 478 specialist skills for Claude Code, Cursor, Codex, Gemini CLI"
  homepage "https://windags.ai"
  url "https://github.com/curiositech/windags-skills/archive/refs/tags/v2.4.0.tar.gz"
  sha256 "60fa8930ef415ff89f3ccbb5f1528139d0ca2ad56485e58a90b6058abe6c905e"
  license "BUSL-1.1"
  head "https://github.com/curiositech/windags-skills.git", branch: "main"

  depends_on "node"

  def install
    libexec.install Dir["*"]

    # Install MCP server deps (production only, no audit/fund noise)
    cd libexec/"mcp-server" do
      system "npm", "install", "--omit=dev", "--no-audit", "--no-fund"
    end

    node = Formula["node"].opt_bin/"node"

    # MCP server binary — wraps node + the bundled mcp-server entry
    (bin/"windags-mcp").write <<~EOS
      #!/bin/bash
      exec "#{node}" "#{libexec}/mcp-server/index.js" "$@"
    EOS
    chmod 0755, bin/"windags-mcp"

    # init wrapper: runs the cross-tool installer (Claude Code, Codex, Gemini, Cursor)
    (bin/"windags-init").write <<~EOS
      #!/bin/bash
      exec "#{libexec}/scripts/install.sh" "$@"
    EOS
    chmod 0755, bin/"windags-init"

    # Top-level CLI dispatcher
    (bin/"windags").write <<~EOS
      #!/bin/bash
      cmd="$1"; shift || true
      case "$cmd" in
        init)    exec "#{bin}/windags-init" "$@" ;;
        mcp)     exec "#{bin}/windags-mcp" "$@" ;;
        version) echo "windags v2.4.0 — 478 skills" ;;
        ""|help|-h|--help)
          cat <<HELP
windags — DAG orchestration + specialist skills for AI coding agents

USAGE
  windags init       Wire skills into Claude Code, Cursor, Codex, Gemini CLI
  windags mcp        Run the MCP server (stdio)
  windags version    Print version
  windags help       This message

NEXT STEP
  windags init                                   # link skills into ~/.claude, ~/.codex, ~/.gemini
  claude mcp add windags -- windags-mcp          # register the MCP server with Claude Code

Docs: https://windags.ai
HELP
          ;;
        *) echo "windags: unknown command '$cmd' (try: windags help)" >&2; exit 2 ;;
      esac
    EOS
    chmod 0755, bin/"windags"
  end

  def caveats
    <<~EOS
      WinDAGs installed. Two more steps to wire it up:

        windags init                                 # link skills + agents into ~/.claude (and ~/.codex, ~/.gemini if present)
        claude mcp add windags -- windags-mcp        # register the MCP server with Claude Code

      Then in any session:
        /next-move                                   # the prediction pipeline
        "search WinDAGs for skills about X"          # uses windags_skill_search

      Docs: https://windags.ai/install
    EOS
  end

  test do
    assert_predicate libexec/"mcp-server/index.js", :exist?
    assert_predicate libexec/"plugin.json", :exist?
    assert_predicate libexec/"skills", :exist?
    assert_match "v2.4.0", shell_output("#{bin}/windags version")
  end
end
