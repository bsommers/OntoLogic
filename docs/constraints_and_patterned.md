# Logic Representation, Constraints, and Pattern Matching in OntoLogic

This document details the logical expressiveness of OntoLogic, how it differs from Horn clause logic, and how First-Order Logic (FOL) formulas are parsed, linted, and transpiled into target runtime environments (Java, Python, and Neo4j).

---

## 1. Logic Representation: Full First-Order Logic (FOL)

OntoLogic is **not** restricted to Horn clauses (unlike Prolog or Datalog). 

In [`src/OntoLogic.hs`](src/OntoLogic.hs), the abstract syntax tree (`FOL`) represents full First-Order Predicate Logic:

```haskell
data FOL = Predicate Name [Term]
         | And FOL FOL
         | Or FOL FOL
         | Not FOL
         | Implies FOL FOL
         | Iff FOL FOL
         | ForAll Name FOL
         | Exists Name FOL
         deriving (Show, Eq, Generic)
```

### Key Differences from Horn Clauses

- **Horn Clause Restriction**: A Horn clause is a disjunction of literals with at most one positive literal (e.g. $A \land B \implies C$). Horn logic cannot represent general disjunctions ($A \lor B$) or arbitrary negations ($\neg (A \land B)$).
- **OntoLogic Expressiveness**: Supports:
  - **Full Connectives**: Conjunction ($\land$), Disjunction ($\lor$), Negation ($\neg$), Implication ($\implies$), Biconditional ($\iff$).
  - **Quantifiers**: Universal ($\forall$) and Existential ($\exists$) quantification over arbitrary variables.

---

## 2. Transpilation & Pattern Extraction

While the AST represents unrestricted FOL, current target runtime platforms (Java Jakarta Validation, Python Pydantic, and Neo4j Cypher) do not run general-purpose first-order theorem provers at runtime. 

To bridge full logic with high-performance production code, the emitters target a **syntactic pattern** of universally quantified implications:

$$\forall x \; \big( \text{Concept}(x) \implies \text{PropertyConstraints}(x) \big)$$

### Constraint Mapping Matrix

| Logic Predicate | Range Type | Java (Jakarta Validation) | Python (Pydantic v2) | Neo4j (Cypher Audit Query) |
| :--- | :--- | :--- | :--- | :--- |
| `gt(prop, val)` | `Integer` | `@Min(val + 1)` on getter | `Field(gt=val)` | `MATCH (n:C) WHERE NOT (n.prop > val)` |
| `gte(prop, val)` | `Integer` | `@Min(val)` on getter | `Field(ge=val)` | `MATCH (n:C) WHERE NOT (n.prop >= val)` |
| `lt(prop, val)` | `Integer` | `@Max(val - 1)` on getter | `Field(lt=val)` | `MATCH (n:C) WHERE NOT (n.prop < val)` |
| `lte(prop, val)` | `Integer` | `@Max(val)` on getter | `Field(le=val)` | `MATCH (n:C) WHERE NOT (n.prop <= val)` |
| `eq(prop, val)` | Any | Verified via linter / audit | Verified via linter | `MATCH (n:C) WHERE NOT (n.prop = val)` |

---

## 3. Subclass Inheritance & Override Handling

When a subclass $B$ (where $B \sqsubseteq A$) introduces extra constraints on a property $p$ defined on ancestor $A$:

- **Java**: Emits an `@Override` getter in class $B$ with the subclass-specific `@Min` / `@Max` annotations, avoiding Java field-shadowing while preserving standard JavaBean getter validation.
- **Python**: Redeclares the property in the subclass Pydantic model with the subclass-specific `Field(...)` parameters.

---

## 4. Static Linter Validation

The static linter in [`src/Linter.hs`](src/Linter.hs) validates logic files before code generation:

1. **Taxonomy Cycle Check**: Detects circular inheritance chains (e.g., $A \sqsubseteq B \sqsubseteq A$).
2. **Propositional Contradictions**: Detects conjuncts containing $P \land \neg P$.
3. **Numeric Range Contradictions**: Detects impossible range combinations on the same property (e.g., $x > 50 \land x < 0$).
