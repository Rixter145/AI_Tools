# Agent wiring

Findings below come from inspecting the actual agent binaries, not from documentation alone. The
hook was additionally run end-to-end against Claude Code and Codex; Gemini CLI was wired to the
same verified protocol but never exercised. Treat anything marked untested as wired-but-unverified.

## Shared hook protocol

All three agents (Claude Code, Codex, Gemini CLI) share one hook protocol:

```
stdin  <- JSON event payload
stdout -> {"hookSpecificOutput":{"hookEventName":"...","additionalContext":"..."}}
```

A hook is a subprocess. Its stdout is injected into context; it cannot invoke a skill directly.
`frictionmax.mjs` only injects the mandate — the model does the classification of whether a given
prompt is a scope/voice decision. That classification is semantic; no regex can do it.

## Event names

| Agent | Session event | Per-turn event |
|---|---|---|
| Claude Code | `SessionStart` | `UserPromptSubmit` |
| Codex | `SessionStart` | `UserPromptSubmit` |
| Gemini CLI | `SessionStart` | `BeforeAgent` |

Gemini CLI also exposes `BeforeModel`, `AfterModel`, `AfterAgent`, `BeforeTool`, `AfterTool`, and
`SessionEnd`. Only `SessionStart` and `BeforeAgent` are used here.

## Config file locations

| Agent | Path |
|---|---|
| Claude Code | `~/.claude/settings.json` |
| Codex | `~/.codex/hooks.json` |
| Gemini CLI | `~/.gemini/settings.json` |

Gemini's hook entries additionally carry `name` and `timeout` fields; the other two do not.

Claude Code / Codex hooks block, inside the existing `hooks` object:

```json
"SessionStart":     [{ "hooks": [{ "type": "command", "command": "C:\\Users\\<you>\\.local\\bin\\frictionmax.cmd" }] }],
"UserPromptSubmit": [{ "hooks": [{ "type": "command", "command": "C:\\Users\\<you>\\.local\\bin\\frictionmax.cmd" }] }]
```

Gemini CLI hooks block:

```json
"SessionStart": [{ "hooks": [{ "name": "frictionmax", "type": "command", "command": "~/.local/bin/frictionmax.cmd", "timeout": 5000 }] }],
"BeforeAgent":  [{ "hooks": [{ "name": "frictionmax", "type": "command", "command": "~/.local/bin/frictionmax.cmd", "timeout": 5000 }] }]
```

## Instruction-file layer

| Agent | Path |
|---|---|
| Claude Code | `~/.claude/CLAUDE.md` |
| Codex | `~/.codex/AGENTS.md` |
| Gemini CLI | `~/.gemini/GEMINI.md` |

Gemini CLI reads no user-level skills directory, so `~/.gemini/GEMINI.md` must carry the full
behaviour of this skill directly rather than pointing at a `SKILL.md` file. Claude Code and Codex
can instead reference the installed skill from their instruction file.

## Skill install paths

- `~/.agents/skills/` — shared, agent-neutral location
- `~/.claude/skills/`
- `~/.codex/skills/`
- `~/.cursor/skills/` — Cursor uses the identical `SKILL.md` frontmatter format, so the same file
  can be linked or copied in without changes

## Limitations

- **A hook cannot invoke a skill in any of these agents.** A hook is a subprocess whose stdout is
  injected into context. The hook injects a mandate; the model does the classification. No regex
  can detect "is this a scope decision" — it is semantic, not lexical.
- **`claude -p` (print mode) does not run `SessionStart` or `UserPromptSubmit` hooks.** Verified
  with an env-gated trace and with an explicit `--settings` file. This means you cannot verify
  Claude Code's hook wiring headlessly — test it interactively.
- **`SessionStart` `additionalContext` delivery is not uniform across agents and run modes.** This
  is why the mandate is injected on the first per-turn event of a session (tracked by a
  `mandateSent` flag in session state) rather than relying on `SessionStart` alone.
- **Gemini CLI is wired but entirely untested.** The event names and protocol above were read out
  of the CLI bundle, but no session was ever run against it. In particular, the `BeforeAgent`
  payload is not confirmed to carry prompt text; if it does not, the `fm off` override degrades
  there to model-honoured only rather than persisting across turns via the state file.
- **Cursor and GitHub Copilot use different hook schemas** (Cursor's is permission-shaped:
  allow/deny/ask) and are not supported by this hook script. Cursor can still use the skill plus a
  global rule; the hook itself does not port.
- **Only tested on Windows.** The `.cmd` shim is Windows-specific. On macOS/Linux, a shell shim
  calling `node frictionmax.mjs` should work but is untested.

## Debugging

Set `FRICTIONMAX_DEBUG=1` in the agent's environment to append every hook invocation (event name,
session id, payload keys) to `%TEMP%/frictionmax/_debug.log`. This is the fastest way to find out
which events a given agent actually delivers, since that varies by agent and run mode.
