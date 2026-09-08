# Official provider documentation

Use only the selected provider section and relevant linked model pages. These are discovery entry points, not cached guidance or fixed model recommendations. Fetch substantive content on every invocation, follow official redirects, record final URLs/retrieval dates, and resolve exact model IDs. If a link moves, search the provider's official documentation; if core evidence remains unavailable, flag DOCS_UNAVAILABLE and ask for a link.

| Provider | Model discovery | Prompting | Migration and release guidance | Pricing |
| --- | --- | --- | --- | --- |
| OpenAI / GPT | [Current model guide](https://developers.openai.com/api/docs/guides/latest-model), [model catalog](https://developers.openai.com/api/docs/models) | Prompting best practices in the current guide; follow the exact model's guidance | Migration sections in the current guide; [changelog](https://developers.openai.com/api/docs/changelog) | [API pricing](https://developers.openai.com/api/docs/pricing) |
| Anthropic / Claude | [Models overview](https://platform.claude.com/docs/en/models/overview) and its exact-model pages | [Prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices) and linked model-specific guides | Migration guide linked from the models overview; [release notes](https://platform.claude.com/docs/en/release-notes/overview) | [API pricing](https://platform.claude.com/docs/en/about-claude/pricing) |
| Google / Gemini | [Models](https://ai.google.dev/gemini-api/docs/models), [current model guide](https://ai.google.dev/gemini-api/docs/latest-model) | [Prompt design strategies](https://ai.google.dev/gemini-api/docs/prompting-strategies) and the selected model's guidance | Current model guide; [release notes](https://ai.google.dev/gemini-api/docs/changelog) | [Gemini Developer API pricing](https://ai.google.dev/gemini-api/docs/pricing) |

## Apply the right scope

- Read model-specific guidance before applying general provider advice. Distinguish model IDs, aliases, generations, and stable/preview releases. Do not hardcode current model names or prices here.
- Check the selected model's documented reasoning/thinking controls, tool use, structured output, context handling and prompting recommendations only where they affect audited instructions. Do not transfer OpenAI parameter names, Claude thinking conventions or Gemini settings to other providers without evidence.
- Model API docs do not establish host behavior. For host-specific findings, consult that host's official documentation separately; Claude Code, Gemini CLI, Codex and Cursor are execution environments with their own capabilities. A Cursor session does not identify the underlying provider.
- For Vertex AI, Bedrock, hosted gateways or other deployment channels, use that channel's official availability and pricing evidence. Direct-provider API rates do not establish gateway costs or subscription usage.
- For other providers, discover the equivalent official model catalog, prompting/migration guidance, release notes and pricing. Preserve the same missing-documentation flag, bounded scan and approval rules.
