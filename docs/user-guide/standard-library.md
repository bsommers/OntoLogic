# Standard library

OntoLogic bundles reusable ontologies in the `ontologic-lib/` directory: an upper ontology (BFO), common-core and cybersecurity vocabularies, AI-governance frameworks, and more. You use them with `(import "name.logic")`. The full catalogue, with descriptions and layering, is on its own page: [../standard-library.md](../standard-library.md). This page only covers how imports of library files work.

## Importing a library file

```lisp
(import "bfo_2020.logic")

(def-concept Pump bfo:MaterialEntity)
(def-property flow_rate Pump Integer)
```

```bash
ontologic-exe -i pump.logic -t lint
ontologic-exe -i pump.logic -t solve -T 20
```

```text
✅ Logic Validated successfully.
✅ SMT Satisfiable (SAT) — Ontology is logically consistent.
✅ All concepts are satisfiable (0 empty concepts).
```

Points to know:

- **Use the bare file name.** `(import "bfo_2020.logic")` is found through the search path, whether you run from the repository, from an installed copy, or from a release tarball. A path such as `ontologic-lib/bfo_2020.logic` only works when run from a directory that has it.
- **Names carry prefixes.** Library concepts are declared with namespace prefixes (`bfo:MaterialEntity`, not `MaterialEntity`). Refer to them exactly as declared; the linter reports `Undeclared parent concept` otherwise.
- **Imports are transitive.** Importing `mitre_attack.logic` also loads the files it imports (for example `stix_cve.logic`). Circular imports are an error.
- **Library files must be lint-clean.** The linter checks the merged ontology, so a problem anywhere in the import graph stops your run.

## Where library files are found

In order: your file's own directory, each `--lib-path DIR`, each directory in `$ONTOLOGIC_PATH`, then the built-in locations (next to the executable, the installed data directory, `./ontologic-lib`, and finally the current directory). The details and an example are in the [Language reference](language-reference.md#imports-and-search-path).

To use your own shared library of ontologies, put it in a directory and add it to the path:

```bash
export ONTOLOGIC_PATH=$HOME/ontologies
ontologic-exe -i app.logic -t lint
# or per run:
ontologic-exe -i app.logic -t lint --lib-path $HOME/ontologies
```

## Files in `ontologic-lib/`

`bfo_2020`, `cco_core`, `uco_observables`, `stix_cve`, `mitre_attack`, `mitre_d3fend`, `mitre_atlas`, `nist_ai_rmf`, `nist_csf`, `nist_sp800_53`, `iso_42001_eu_ai_act`, `ocsf_schema`, `sigma_rules`, `autonomous_ai`, `software_systems`, `factory_domain`, `ecosystem`, and `ecosystem_unified` (each with the `.logic` extension). See [../standard-library.md](../standard-library.md) for what each covers.

Next: [Domain examples](domain-examples.md)
