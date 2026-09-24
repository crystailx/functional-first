# Review Signals

Review runs on observable markers, not on judgement questions. "Is this function pure enough"
cannot be checked; "a `Repository` type appears in a decision function's parameters" can be
grepped.

A signal is a prompt, not a verdict. Signals over-fire and under-fire by nature — read the
code before concluding.

### Signal 1 — Core/shell

A module holding decision logic imports a database, HTTP, or time package.

```java
// trips the signal — deciding and fetching in one place
BigDecimal total(OrderId id) { return repo.load(id).lines()...; }

// clean — the caller loads, this decides
BigDecimal total(List<Line> lines) { ... }
```

### Signal 2 — Decide/execute

A function that both computes a value and performs a write. Also: a core function whose
return type is `void` or `Unit` — a decision that returns nothing has already been executed
somewhere inside.

### Signal 3 — Immutability

A parameter mutated in place, a setter, or a shared mutable collection escaping a function.

### Signal 4 — Types

A function whose parameter is an already-parsed type, re-checking that type's invariant in its
body — the boundary parsed it once, so a second check means the type is not carrying its
guarantee.

Also: on Java **21+**, a `default` branch in a `switch` over a **sealed** hierarchy — it
discards the exhaustiveness check that sealing exists to provide.

Scope matters here, because the verdict is not the same at every Effective Language Level, and
at one of them the construct being judged cannot be written at all:

| Effective Language Level | Selector | `default` branch |
|---|---|---|
| 21+ | sealed | **violation** — defeats exhaustiveness |
| 16 / 17 | sealed | unavailable — a `switch` cannot select on a `sealed` type before JEP 441 (Java 21); the tier's substitute is an `instanceof` chain closed by `else` |
| any | non-sealed | correct — ordinary code |

### Signal 5 — Errors

A `catch` block that returns a normal value instead of rethrowing — the exception is standing
in for a return type. Also: a `catch` with an empty body.

### Signal 6 — Dependencies

`Instant.now()`, `UUID.randomUUID()`, `new XxxClient()`, `datetime.now()`, or a global
singleton referenced inside a function body rather than passed in.
