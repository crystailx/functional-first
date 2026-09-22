# Functional-First Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a git-installable marketplace containing the `functional-first` plugin — an always-on CLAUDE.md snippet carrying six structural principles, plus a skill supplying stance resolution, per-language idiom, and review signals.

**Architecture:** The repository is a Claude Code marketplace. The snippet is the guarantee layer: it carries Axis A in full, so the principles hold even when the skill never loads. The skill supplies depth on demand.

**Tech Stack:** Markdown and JSON manifests. No build step, no runtime, no dependencies.

**Spec:** `docs/superpowers/specs/2026-09-23-functional-first-design.md`

## How this plan is verified

This plan ships documents, and documents have no behaviour a unit test can reach. Asserting
that a Markdown file contains a heading you just typed is a tautology at write time and dead
weight at edit time, so there is **no test suite here**.

What can genuinely be verified is behaviour, and each task carries its own gate:

- **Does it install and load?** Add the marketplace from a local path and install.
- **Does it fire when nobody says "functional"?** Run a scenario in a fresh session.
- **Are the ecosystem facts true?** Verify by live search before writing them down.
- **Does the guidance produce the intended code?** Run a scenario and read the output.

A task is done when its gate has been run and its result recorded — not when its file exists.

## Global Constraints

- All shipped artifacts are written in **English**. Only conversation with the user is in Traditional Chinese.
- Every published layer is named `functional-first` — GitHub repo, marketplace, plugin, and skill alike. Install reads `/plugin install functional-first@functional-first`. `functimize` is the local directory name only and appears in no manifest.
- **No test suite, and no Python anywhere in the repo.** Verification is behavioural; see below.
- Axis A is exactly **six principles**, applied at full rigor in every language, never discounted for language capability.
- The deviation whitelist is exactly **three items**: measured hot path, framework grain, existing-codebase consistency. The third is brownfield-only and protects only Contagious Changes.
- Brownfield scope is **new files plus modified functions**. "Module" must never appear as a scope boundary in `SKILL.md`'s body. The frontmatter `description` may use it as a situation noun ("designing a service, module, or API") — that is naming what a user is doing, not defining scope.
- Option sets: Java `{ native }`, Python `{ native }`, Scala 3 `{ ZIO 2, cats-effect 3, direct style }`, Scala 2 `{ ZIO 2, cats-effect 3, direct style }`. Nothing derived from these is stored anywhere — the ask rule is computed, never recorded.
- Ask rule: **set size > 1 → ask; size = 1 → proceed.** No High/Medium/Low level anywhere.
- Review signal 4 fires **only** over a sealed hierarchy at Effective Language Level 21+.
- Java tiers are **8/11**, **16/17**, **21+**. Detection reads the build target plus source evidence, never the runtime.
- Python: a strict type checker (mypy or pyright, strict, with `assert_never`) is a **precondition** for principle 4.
- `references/*.md` carry capability and idiom only. Stance — including option sets — lives in `SKILL.md`.
- Reference order: `scala-2.md` → `scala-3.md` → `java.md` → `python.md`. Scala 2 ships alongside Scala 3, not after it — new projects adopt 2.13 for real reasons, so shipping only Scala 3 would leave the Scala 2 stance resolvable but unsupported.
- Vocabulary is fixed by `CONTEXT.md`: Axis A, Axis B, Deviation, Substitution, Effective Language Level, Stance, Taste Fork, Contagious Change, Failure Signal.

## Target layout

```
functimize/                                     local dir; published as functional-first
├── .claude-plugin/marketplace.json
├── README.md
├── CONTEXT.md                                  already committed
├── docs/                                       already committed
└── plugins/functional-first/
    ├── .claude-plugin/plugin.json
    └── skills/functional-first/
        ├── SKILL.md                            contract, gate, stance, deviation
        ├── snippets/claude-md.md               the always-on block
        └── references/
            ├── review-signals.md
            ├── scala-2.md
            ├── scala-3.md
            ├── java.md
            └── python.md
```

---

### Task 1: Marketplace and plugin manifests

