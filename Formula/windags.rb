class Windags < Formula
  desc "DAG orchestration + 545 specialist skills (5-stage local cascade + headless /next-move) for Claude Code, Cursor, Codex, Gemini CLI"
  homepage "https://windags.ai"
  url "https://github.com/curiositech/windags-skills/archive/refs/tags/v2.10.0.tar.gz"
  sha256 "a3586b833d22367b1f6ff993802911f9f34ff866aafc135befc76f9f42c9edb3"
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

    # Use opt_libexec (stable `/opt/homebrew/opt/windags/libexec` path) instead of
    # libexec (versioned Cellar path). Symlinks created by install.sh resolve through
    # this stable path, so they survive `brew upgrade` instead of becoming dangling.
    (buildpath/"windags-mcp").write <<~EOS
      #!/bin/bash
      exec "#{node}" "#{opt_libexec}/mcp-server/index.js" "$@"
    EOS

    (buildpath/"windags-init").write <<~EOS
      #!/bin/bash
      exec "#{opt_libexec}/scripts/install.sh" "$@"
    EOS

    (buildpath/"windags").write <<~EOS
      #!/bin/bash
      cmd="$1"; shift || true
      case "$cmd" in
        init)    exec "#{HOMEBREW_PREFIX}/bin/windags-init" "$@" ;;
        mcp)     exec "#{HOMEBREW_PREFIX}/bin/windags-mcp" "$@" ;;
        version) echo "windags v2.10.0 — 545 skills · 5-stage cascade · 10-tool MCP + next_move prompt + headless run-pipeline (Anthropic/OpenAI/Google/+) (BM25 + MiniLM + RRF + cross-encoder + attribution)" ;;
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

  def post_install
    # Re-link skills + agents into ~/.claude, ~/.codex, ~/.gemini after every
    # install/upgrade. Two reasons:
    #   1. New skills shipped in this version get linked without the user
    #      remembering to re-run `windags init`.
    #   2. The wrappers above use opt_libexec, so re-running here refreshes the
    #      symlinks against the stable opt path on first install.
    install_sh = opt_libexec/"scripts/install.sh"
    return unless install_sh.exist?
    return if ENV["HOME"].nil? || ENV["HOME"].empty?

    ohai "Linking WinDAGs skills into agent dirs (~/.claude, ~/.codex, ~/.gemini)"
    system install_sh.to_s
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
    assert_match "v2.10.0", shell_output("#{bin}/windags version")
  end
end
