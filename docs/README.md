# OntoLogic: Documentation Index

Welcome to the OntoLogic documentation folder. This directory contains detailed descriptions of the compiler's purpose, design, pipeline internals, and user guides.

---

## 📚 Documents

1.  **[Why OntoLogic? Strategic & Architectural Rationale](WHY_ONTOLOGIC.md)**: The foundational executive and technical manifesto for OntoLogic. Analyzes the 5 fatal anti-patterns of modern polyglot architectures (Distributed Logic Drift, Property Graph Sloppiness Tax, LLM Hallucination Wall, Academic OWL Trap, Data vs. Logic Contracts) and demonstrates how Logic-as-Code, FOL theorem proving, and universal compilation solve them.
2.  **[Purpose & Motivation](purpose_and_motivation.md)**: Explains the operational problem of distributed logic drift in IoT fleets and how OntoLogic's "Logic-as-Code" provides a single source of truth.
3.  **[Compiler Architecture](architecture.md)**: Details the parser frontend, FOL intermediate representation (AST), validation linter, and multi-target compilation emitters.
4.  **[Comprehensive User Guide](user-guide/README.md)**: In-depth user manual, step-by-step tutorial, S-expression syntax specifications, CLI workflows, and troubleshooting.
5.  **[User Guide & CLI Reference](using.md)**: Quick reference manual, CLI flags, build configurations, and diagram rendering instructions.
6.  **[Suggested Improvements](SUGGESTED_IMPROVEMENTS.md)**: Critical architectural review, bug audits, semantic gaps, and prioritized modernization roadmap.
7.  **[Gemini 3.7 Architectural Review & Strategic Recommendations](GEMINI_3_7_REVIEW.md)**: Comprehensive codebase security audit, semantic gap analysis, and phased roadmap by Gemini 3.7 Flash (Medium Reasoning).
8.  **[Replay Playbook & Learnings](superpowers/REPLAY_PLAYBOOK.md)**: Complete central manual of architecture learnings, edge cases, and runbook to replay and rebuild the entire compiler and test suite cleanly from scratch.
9.  **[Superpowers Plans](superpowers/plans/)**: Formal implementation plans for Milestone 1 (Core Improvements), Milestone 2 (Robust Testing Suite), and Milestone 3 (Security Hardening, Error Handling & CI).
10. **[BFO Critique & Recommendations](AI_BFO_Review.md)**: Formal review of ecosystem ontology against Basic Formal Ontology (BFO) principles (AI-generated).
11. **[Strategic Value of Ontology](ONTOLOGY_VALUE.md)**: Distinguishing taxonomy from ontology, solving IIoT data context issues, and grounding AI.
12. **[Role-Based Organizational Value](COMPANY_ROLES.md)**: Why every role in the organization benefits from formal ontology.
13. **[Case for Rigorous Ontology](RATIONALE.md)**: Technical rationale for BFO, First-Order Logic (FOL), and Haskell in industrial AI systems.

---

## ⚡ Quick Start

To parse and validate a logic schema, run:
```bash
stack exec ontologic-exe -- -i logic/fleet.logic -t lint -o .
```

To transpile a logic schema into Python Pydantic models, run:
```bash
stack exec ontologic-exe -- -i logic/fleet.logic -t python -o generated/
```