**Files:**
- Create: `.claude-plugin/marketplace.json`
- Create: `plugins/functional-first/.claude-plugin/plugin.json`

**Interfaces:**
- Consumes: nothing
- Produces: the installable marketplace. Every later task writes under `plugins/functional-first/skills/functional-first/`.

Both manifests are required. The plugin manifest alone is not installable from git — the marketplace manifest at the repository root is what `/plugin marketplace add` reads.

- [ ] **Step 1: Create the directory layout**

```bash
mkdir -p .claude-plugin \
         plugins/functional-first/.claude-plugin \
         plugins/functional-first/skills/functional-first/snippets \
         plugins/functional-first/skills/functional-first/references
```

- [ ] **Step 2: Write the marketplace manifest**

Create `.claude-plugin/marketplace.json`:

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "functional-first",
  "description": "Functional-first design guidance for Claude Code",
  "owner": {
    "name": "CrystailX"
  },
  "plugins": [
    {
      "name": "functional-first",
      "description": "A cross-language guideline that biases architecture, planning, implementation, and library selection toward functional design.",
      "author": {
        "name": "CrystailX"
      },
      "category": "productivity",
      "source": "./plugins/functional-first",
      "homepage": "https://github.com/crystailx/functional-first"
    }
  ]
}
```

- [ ] **Step 3: Write the plugin manifest**

Create `plugins/functional-first/.claude-plugin/plugin.json`:

```json
{
  "name": "functional-first",
  "description": "A cross-language guideline that biases architecture, planning, implementation, and library selection toward functional design.",
  "version": "0.1.0",
  "author": {
    "name": "CrystailX"
  },
  "homepage": "https://github.com/crystailx/functional-first",
  "repository": "https://github.com/crystailx/functional-first",
  "license": "MIT",
  "keywords": [
    "functional",
    "architecture",
    "design",
    "scala",
    "java",
    "python"
  ]
}
```

- [ ] **Step 4: GATE — install from the local path and confirm the plugin appears**

Ask the user to run, in their terminal:

```
/plugin marketplace add /Users/changyenh/Codes/functimize
/plugin
```

Expected: the `functional-first` marketplace lists a `functional-first` plugin. Installing it
should succeed even though the skill file does not exist yet — a plugin with no skills is
valid, and this gate isolates manifest problems from skill problems.

This gate also subsumes any separate JSON syntax check: malformed manifests are rejected here,
and rejection by the real loader is better evidence than a parser saying the bytes are valid
JSON.

Record the actual output. If the marketplace is rejected, the manifest shape is wrong and no
later task can be verified — stop and fix it here.

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin plugins/functional-first/.claude-plugin
git commit -m "feat: add marketplace and plugin manifests"
```

---

### Task 2: The CLAUDE.md snippet — the guarantee layer

**Files:**
- Create: `plugins/functional-first/skills/functional-first/snippets/claude-md.md`

**Interfaces:**
- Consumes: the directory layout from Task 1
- Produces: the block installed into either `~/.claude/CLAUDE.md` or a project `CLAUDE.md`, documented by Task 8

This is the only layer that fires unconditionally, so it carries all six principles in full
rather than pointing at them. It loads in every session of every project, so its size is a
real cost: if a principle will not fit, sharpen the wording rather than spend more lines.

- [ ] **Step 1: Write the snippet**

Create `plugins/functional-first/skills/functional-first/snippets/claude-md.md`:

```markdown
## Functional-first

Default to functional structure, in every language:

- I/O, database, clock, and network at the edges; decision logic pure
- The core returns a description of what should happen; the shell performs it
- Data is immutable; transformations return new values
- Illegal states unrepresentable; legal states handled exhaustively
- Expected failure is a return value, not an exception
- Dependencies — including clock, randomness, and IDs — are passed in

Deviating is allowed. Deviating silently is not: name the principle and the reason.

Designing, planning, choosing a library, or reviewing → load
`functional-first:functional-first` for per-language idiom and stance.
Applies whenever brainstorming or writing-plans runs.
```

- [ ] **Step 2: GATE — confirm the block alone changes the output**

