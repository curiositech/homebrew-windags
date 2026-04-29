class Windags < Formula
  desc "DAG orchestration + 534 specialist skills for Claude Code, Cursor, Codex, Gemini CLI"
  homepage "https://windags.ai"
  url "https://github.com/curiositech/windags-skills/archive/refs/tags/v2.5.0.tar.gz"
  sha256 "3f32d15107b48024de10d22d416e6ed2bb1f317ea31abb38369122055736b2c3"
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

    # Build script files in buildpath, chmod, then bin.install — Homebrew's
    # canonical pattern for write+exec (avoids post-install perm audit stripping
    # exec bits when the file is created directly under bin/).

    (buildpath/"windags-mcp").write <<~EOS
      #!/bin/bash
      exec "#{node}" "#{libexec}/mcp-server/index.js" "$@"
    EOS

    (buildpath/"windags-init").write <<~EOS
      #!/bin/bash
      exec "#{libexec}/scripts/install.sh" "$@"
    EOS

    (buildpath/"windags").write <<~EOS
      #!/bin/bash
      cmd="$1"; shift || true
      case "$cmd" in
        init)    exec "#{HOMEBREW_PREFIX}/bin/windags-init" "$@" ;;
        mcp)     exec "#{HOMEBREW_PREFIX}/bin/windags-mcp" "$@" ;;
        version) echo "windags v2.5.0 — 534 skills" ;;
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

    chmod 0755, buildpath/"windags"
    chmod 0755, buildpath/"windags-init"
    chmod 0755, buildpath/"windags-mcp"
    bin.install "windags", "windags-init", "windags-mcp"
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
