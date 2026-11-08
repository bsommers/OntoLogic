# Architectural Evaluation: Constraining FOL vs. Horn Clauses in OntoLogic

This document evaluates whether OntoLogic's First-Order Logic (FOL) representation should be constrained to Horn clauses or other logical fragments, and details the recommended **Profile-Based Architecture**.

---

## 1. Executive Summary

**Recommendation**: **Do not restrict the core AST to pure Horn clauses.** 

Pure Horn clauses are too restrictive for ontology modeling—they cannot express disjunctions ($A \lor B$), disjointness ($\neg(A \land B)$), or existential constraints ($\exists R.C$). 

Instead, OntoLogic should adopt a **Profile-Based Architecture** (inspired by OWL 2 profiles):
- Keep the core AST as **unrestricted First-Order Logic (FOL)**.
- Use `Linter.hs` to enforce target-specific **Logic Profiles** (e.g., Schema Profile for Java/Python/Neo4j, Rule Profile for Horn/Datalog).

---

## 2. Comparison of Logical Fragments

| Fragment | Expressiveness | Primary Use Case in OntoLogic | Pros | Cons |
| :--- | :--- | :--- | :--- | :--- |
| **Full FOL** *(Current AST)* | Unlimited ($\land, \lor, \neg, \implies, \iff, \forall, \exists$) | Specification & Storage AST | Expresses any domain concept or complex rule without artificial limits. | General FOL theorem proving is undecidable ($Semi-decidable$). |
| **Horn Clauses** *(Datalog / Prolog)* | Definite rules ($A \land B \implies C$) | Rule Engines (Drools, Flink CEP, SQL Triggers) | Polynomial-time inference ($P$-complete); ideal for forward-chaining edge event streams. | **Cannot represent disjunctions** ($A \lor B$) or **disjointness** ($\neg (A \land B)$). |
| **Description Logics** *(DL / OWL 2)* | Class hierarchies ($C \sqsubseteq D$), property domain/range, property restrictions | **OOP & Schema Generation** (Java, Python, Neo4j, GraphQL) | **Decidable**; maps 1:1 with OOP classes, Pydantic models, and Graph DB nodes. | Requires structural linter rules to ensure properties map to classes cleanly. |

---

## 3. Profile-Based Architecture

Rather than restricting the entire language to a single fragment, **OntoLogic adopts target profiles**:

```
                       ┌─────────────────────────┐
                       │  Full FOL (.logic AST)  │
                       └────────────┬────────────┘
                                    │
                               ┌────┴────┐
                               ▼         ▼
                 ┌───────────────────┐  ┌───────────────────┐
                 │  Profile: Schema  │  │   Profile: Rules  │
                 │   (DL / OWL 2)    │  │  (Horn / Datalog) │
                 └─────────┬─────────┘  └─────────┬─────────┘
                           │                      │
        ┌──────────────────┼──────────┐           ▼
        ▼                  ▼          ▼     Rule Engines 
   Java POJOs       Python Pydantic Neo4j  (Drools/SQL CEP)
 (Jakarta Validation)  (v2 Models)   Cypher
```

### Profile 1: Schema Profile (Description Logic / DL)
- **Targets**: Java POJOs, Python Pydantic, Neo4j Cypher, GraphQL/OpenAPI.
- **Allowed Patterns**: Subsumption ($B \sqsubseteq A$), domain/range declarations, and universal property restrictions ($\forall x (C(x) \implies \text{range\_check})$).
- **Linter Enforcement**: Flags unmapped existential quantifiers or general disjunctions that cannot be represented as static class fields.

### Profile 2: Rule Profile (Horn / Datalog)
- **Targets**: Drools rules, Esper/Flink CEP, SQL triggers, Datalog engines.
- **Allowed Patterns**: Implications where the head is a single positive literal ($A \land B \implies C$).
- **Linter Enforcement**: Flags disjunctions in rule heads ($A \implies B \lor C$) or ungrounded variables.

---

## 4. Key Benefits

1. **No Language Lock-in**: Developers write natural `.logic` files without being forced into Prolog-style syntax.
2. **Target Safety**: The linter (`Linter.hs`) validates whether a `.logic` file complies with the chosen target's profile before transpilation:
   ```bash
   ontologic-exe --input fleet.logic --target java    # Checks DL / Schema Profile
   ontologic-exe --input fleet.logic --target drools  # Checks Horn / Rule Profile
   ```
3. **Modularity**: Allows adding new emitters (e.g., Datalog, SQL Triggers, CEP engines) in the future without refactoring the core parser or AST.
