# homebrew-windags

Homebrew tap for WinDAGs — DAG orchestration + 478 specialist skills for Claude Code, Cursor, Codex, and Gemini CLI.

## Install

```bash
brew install curiositech/windags/windags
windags init
```

`windags init` auto-detects every AI coding tool you have installed (Claude Code, Claude Desktop, Cursor, Codex CLI, Gemini CLI) and wires the skill catalog into each.

## What's in the tap

| Formula | What it ships |
| --- | --- |
| `windags` | The full plugin — 478 skills, 5 meta-DAG sub-agents, the `windags-mcp` MCP server, the `/next-move` prediction pipeline. |

## Binaries on PATH after install

- `windags` — top-level dispatcher (`windags init`, `windags mcp`, `windags version`).
- `windags-init` — cross-tool installer (Claude Code, Codex, Gemini, Cursor).
- `windags-mcp` — MCP server entry, used by clients via stdio.

## Wire MCP into Claude Code

```bash
claude mcp add windags -- windags-mcp
```

Other clients: point your MCP config at the `windags-mcp` binary over stdio.

## Source

- Plugin source: https://github.com/curiositech/windags-skills
- Docs: https://windags.ai

## License

BUSL-1.1
