# AI_Tools

Reusable, agent-neutral skills for working with AI coding assistants.

## new-model-audit

Review your repository's authoritative instructions against fresh official model guidance, then approve a concrete plan before anything is changed.

[Read the skill](skills/new-model-audit/SKILL.md) · [Audit report template](skills/new-model-audit/assets/audit-report-template.md)

The skill:

- Fetches official documentation on every invocation. Name any provider/model, or use the default current GPT guide.
- Audits authoritative Markdown and Markdown-based agent rules, including required policy references. It excludes ordinary docs, generated content, artifacts and runtime code by default.
- Uses bounded lower-cost scan workers when supported, sharing research once and avoiding repeated full-repository scans.
- Saves findings, evidence, coverage gaps, proposed edits and an implementation handoff to `docs/model-audits/` in the repository being audited.
- Requires explicit approval before editing audited files or dispatching implementation.
- Selects a capable implementation model using current availability, pricing and task complexity; it does not hardcode a model ranking.
- Preserves shared contracts across agent hosts. If docs or delegation are unavailable, it reports the limitation instead of pretending the work ran.

## Use it

Clone this repository somewhere outside the repository you want to audit:

```sh
git clone https://github.com/Rixter145/AI_Tools.git
```

Open your target repository in your agent and give it the absolute path to `AI_Tools/skills/new-model-audit/SKILL.md`:

```text
Read and follow <absolute-path>/AI_Tools/skills/new-model-audit/SKILL.md.
Audit this repository for <provider and exact model>.
```

To use the default current GPT guidance, omit the provider/model sentence. The agent should fetch current evidence and produce a proposal. Read the saved report, then explicitly approve the finding IDs, editable files and implementation model you want.

### Optional skill discovery

Copy or link the entire `skills/new-model-audit` folder into a skill directory supported by your host. Keep `assets/` next to `SKILL.md`. A shared personal location such as `~/.agents/skills/new-model-audit` keeps the source independent of any one product; host-specific discovery paths can link to it where supported. Do not overwrite an existing installation without reviewing it.

Discovery locations and slash-command support depend on the host and version. The explicit file-path method works without relying on automatic discovery, provided the agent can read local files and follow Markdown instructions.

## Requirements and limits

The core workflow needs an agent with web access and local file access. Lower-cost scan and implementation dispatch additionally need host-supported delegation and model selection. Without these capabilities, the skill reports the gap and supplies a bounded fallback or manual handoff. API token prices are not subscription usage prices, and actual cost savings are not guaranteed.

The instructions use capabilities rather than Codex-, Claude- or Cursor-specific tool APIs. Native discovery and live workflow behavior have not been verified across every host. Installing the skill does not execute an audit or migration. Running an audit does not approve implementation.

## Contributing

Keep skills portable, concise and self-contained. Preserve explicit approval boundaries and token-conscious scope. Include only reusable templates and examples; exclude credentials, personal configuration, audit outputs and repository-specific business policies. Describe validation and any unverified host behavior with proposed changes.

## License

[MIT](LICENSE)
