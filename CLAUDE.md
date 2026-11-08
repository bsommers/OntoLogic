# CLAUDE.md

See [AGENTS.md](AGENTS.md) for full architecture map, development workflow, and required pre-push verification gates.

## Directives
- **CI Conservation**: Execute `stack test --ghc-options="-Wall -Werror"` locally before pushing. Avoid redundant remote CI triggers.
- **Merge Gate**: Never merge PRs without explicit user authorization command.
