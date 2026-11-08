# REPL

The REPL is an interactive session in which you load or type ontology forms, lint them, run the solvers, prove subsumptions, and print any emitter's output without writing files. It is the quickest way to ask "does this follow?" or "what would this look like in TypeScript?". Start it with `ontologic-exe --repl` (or `-t repl`); no input file is needed.

```text
╔════════════════════════════════════════════════════════════╗
║              OntoLogic Interactive REPL v1.0               ║
║   Type ':help' for commands or enter DSL expressions       ║
╚════════════════════════════════════════════════════════════╝
ontologic>
```

Input is read one line at a time, so each form or command must fit on one line. End the session with `:quit`, `:q`, `exit`, or end-of-input (Ctrl-D).

## Commands

| Command | What it does |
|---------|--------------|
| `:help`, `:?` | List commands |
| `:load <file.logic>` | Replace the session with a file and its imports (uses the default library search path and `$ONTOLOGIC_PATH`) |
| `:show` | Counts and names of concepts, properties, relations, axioms; active prover; loaded file |
| `:lint` | Run the linter on the session |
| `:prover [name]` | Show or set the prover: `z3`, `cvc5`, `vampire`, `native`, `auto` |
| `:solve`, `:check` | Consistency check (prints the model when SAT) plus the coherence check |
| `:explain` (also `:unsat-core`, `:explain-unsat`) | Unsatisfiable core, when there is a contradiction |
| `:model` (also `:inspect-model`) | Print a satisfying model |
| `:prove <A> <B>` | Prove or refute that every `A` is necessarily a `B` (A ⊑ B); a counterexample model is printed when refuted |
| `:unsat` | List concepts that cannot have instances |
| `:cnf` | Show the session in clausal normal form |
| `:ir` | Dump the compiled intermediate model (for debugging) |
| `:emit <target>` | Print the target's output (all files concatenated) to the screen. Any name or alias from the [CLI reference](cli-reference.md#targets) |
| `:set java-package <pkg>` | Package used by `:emit java` |
| `:set base-iri <iri>` | Base IRI used by `:emit owl` and `:emit shacl` |
| `:clear` | Empty the session (the prover choice is kept) |
| `:quit`, `:q`, `exit` | Leave |

Anything that is not a command is parsed as DSL. A line may contain one or several top-level forms; they are merged into the session. The linter runs after each addition and, if it finds a problem, prints `⚠️ Lint warning: ...` for the first one; the forms stay in the session regardless.

## Example session

```text
ontologic> (def-concept Device)
Added to registry.
ontologic> (def-concept SmartSensor Device)
Added to registry.
ontologic> (def-property batteryLevel SmartSensor Integer)
Added to registry.
ontologic> (forall (s) (implies (SmartSensor s) (and (gte batteryLevel 0) (lte batteryLevel 100))))
Added to registry.
ontologic> :lint
✅ Semantic Linting Passed (0 errors).
ontologic> :prove SmartSensor Device
✅ Theorem Proved via Auto (Z3/CVC5/Vampire/Native): 'SmartSensor' ⊑ 'Device' (Every instance of SmartSensor is necessarily a Device).
ontologic> :emit ts
import { z } from "zod";

export const DeviceSchema = z.object({
});
...
export const SmartSensorSchema = DeviceSchema.extend({
  batteryLevel: z.number().int().gte(0).lte(100),
});
```

Adding a contradictory bound is caught immediately:

```text
ontologic> (forall (s) (implies (SmartSensor s) (gt batteryLevel 100)))
Added to registry.
⚠️  Lint warning: Cross-axiom contradiction on SmartSensor.batteryLevel: lte 100 and gt 100
ontologic> :solve
❌ SMT Unsatisfiable (UNSAT) via Auto (Z3/CVC5/Vampire/Native) — Logical Contradiction Detected!
❌ Unsatisfiable / empty concept(s): SmartSensor
```

Refuting a subsumption (with Z3 selected):

```text
ontologic> :load fleet.logic
✅ Loaded fleet.logic (4 concepts, 0 lint errors).
ontologic> :prover z3
✅ SMT Prover switched to: Z3
ontologic> :prove Vehicle Truck
❌ Theorem Disproved via Z3: 'Vehicle' is NOT subsumed by 'Truck'. Counterexample model:
```

## Differences from the CLI

- `:load` does not take `--lib-path`; use `ONTOLOGIC_PATH`.
- `:load` loads even when there are lint errors (it reports `Loaded ... with N lint warnings`); the CLI refuses to continue past lint errors.
- There are no `-T`/`--solve-timeout` or `--solve-memory` controls; for bounded runs use the CLI.
- `:solve` always prints the model on SAT; the CLI needs `--inspect-model`.
- `:prove` exists only here.
- `:explain` reports "No contradictory axioms or unsat cores detected" when the solver returns an empty core, which can happen even when `:solve` has just reported UNSAT. If so, rely on the `:solve` verdict and read the lint message.
- Malformed input prints a parse error with a caret and leaves the session unchanged:

```text
ontologic> (oops
❌ Parse Error:
<repl>:1:6:
  |
1 | (oops
  |      ^
unexpected end of input
```

Next: [Editor and LSP](editor-and-lsp.md)