Install the block into a scratch project's `CLAUDE.md`. Do **not** install the plugin. In a
fresh session in that project, ask:

> Write me a function that charges a customer and records the payment.

Expected: the result separates the decision from the effect — a pure function computing what
should happen, with the charge and the write performed by the caller — without the words
"functional", "pure", or "immutable" appearing anywhere in the prompt.

This is the Layer 1 guarantee, and it is the single claim the whole hybrid design rests on. If
the output is an ordinary imperative method that charges and writes inline, the block's
wording is too abstract to bind — revise it here rather than relying on the skill to rescue
it later.

Record the function you got back.

- [ ] **Step 3: Commit**

```bash
git add plugins/functional-first/skills/functional-first/snippets/claude-md.md
git commit -m "feat: add always-on CLAUDE.md snippet carrying Axis A"
```

---

### Task 3: SKILL.md — contract, gate, stance, deviation

**Files:**
- Create: `plugins/functional-first/skills/functional-first/SKILL.md`

**Interfaces:**
- Consumes: the six principles from Task 2
- Produces: the skill's `description` (the Layer 3 trigger) and the stance-resolution procedure. Tasks 4–7 are linked from its reference table.

The description is Layer 3 and must name what the user is *doing*, never what the guideline
believes. A description phrased around "functional architecture" matches only users who
already said the word — precisely the population that least needs it.

Option sets live here rather than in `references/`, because an option set is stance and
`references/` carries facts only. Nothing derived from them is stored: whether to ask is
computed from the set's size at the moment it matters.

- [ ] **Step 1: Write SKILL.md**

Create `plugins/functional-first/skills/functional-first/SKILL.md`:

````markdown
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
already satisfies Axis A. Present trade-offs rather than names, and ask at design time, never
mid-implementation.

Record the answer in the project's `CLAUDE.md`:

