# AI_Tools

A growing collection of reusable, agent-neutral AI tools, workflows, and skills for working with AI coding assistants. Each tool is designed to be portable, reviewable, and useful across supported agent hosts.

## Tools

| Tool | Purpose | Instructions |
| --- | --- | --- |
| `new-model-audit` | Audit agent instructions against current official model guidance. | [Read the skill](skills/new-model-audit/SKILL.md) |
| `friction-maxxing` | Prediction-first gate on product/scope and strategy/voice decisions. | [Read the skill](skills/friction-maxxing/SKILL.md) |

## Getting started

Clone the collection, choose a tool, and read that tool's instructions in your agent:

```sh
git clone https://github.com/Rixter145/AI_Tools.git
```

Tools are self-contained under `skills/<skill-name>/`. You can copy or link a complete tool, including its assets and references, into a skill directory supported by your host. A shared location such as `~/.agents/skills/<skill-name>` keeps the source agent-neutral; host-specific discovery paths can link to it where supported. Do not overwrite an existing installation without reviewing it.

## Using new-model-audit

Review your repository's authoritative instructions against fresh official model guidance, then approve a concrete plan before anything is changed.

[Audit report template](skills/new-model-audit/assets/audit-report-template.md)

Give your agent the absolute path to the skill and a provider plus exact model:

```text
Read and follow <absolute-path>/AI_Tools/skills/new-model-audit/SKILL.md.
Audit this repository for <provider and exact model>.
```

The audit fetches fresh official evidence, resolves ambiguous model names instead of defaulting to a provider, and produces a proposal before edits. Review the saved findings and explicitly approve the finding IDs, editable files, and implementation model before implementation edits or implementation delegation.

Official model, prompting, release-note, and pricing entry points are in the [source map](skills/new-model-audit/references/provider-docs.md). The workflow needs web and local file access; delegation and model selection depend on host support. API token prices are separate from subscription usage, and savings are not guaranteed.

## Using friction-maxxing

Gates two decision classes so the user forms their own read before the agent offers one: product
and scope (what to build, what to cut, who it is for, what "done" means, prioritisation) and
strategy and writing voice (theses, positioning, public wording, anything carrying the user's
name). Everything else — architecture, implementation, refactors, debugging, research, and any
mechanical or reversible work — is explicitly not gated and must not be slowed down.

When a gated decision surfaces, the agent names the decision, states what is at stake without
leaning toward an answer, asks for the user's read and reasoning, and stops. It only gives its
own view after the user has committed to theirs. Override with `fm off` (stands down for the
session), `fm on` (re-arms it), or `just tell me` (bypasses the gate for one turn only).

Install by copying `skills/friction-maxxing/SKILL.md` into a skill directory your agent host
supports — this alone is enough for the gate to work whenever the skill is triggered. For the
full version, which also injects a mandate at session start and tracks override state across
turns without relying on the model to remember it, install the hook runtime in
`skills/friction-maxxing/assets/` with `install-frictionmax.ps1` and wire it into your agent's
hook configuration by hand; see [agent wiring](skills/friction-maxxing/references/agent-wiring.md)
for per-agent event names, config paths, and known limitations.

## Design principles

Tools should remain portable, concise, self-contained, and explicit about approval boundaries, capabilities, validation, and limitations. They should include reusable assets and references while excluding credentials, personal configuration, audit outputs, and repository-specific policies.

## Contributing

Contributions should follow these principles and document any host behavior that remains unverified.

## License

[MIT](LICENSE)
