---
name: functional-first
description: Use when designing a service, module, or API; when writing an implementation plan; when choosing a library or framework; when implementing backend logic; or when reviewing code — applies functional structure in any language, resolves which effect machinery a project uses, and supplies per-language idiom.
---

# Functional-First

## The contract

Adopting this skill means accepting Axis A. Only Axis B is negotiable, and only among options
that already satisfy Axis A. A team that does not want functional design should remove the
skill rather than configure it away.

**Axis A — principle rigor.** Applied at full rigor in every language. Never discounted for
language capability: where a language lacks a construct, use the Substitution given in its
reference. Rigor does not change, only form.

1. I/O, database, clock, and network at the edges; decision logic pure.
2. The core returns a description of what should happen; the shell performs it.
3. Data is immutable; transformations return new values. Mutation is confined inside one
   function, leaving it pure from the outside.
4. Illegal states unrepresentable; legal states handled exhaustively. Parse, don't validate —
   the boundary parses once into a validated type and nothing downstream re-checks it.
5. Expected failure is a return value. Exceptions are for genuine bugs and unrecoverable
   conditions.
6. Dependencies are passed in — including clock, randomness, ID generation, and environment.
   No ambient singletons, no global mutable state, no container magic.

**Axis B — abstraction weight.** Which machinery carries the effects. Resolved per project by
Step 2, never assumed.

## Step 1 — Classify the project

Read whether existing source code is present. That is the whole test — never infer it from the
language version, because new projects adopt old versions for real reasons and old projects
run on new runtimes.

**Greenfield** (no existing source): Axis A applies to everything. Framework grain is a
selection criterion — choosing an ORM that demands mutable entities signs up for that tax, so
weigh grain when picking frameworks rather than pleading it afterwards.

**Brownfield** (existing source): Axis A binds every new file and every modified function.
Code merely read or called carries no obligation. Never a global rewrite.

## Step 2 — Resolve the stance

```
brownfield with a build-file signal   → follow what is there. Never ask.
project records a Stance in CLAUDE.md → use it. Never re-ask.
otherwise                             → refresh, ask once, record
```

A signal is a build file (`build.sbt`, `pom.xml`, `build.gradle`, `pyproject.toml`) naming an
effect or FP library — `zio`, `cats-effect`, `arrow-kt`, `vavr`, `returns`, `effect`, `fp-ts`,
`neverthrow` — or those types appearing broadly in source. That list is a fast path, not a
closed set: an unrecognised dependency that looks like effect or FP machinery falls through to
asking, never to `native`.

A signal governs what an existing project is already committed to, never what its reference
offers — so when a signal names a library the matching language reference carries no idiom for,
match that library's existing usage in the codebase and introduce nothing further from it; the
reference still governs everything else.

### Option sets

| Language | Axis-A-compliant machinery | Last verified |
|---|---|---|
| Scala 3 | ZIO 2, cats-effect 3, direct style | 2026-09 |
| Scala 2 | ZIO 2, cats-effect 3, direct style | 2026-09 |
| Java | native | 2026-09 |
| Python | native | 2026-09 |

**More than one option → ask. Exactly one → proceed.** Scala 2 and 3 carry the same members:
both libraries cross-publish to 2.12 and 2.13, and direct style on Scala 2 means plain code
plus discipline, since Ox requires Scala 3.

**Refresh before asking.** These rows are a floor, not a closed list — verify that language's
options by live search immediately before putting the question. A refresh may add an option or
mark one as declining, but may never produce an empty menu or admit an option that fails
Axis A. A row whose last-verified date is old is a prompt to look, not a reason to hesitate.

`native` is a definite architecture, not an absence: an ordinary shell calling the database, a
pure core over records or frozen dataclasses, and failure travelling in a hand-written
`Result` or the language's own sum type.

**Ask about machinery, never about whether to be functional.** Every option on the menu
already satisfies Axis A. Name each option and present its trade-offs, and ask at design time, never
mid-implementation.

Record the answer in the project's `CLAUDE.md`:

```markdown
## functional-first stance
- Axis B: cats-effect 3
- Decided: 2026-09-23 — team already ships cats/http4s services
```

The reason line decides whether the next person revisiting this is deciding or guessing.

## Deviation

Applying a principle below full rigor. Allowed only against this list, and never silently —
name the principle and the reason.

1. **Measured hot path.** Profiling data exists and the mutation is confined inside the
   function. Both halves are required.
2. **Framework grain.** The ORM demands mutable entities. Brownfield only as a plea; in
   greenfield it was a choice. Keep framework types out of the core rather than fighting the
   framework.
3. **Existing-codebase consistency.** Brownfield only, and it protects only Contagious
   Changes — those forcing others to learn something or modify code they own. Adopting an
   effect library is contagious. Adding a `record` or a `sealed interface` is not, so any
   native construct the build target supports is used regardless of surrounding style.

**Substitution is not Deviation.** "This language has no sum type" is not a licence to relax;
the reference gives the substitute form and rigor is unchanged.

## Language references

Load the one matching the language being implemented. They carry capability and idiom only —
what the language and its ecosystem can do, and what idiomatic code looks like.

| Language | Reference |
|---|---|
| Scala 3 | `references/scala-3.md` |
| Scala 2 | `references/scala-2.md` |
| Java | `references/java.md` |
| Python | `references/python.md` |

For review, load `references/review-signals.md`.
