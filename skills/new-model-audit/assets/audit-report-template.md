# Model audit: {{provider}} / {{exact_model}}

- Retrieved: {{timestamp_with_timezone}}
- Repository: {{absolute_root}}
- Status: {{proposed | blocked | no-changes | approved | implemented | incomplete}}
- Baseline: {{prior_audit_or_verified_comparison; otherwise current-guidance-only}}

## Sources and evidence gaps

| Official URL and section | Model/version | Retrieved | Published/updated | Supported guidance |
| --- | --- | --- | --- | --- |

Record DOCS_UNAVAILABLE and missing pricing/availability evidence where applicable. Distinguish unavailable core guidance from optional source gaps. Do not reproduce secrets or extensive source text.

## Coverage and preserved requirements

Scope: authoritative Markdown and active Markdown-based host rules only. List the compact authority manifest: file, reason it governs behavior, hash, and reviewed sections/status. Summarize applicable personal sources and current user edits. Report unresolved authority references and excluded categories without enumerating excluded files. State the business rules and output/approval contracts that edits must preserve. Runtime code/configuration, generators, artifacts, history, and ordinary documentation are outside this default scope.

## Scan delegation and efficiency

| Partition | Actual model / effort | Assigned / reviewed coverage | Status / gaps | Usage or cost, if exposed |
| --- | --- | --- | --- | --- |

Record the shared documentation fetch, bounded authority manifest, partition rationale, coordinator evidence spot-checks, and any reused prior coverage with its hash/guidance basis. Distinguish pending, failed, and completed workers. Flag SCAN_DELEGATION_UNAVAILABLE and describe any coordinator fallback. Report measured usage only when available; do not claim estimated savings as measured. Summarize only authoritative-file coverage; do not attach a repository-wide inventory.

## Findings and proposed edits

| ID | File:line / affected behavior | Evidence and fact vs inference | Concrete edit and rationale | Acceptance check |
| --- | --- | --- | --- | --- |

Include exact affected paths and enough replacement detail for implementation. Flag required generator/loader work as a separately scoped follow-up; do not imply that code was audited. State no justified changes when appropriate. Identify unresolved decisions as blockers instead of delegating them as implementation choices.

## Shared-agent compatibility

| Proposed edit | Consumers (host and model) | Shared or scoped surface | Compatibility check | Result / unverified behavior |
| --- | --- | --- | --- | --- |

Account for Codex, Claude, and Cursor where affected. Explain why each shared edit is valid across consumers; scope model-only guidance instead of making it universal. Preserve shared contracts and consumer-specific workarounds still needed elsewhere. Distinguish static verification from live host/model testing.

## Implementation model and cost rationale

- Host and available delegation/model-selection mechanism:
- Plausible capable candidates and current cost sources:
- Selected model and supported effort:
- Capability rationale and estimated total-cost assumptions:
- API versus subscription distinction; unverified costs or availability:
- Manual handoff requirement, if any:

## Approval and implementation handoff

Approval is pending until the prompter explicitly approves this proposal. Record the approved scope and model choice after approval; do not infer approval from generating this report.

Provide a self-contained handoff containing:

- Objective, working root, report path, and relevant documentation evidence.
- Approved finding IDs, exact editable files, canonical sources, and intended edits.
- Preserved invariants and existing user changes.
- Required acceptance checks and expected results.
- Selected model/effort, boundaries, and stopping/escalation conditions.
- Required return: changed files, diff summary, checks actually run and results, unresolved issues.

## Verification receipt

Complete after implementation; keep planned checks distinct from executed checks.

| Check / scenario | Expected result | Observed result and evidence | Pass/fail/not run |
| --- | --- | --- | --- |

Record coordinator diff review, implemented finding IDs, remaining coverage gaps, and any incomplete work. No-change audits require no implementation dispatch.
