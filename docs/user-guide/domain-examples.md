# Domain examples

The repository includes worked ontologies for realistic domains (mining, cloud data centers, security and trust, and more), each paired with a deliberately broken variant so you can see what a contradiction looks like. The gallery, with a description of each domain, is written separately: [../domains/README.md](../domains/README.md). This page explains how the files are organized and how to run them.

## Layout

| Path | Contents |
|------|----------|
| `examples/domain_*.logic` | The domain ontologies, for example `examples/domain_mining.logic`, `examples/domain_cloud_datacenter.logic`, `examples/domain_security_trust.logic` |
| `test/fixtures/domains/<name>.expect` | The expected verdict for the ontology of that name |
| `test/fixtures/domains/<name>_conflict.logic` | A variant that imports the domain file and adds an axiom that contradicts it |

Each domain example has an `.expect` file and a `_conflict` fixture under `test/fixtures/domains/`. They are checked by `test/DomainExamplesSpec.hs`:

- A guard fails if an `examples/domain_*.logic` file has no `.expect` fixture.
- The `.expect` file is a list of lines such as `concept Excavator`, `relation drives`, or `property methane_level` (`#` starts a comment); each named symbol must be declared in the loaded ontology.
- The ontology must be satisfiable (SAT).
- The `_conflict` variant must be unsatisfiable (UNSAT). This check uses Z3, falling back to CVC5, because the conflicts involve numeric bounds; it is marked pending when neither is installed. All solves use a 30 second limit.

The test asks the solver directly. On the command line the linter catches these conflicts first, so the CLI reports lint errors rather than an UNSAT verdict (shown below).

## Try one

```bash
ontologic-exe -i examples/domain_mining.logic -t lint
ontologic-exe -i examples/domain_mining.logic -t solve -p z3
```

```text
✅ Logic Validated successfully.
✅ SMT Satisfiable (SAT) — Ontology is logically consistent.
✅ All concepts are satisfiable (0 empty concepts).
```

Now the conflict variant, which is the import plus one extra axiom:

```lisp
(import "examples/domain_mining.logic")
(forall (s)
    (implies (GasSensor s)
             (and (gt methane_level 5) (lt methane_level 3))))
```

```bash
ontologic-exe -i test/fixtures/domains/domain_mining_conflict.logic -t lint
```

```text
examples/domain_mining.logic:49:15: error: Property contradiction on methane_level: gt 5 and lt 3
examples/domain_mining.logic:27:14: error: Cross-axiom contradiction on GasSensor.methane_level: gt 5 and lt 3
examples/domain_mining.logic:27:14: error: Cross-axiom contradiction on GasSensor.methane_level: lt 3 and gt 5
```

(Real output prints full paths.) The `(import "examples/...")` path resolves relative to the current directory, so run these from the repository root.

Compile a domain to code or diagrams the same way as any ontology:

```bash
ontologic-exe -i examples/domain_cloud_datacenter.logic -t d2 -o diagrams --render
ontologic-exe -i examples/domain_security_trust.logic -t ts -o out/ts
```

The `examples/` directory also holds generated artifacts (`.mmd`, `.d2`, `.d2.svg`, `.cypher`) next to each `.logic` file.

Next: [Troubleshooting](troubleshooting.md)
