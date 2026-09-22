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

A function both computes and writes, or returns `void`/`Unit` while carrying meaning.

### Signal 3 — Immutability

A parameter mutated in place, a setter, or a shared mutable collection escaping a function.

### Signal 4 — Types

The same validation repeating across layers.

Also: on Java **21+**, a `default` branch in a `switch` over a **sealed** hierarchy — it
discards the exhaustiveness check that sealing exists to provide.

Scope matters here, because the same construct is correct in two of the three places it
appears:

| Effective Language Level | Selector | `default` branch |
|---|---|---|
| 21+ | sealed | **violation** — defeats exhaustiveness |
| 16 / 17 | sealed | correct — the prescribed idiom; matching is an `instanceof` chain |
| any | non-sealed | correct — ordinary code |

### Signal 5 — Errors

Expected failure raised as an exception and caught as control flow; or a swallowed `catch`.

### Signal 6 — Dependencies

`Instant.now()`, `UUID.randomUUID()`, `new XxxClient()`, `datetime.now()`, or a global
singleton referenced inside a function body rather than passed in.
