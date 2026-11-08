# Developer and Internal Notes

Working material for people changing OntoLogic itself: plans, reviews, design
discussion, benchmarks and the test-coverage audit. These are records of how the
project got here, not user documentation; for that see the
[documentation index](../README.md).

Some documents are snapshots. Check the current code and
[`CHANGELOG.md`](../../CHANGELOG.md) before acting on a recommendation.

## Index

| Area | Document | What it is |
| :--- | :--- | :--- |
| Roadmap input | [Suggested Improvements](SUGGESTED_IMPROVEMENTS.md) | Architectural review, bug audit, semantic gaps and a prioritized modernization list |
| Quality | [Test Coverage](TEST_COVERAGE.md) | Test-suite coverage audit and gap list |
| Design notes | [Constraint considerations](design/constraint_considerations.md) | Whether to constrain FOL to Horn clauses; the profile-based architecture |
| | [Constraints and patterns](design/constraints_and_patterned.md) | Logical expressiveness compared with Horn clauses, and how formulas are parsed and linted |
| Reviews | [Gemini review](reviews/GEMINI_3_7_REVIEW.md) | AI-generated codebase, security and semantic-gap review with a phased roadmap |
| | [BFO review](reviews/AI_BFO_Review.md) | AI-generated critique of the ecosystem ontology against BFO principles |
| Benchmarks | [Native prover benchmarks](benchmarks/v1.7.0-native-prover-benchmarks.md) | Measurements for the built-in prover |
| Plans | [`plans/`](plans/) | Dated remediation and tech-debt plans (2026-09) |
| Implementation history | [Replay playbook](superpowers/REPLAY_PLAYBOOK.md) | Milestone-by-milestone learnings and a runbook to rebuild the project |
| | [`superpowers/plans/`](superpowers/plans/) | Formal implementation plans for each milestone |

## Plans

- [Codebase-wide review and remediation](plans/2026-09-26-codebase-wide-review-and-remediation.md)
- [FOL completeness and tech-debt plan](plans/2026-09-26-fol-completeness-and-tech-debt-plan.md)
- [v1.5.0 tech-debt remediation](plans/2026-09-27-v1.5.0-tech-debt-remediation.md)
- [v1.5.0 tech-debt implementation plan](plans/2026-09-28-v1.5.0-tech-debt-implementation-plan.md)

## Before you push

The required verification gates and architecture map for contributors are in
[`AGENTS.md`](../../AGENTS.md). In short, run
`stack test --ghc-options="-Wall -Werror"` locally first.
