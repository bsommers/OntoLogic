# Contributing to OntoLogic

Thanks for helping. Please read the [Code of Conduct](CODE_OF_CONDUCT.md) first; report security
problems as described in [SECURITY.md](SECURITY.md), not in public issues.

## Build and test

OntoLogic is a Haskell project built with [Stack](https://docs.haskellstack.org/).

```bash
stack build
stack test --ghc-options="-Wall -Werror"   # the full gate; run it locally before every push
```

Some specs call real tools (z3, cvc5, vampire, go, rustc, python3 with pydantic and rdflib, node,
d2, g++, sqlite3, javac). Locally a missing tool makes its spec report as pending. Pass
`ONTOLOGIC_REQUIRE_TOOLCHAINS=1` to turn that into a failure (the manual `ci.yml` workflow sets it).

The full gate runs on your machine, not on GitHub. Before every push, also run:

- `scripts/check_coverage.sh` enforces the expression-coverage floor (74%).
- `python3 -I scripts/check_links.py` fails on broken relative links in the docs. This is the one check GitHub also runs automatically (the `docs` check on pull requests).
- `./gradlew clean build test` checks the generated Java model.
- `.github/scripts/check_pending.sh <hspec-log>` fails on unexpected pending examples.

The maintainers can start the full workflow by hand on GitHub (`ci.yml`, `workflow_dispatch`).

## Pull requests

- Fork the repository and open the pull request against `main`. On GitHub only the `docs` link check runs on pull requests (including from forks); the full build and test is run locally by you and by the maintainers.
- Add a test for every behaviour change; a bug fix needs a test that failed before the fix.
- Keep `-Wall -Werror` clean. Do not weaken or delete a test to make the suite pass.
- Update the docs and `CHANGELOG.md` when you change a command, flag, or behaviour.
- Keep changes focused; one concern per pull request.

## Ontology and emitter changes

Every file in `examples/` and `ontologic-lib/` must still lint clean. If a new check flags one,
fix the ontology rather than the check. A translator that cannot express a construct must emit an
"unmapped" comment, never silently drop it.
