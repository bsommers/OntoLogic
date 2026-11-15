# CLAUDE.md

See [AGENTS.md](AGENTS.md) for full architecture map, development workflow, and the single list of required pre-push verification gates.

## Directives
- **CI is local**: Run every gate listed under "Pre-Push Verification Gate" in AGENTS.md locally before pushing (not only `stack test`). GitHub automatically runs only the `docs` link check and the Pages deployment; the full workflow (`ci.yml`) is manual-only. Do not start it without need.
- **Merge Gate**: Never merge PRs without explicit user authorization command.
