## CHANGELOG

Rules that apply whenever a CHANGELOG entry is written (during `/ship` Step 13 or any manual update):

1. **Strip empty sections** — a section (Added, Changed, Fixed, Removed) whose only bullet is a bare `-` with no text must be deleted entirely from the release entry. Never ship a section that is literally just `- `.

2. **Fallback to previous release** — if EVERY section under `[Unreleased]` is empty after applying rule 1, copy the non-empty sections from the most recent versioned release (the first `## [X.Y.Z...]` block below) and use them as the release entry instead. This ensures the CHANGELOG always has meaningful content.

3. **Reset Unreleased after shipping** — after converting `[Unreleased]` to a versioned entry, reset the Unreleased template to this exact block (no pre-filled empty bullets):

```markdown
## [Unreleased]

### Added

### Changed

### Fixed

---
```

4. **Never include `---` between back-to-back release blocks** — only one `---` separator between releases.

---

## graphify

This project has a graphify knowledge graph at graphify-out/.

Rules:
- Before answering architecture or codebase questions, read graphify-out/GRAPH_REPORT.md for god nodes and community structure
- If graphify-out/wiki/index.md exists, navigate it instead of reading raw files
- For cross-module "how does X relate to Y" questions, prefer `graphify query "<question>"`, `graphify path "<A>" "<B>"`, or `graphify explain "<concept>"` over grep — these traverse the graph's EXTRACTED + INFERRED edges instead of scanning files
- After modifying code files in this session, run `graphify update .` to keep the graph current (AST-only, no API cost)