```markdown
## functional-first
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
````

- [ ] **Step 2: GATE — run the four stance scenarios**

Reinstall the plugin so the new skill is picked up, then run each scenario in a **fresh
session**, recording what actually happened.

| # | Setup | Prompt | Expected |
|---|---|---|---|
| 1 | empty directory | "Design an order service in Scala 3" | skill loads without "functional" in the prompt; classifies greenfield; asks once between the three options, showing trade-offs |
| 2 | `build.sbt` listing `dev.zio::zio` | same | does **not** ask; follows ZIO |
| 3 | `CLAUDE.md` with a recorded Stance | same | does **not** ask; uses the recorded stance |
| 4 | empty directory | "Design an order service in Java" | does **not** ask — one option |

Scenario 1 failing to load is the most important failure mode in this design. If it does not
fire, the `description` is wrong — revise it here, not the principles.

- [ ] **Step 3: Commit**

```bash
git add plugins/functional-first/skills/functional-first/SKILL.md
git commit -m "feat: add SKILL.md with contract, gate, stance resolution, deviation"
```

---

### Task 4: Review signals reference

**Files:**
- Create: `plugins/functional-first/skills/functional-first/references/review-signals.md`

**Interfaces:**
- Consumes: the six principles from Task 3's `SKILL.md`
- Produces: the signal definitions; Task 7's Java tier table is cited by Signal 4

- [ ] **Step 1: Write the reference**

Create `plugins/functional-first/skills/functional-first/references/review-signals.md`:

````markdown
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
````

- [ ] **Step 2: GATE — confirm Signal 4 discriminates**

Write two Java 21 files in a scratch directory: one `switch` over a `sealed interface` with a
`default -> throw` branch, and one `switch` over a plain `String` with a `default` branch. Ask
the skill to review both.

Expected: the first is flagged, the second is not. A signal that fires on both is worse than
no signal, because it trains the reader to ignore it.

- [ ] **Step 3: Commit**

```bash
git add plugins/functional-first/skills/functional-first/references/review-signals.md
git commit -m "feat: add review signals reference"
```

---

### Task 5: Scala 2 reference

**Files:**
- Create: `plugins/functional-first/skills/functional-first/references/scala-2.md`

**Interfaces:**
- Consumes: the Scala 2 option set from Task 3's `SKILL.md`
- Produces: idiom for all three options on Scala 2, and **the worked example** — one small
  domain, carried unchanged into `scala-3.md` in Task 6 so a reader moving between the two
  files compares like with like

**Scala 2 is not a legacy tier and this reference is not a migration note.** New projects adopt
2.13 for real reasons — Spark's cross-publishing being the common one — so it carries the same
weight as `scala-3.md`. It ships first precisely so it is written on its own terms rather than
as a diff against Scala 3.

This reference documents ZIO, cats-effect, and direct style **even-handedly**. Describing how
each is written is a fact; saying which to pick is stance and belongs in `SKILL.md`.

- [ ] **Step 1: Verify the ecosystem facts before writing them**

The spec flags its ecosystem claims as recalled rather than verified. Search for the current
state of: which Scala 2 versions ZIO 2 and cats-effect 3 cross-publish for; whether any
direct-style library serves Scala 2, given Ox requires Scala 3; whether a non-exhaustive
`match` over a `sealed trait` is a **warning or an error** by default in 2.13 and which
compiler flag makes it fatal; and Spark's current Scala version support, since that is the most
common reason a new project is on 2.13 at all.

If any finding contradicts the option-set table in `SKILL.md`, fix that table first and re-run
Task 3's gate before continuing.

- [ ] **Step 2: Write the reference**

Create `references/scala-2.md`, structured as:

- A header line `last-verified: YYYY-MM` recording Step 1's findings.
- **Making principle 4 enforced**, stated first because it governs everything below.
  Exhaustivity over a `sealed trait` is reported as a compiler warning rather than an error
  unless fatal warnings are enabled. Give the exact flag found in Step 1, and say plainly that
  without it principle 4 is advisory in that project — the same shape as Python's
  strict-checker precondition, and for the same reason: a guarantee nobody enforces is not a
  guarantee.
- **Native capability** — `sealed trait` plus `case class` for ADTs, value classes
  (`extends AnyVal`) for zero-cost wrappers, implicit parameters for dependency passing, and
  right-biased `Either` (`since: 2.12`). Include the **worked example** here — one small domain,
  a pure decision function returning `Either`, and the caller performing effects. Task 6 reuses
  this same domain, so choose one that survives translation.
- **ZIO 2 idiom** — `ZIO[R, E, A]` carrying environment, typed error, and result; `ZLayer` for
  dependency wiring; and the note that principle 2 is satisfied structurally because a `ZIO`
  value *is* a description. The same worked example, naming the cross-published artifact found
  in Step 1.
- **cats-effect 3 idiom** — `IO`, `Resource`, `Ref`; constructor injection or tagless final for
  principle 6; typical companions (`http4s`, `fs2`, `doobie`). The same worked example.
- **Direct style idiom** — the same example with no effect monad: a pure `sealed trait` core,
  `Either` for failure, effects performed by ordinary code at the edge. State outright that Ox
  is unavailable here and what stands in its place per Step 1.
- **Substitutions** — a table mapping each Scala 3 construct to its Scala 2 form (`enum` →
  `sealed trait` + `case class`; `opaque type` → value class; `given`/`using` → implicit
  parameters; union types → no equivalent, model explicitly). This table is what stops a reader
  or a model defaulting to Scala 3 idiom from writing code that will not compile — which is the
  direction that actually breaks, since Scala 2 forms remain legal in Scala 3.

Every construct carries a `since:` marker where it is not available across all supported 2.x
releases. No section states or implies a preference between the three options, and none frames
Scala 2 as a lesser version of Scala 3.

- [ ] **Step 3: GATE — implement with it and read the output**

In a scratch Scala 2.13 project with a recorded Stance of `cats-effect 3`, ask for a small
feature — "add an endpoint that cancels an order". Expected: the decision logic is a pure
function over the `sealed trait` model returning `Either`, effects sit at the edge, and the
cats-effect idiom matches the reference rather than being invented.

Then repeat with the Stance set to `direct style`. Expected: the same pure core, no `IO`, and
no suggestion that direct style is the weaker choice.

Also confirm that scaffolding the build mentions the fatal-warnings flag. Omitting it silently
is the failure this gate exists to catch: the model will look correct while enforcing nothing.

- [ ] **Step 4: Commit**

```bash
git add plugins/functional-first/skills/functional-first/references/scala-2.md
git commit -m "feat: add Scala 2 reference with exhaustivity-enforcement precondition"
```

---

### Task 6: Scala 3 reference

**Files:**
- Create: `plugins/functional-first/skills/functional-first/references/scala-3.md`

**Interfaces:**
- Consumes: the Scala 3 option set from Task 3's `SKILL.md`; **the worked example** defined in
  Task 5's `scala-2.md`, carried over unchanged so the two files compare like with like
- Produces: idiom for all three options on Scala 3, loaded when implementing Scala 3

This reference documents ZIO, cats-effect, and direct style **even-handedly**. Describing how
each is written is a fact; saying which to pick is stance and belongs in `SKILL.md`.

- [ ] **Step 1: Verify the ecosystem facts before writing them**

Search for the current state of: ZIO 2's latest line and its Scala 3 support; cats-effect 3's
latest line; whether Ox is still the active direct-style library for Scala 3; and whether a
non-exhaustive `match` over an `enum` or `sealed` type is a **warning or an error** by default,
plus which compiler flag makes it fatal. That last one decides whether principle 4 is enforced
or merely documented — Task 5 will have established the Scala 2 answer, and the two need not
match.

If any finding contradicts the option-set table in `SKILL.md`, fix that table first and re-run
Task 3's gate before continuing.

- [ ] **Step 2: Write the reference**

Create `references/scala-3.md`, structured as:

- A header line `last-verified: YYYY-MM` recording Step 1's findings.
- **Enforcing principle 4** — state whether exhaustivity is a warning or an error by default
  per Step 1, and give the flag that makes it fatal. If the answer differs from Scala 2's, say
  so; a reader arriving from `scala-2.md` will assume it carries over.
- **Native capability** — `enum` for ADTs (`since: 3.0`), `case class` for immutable records,
  `opaque type` for zero-cost wrappers (`since: 3.0`), `given`/`using` for explicit dependency
  passing (`since: 3.0`), compiler exhaustiveness over `enum` and `sealed` in `match`, and
  `Either` for errors as values. Carry over **the worked example from `scala-2.md`** — the same
  domain, now expressed with `enum` — so the difference on the page is idiom and nothing else.
- **ZIO 2 idiom** — `ZIO[R, E, A]` carrying environment, typed error, and result; `ZLayer` for
  dependency wiring; and the note that principle 2 is satisfied structurally because a `ZIO`
  value *is* a description. The same worked example expressed in ZIO.
- **cats-effect 3 idiom** — `IO`, `Resource`, `Ref`; constructor injection or tagless final for
  principle 6; typical companions (`http4s`, `fs2`, `doobie`). The same worked example.
- **Direct style idiom** — the same example with no effect monad: a pure `enum`-based core,
  `Either` for failure, effects performed by ordinary code at the edge, and the concurrency
  tooling noted with its `since:` marker per Step 1's findings.
- **Substitutions** — none needed; Scala 3 expresses every Axis A principle natively. Point at
  `scala-2.md`'s substitution table for readers moving the other way, since Scala 3 constructs
  are the ones that fail to compile on 2.13.

Every construct not available in all supported Scala 3 releases carries a `since:` marker. No
section states or implies a preference between the three options.

- [ ] **Step 3: GATE — confirm the version is read, not assumed**

Two scratch sbt projects with identical requests, one `scalaVersion := "3.x"` and one
`scalaVersion := "2.13.x"`. Ask for the same small domain model in each.

Expected: the first uses `enum`, the second uses `sealed trait` plus `case class`, and neither
output suggests the other is the proper way. A single answer in both is a failure — it means
the version was assumed rather than read from the build.

- [ ] **Step 4: Commit**

```bash
git add plugins/functional-first/skills/functional-first/references/scala-3.md
git commit -m "feat: add Scala 3 reference covering all three machinery options"
```

---

### Task 7: Java reference

**Files:**
- Create: `plugins/functional-first/skills/functional-first/references/java.md`

**Interfaces:**
- Consumes: the Java option set from Task 3's `SKILL.md`
- Produces: the three-tier capability table cited by Signal 4 in Task 4

- [ ] **Step 1: Verify the ecosystem facts before writing them**

Search for the current state of: Vavr's release activity and whether 1.0 has shipped; whether
any Java-native effect library has gained meaningful adoption; and Java pattern-matching
features finalized after 21.

If a Java effect library has become mainstream, `SKILL.md`'s `native`-only row for Java must
become a multi-member set — fix it there and re-run Task 3's gate before continuing.

- [ ] **Step 2: Write the reference**

Create `references/java.md`, structured as:

- A header line `last-verified: YYYY-MM`.
- **Reading the Effective Language Level** — from `maven.compiler.release` or
  `sourceCompatibility`, plus evidence in source (does `record` or `sealed` appear anywhere),
  stated explicitly as never the runtime. Note that a project may compile at 21 and be written
  entirely in Java 8 style.
- **Capability by tier** — a table with columns `Effective level | record | sealed | switch
  patterns + exhaustiveness` and rows `8 / 11`, `16 / 17`, `21+`.
- **Tier 21+ idiom** (`since: 21`) — `record` plus `sealed interface` for the ADT, `switch`
  with record patterns for exhaustive handling. One worked decision example.
- **Tier 16/17 idiom** (`since: 16` for `record`, `since: 17` for `sealed`) — the same ADT
  matched with an `instanceof` chain closing on `default -> throw new AssertionError()`, with
  exhaustiveness noted as unchecked.
- **Tier 8/11 Substitution** — no `record`, no `sealed`. Immutability via hand-written final
  fields or an annotation processor; the **visitor pattern** as the only construction giving
  compiler-checked exhaustiveness, because adding a case to the visitor interface breaks every
  implementor at compile time. One worked visitor example.
- **Errors as values across all tiers** — a sealed or visitor-based result type rather than
  checked exceptions.
- **Dependencies** — constructor parameters including a `Clock`, contrasted against
  `Instant.now()` in a method body.

- [ ] **Step 3: GATE — confirm the tier is detected, not assumed**

Create two scratch Maven projects with identical source: one with
`<maven.compiler.release>21</maven.compiler.release>`, one with `8`. Ask for the same small
model in each.

Expected: the first uses `record` and `sealed interface`; the second uses the visitor pattern
and never suggests a construct the build target cannot compile. A single correct answer in
both is a failure — it means the tier was assumed rather than read.

- [ ] **Step 4: Commit**

```bash
git add plugins/functional-first/skills/functional-first/references/java.md
git commit -m "feat: add Java reference with 8/17/21 capability tiers"
```

---

### Task 8: Python reference

**Files:**
- Create: `plugins/functional-first/skills/functional-first/references/python.md`

**Interfaces:**
- Consumes: the Python option set from Task 3's `SKILL.md`
- Produces: the strict-checker precondition wording; the last reference in this plan

- [ ] **Step 1: Verify the ecosystem facts before writing them**

Search for the current state of: whether `returns` or another Python FP library has gained
mainstream adoption; the current strict-mode flags for mypy and pyright; and any typing
features after 3.12 affecting sum-type modelling.

If a Python FP library has become mainstream, fix `SKILL.md`'s Python row and re-run Task 3's
gate before continuing.

- [ ] **Step 2: Write the reference**

Create `references/python.md`, structured as:

- A header line `last-verified: YYYY-MM`.
- **The precondition**, stated first because it governs everything below: a strict type checker
  (mypy or pyright in strict mode, with `typing.assert_never`) is a precondition for
  principle 4. Unlike Java 8, which has the visitor pattern, Python has **no** built-in
  construction turning a missing case into an error. Where a project has no strict checker,
  say plainly that principle 4 carries **documentation value only** there, and degrade —
  silence is worse than absence, because rigorous-looking models with zero enforcement mislead
  readers into believing they are protected.
- **Native capability** — `@dataclass(frozen=True)` for immutable records; tagged unions via
  `Literal` discriminants plus `Union` (or `X | Y`, `since: 3.10`); `match`/`case` structural
  pattern matching (`since: 3.10`); `assert_never` for exhaustiveness (`since: 3.11`, with the
  `typing_extensions` fallback noted).
- **A hand-written `Result`** — roughly twenty lines of frozen generic dataclasses `Ok` and
  `Err` with a `Union` alias, shown in full, and noted as reading more like Python than a
  dependency would.
- **A worked example** — a tagged-union domain model, a pure decision function returning
  `Result`, a `match` with an `assert_never` fallthrough, and effects performed by the caller.
- **Dependencies** — a clock passed as a parameter, contrasted against `datetime.now()` in a
  function body.
- **Substitutions** — `Literal` discriminants standing in for real sum types, with the
  limitation stated outright: the guarantee comes from the checker, not the language.

- [ ] **Step 3: GATE — confirm the precondition changes behaviour**

Two scratch Python projects: one with `mypy --strict` configured in `pyproject.toml`, one with
no type checker at all. Ask for the same tagged-union model in each.

Expected: the first produces the model with `assert_never` and says nothing special; the
second produces it **and says plainly that principle 4 carries documentation value only here**,
because nothing enforces it. Silence in the second case is the failure this gate exists to
catch.

- [ ] **Step 4: Commit**

```bash
git add plugins/functional-first/skills/functional-first/references/python.md
git commit -m "feat: add Python reference with strict-checker precondition"
```

---

### Task 9: README and install documentation

**Files:**
- Create: `README.md`

**Interfaces:**
- Consumes: every artifact from Tasks 1–8
- Produces: the shipped repository

- [ ] **Step 1: Write the README**

Create `README.md` covering:

- What the guideline is, in two sentences.
- The contract, quoted from `SKILL.md` — adopting it means accepting Axis A; a team that does
  not want functional design removes the skill.
- **Installing the plugin**, with the exact commands:
  ```
  /plugin marketplace add crystailx/functional-first
  /plugin install functional-first@functional-first
  ```
- **Installing the snippet**, with the two adoption modes as a table — `~/.claude/CLAUDE.md`
  for an individual, covering all their projects; a project `CLAUDE.md` for a team, covering
  everyone on the repo — and the sentence that the snippet carries the principles so they hold
  **even when the skill never loads**.
- How a project records its Stance, with the three-line example.
- The six principles, listed, so a reader can decide whether to adopt without installing
  anything.

- [ ] **Step 2: GATE — install from git on a clean machine path**

Push the branch, then from a directory that is not this repo:

```
/plugin marketplace add <the pushed git URL>
/plugin install functional-first@functional-first
```

Then run Task 3's scenario 1 once more. Expected: identical behaviour to the local-path
install. A plugin that works locally but not from git has a path or manifest problem that only
this gate catches.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: add README with installation and adoption modes"
```

---

## Notes for the executor

- **There is no test suite, deliberately.** Asserting that a Markdown file contains a heading
  you just typed proves nothing and rots on the first edit. Every gate in this plan runs the
  artifact and observes behaviour instead. If a gate feels hard to run, that is information
  about the artifact, not a reason to replace it with an assertion.
- **Nothing derived is ever stored.** Whether to ask is computed from the option set's size at
  the moment it matters. An earlier draft of this plan stored an `asks` flag beside each set
  and then added a test to keep the two consistent — which is precisely the failure principles
  3 and 6 exist to prevent.
- **Verify before writing ecosystem facts.** Tasks 5–8 each open with a search step. Treat a
  contradiction with `SKILL.md`'s option-set table as a finding to fix there first.
- **References are facts, never stance.** If a sentence tells the reader which library to pick,
  it belongs in `SKILL.md` or nowhere.
- **`kotlin.md`, `typescript.md`, and `go.md` are out of scope here.** `SKILL.md` lists only the
  references that exist; add rows as the files arrive in later plans.
