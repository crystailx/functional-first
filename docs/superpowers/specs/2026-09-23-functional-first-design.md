# Functional-First Design Guideline — Design

**Status:** proposed
**Date:** 2026-09-23
**Artifact:** the `functional-first` plugin, shipping the `functional-first` skill

## 1. Purpose and contract

A cross-language guideline that biases architecture, implementation planning, implementation,
and library selection toward functional design. It is built to be adopted by any team, not
tuned to one person's taste.

The contract is explicit and belongs at the top of `SKILL.md`:

> Adopting this skill means accepting Axis A. Only Axis B is negotiable, and only among
> options that already satisfy Axis A. If a team does not want functional design, the correct
> action is to remove the skill — not to configure it away.

This matters because a guideline that can be talked out of its own premise is decoration. The
only thing a project chooses is which machinery carries its effects.

## 2. Vocabulary

Defined in [`CONTEXT.md`](../../../CONTEXT.md): Axis A, Axis B, Deviation, Substitution,
Effective Language Level, Stance, Taste Fork, Contagious Change, Failure Signal.

The single load-bearing distinction: **Axis A is not Axis B.** Axis A is structure and costs
no dependency. Axis B is abstraction weight and costs a learning curve. Conflating them is
what makes guidelines like this one fail — it produces either blanket rejection ("we don't
want monads") or blanket adoption ("everything must be an effect").

## 3. Axis A — the six principles

Applied at full rigor in every language. Never discounted for language capability; where a
language lacks a construct, the reference supplies a Substitution and rigor is unchanged.

1. **Functional core, imperative shell.** I/O, database, clock, and network live at the
   outermost layer. Decision logic is pure.
2. **Separate decide from execute.** The core returns a description of what should happen —
   a command, an event, a plan — and the shell performs it. This is the operational form of
   principle 1; without it people write a "pure core" that calls a repository. It is also the
   only source of tests that need no mocks.
3. **Immutable by default.** Transformations return new values. Mutation is permitted only
   when confined inside a single function, leaving it pure from the outside.
4. **Make the type system work.** Illegal states are unrepresentable, and legal states are
   handled exhaustively. Parse, don't validate: the boundary parses input once into a
   validated type, and nothing downstream re-checks it.
5. **Errors are values.** Expected failure travels in the return type. Exceptions are reserved
   for genuine bugs and unrecoverable conditions.
6. **Dependencies are explicit.** Passed as arguments — including clock, randomness, ID
   generation, and environment. No ambient singletons, no global mutable state, no DI
   container magic.

**Deliberately excluded:** "prefer map/filter/reduce", point-free style, "composition over
inheritance". The first two are consequences of the six above rather than causes, and the
third is OO self-correction rather than a functional claim. Admitting them degrades the
guideline into a style checklist, which is the most common failure mode for documents of this
kind.

## 4. Axis B — stance resolution

### 4.1 The greenfield gate

`SKILL.md`'s first action is to classify the project. The test is solely **whether existing
source code is present**. It is never inferred from language version: new projects adopt old
language versions for real reasons (Spark's Scala cross-publishing being the common one), and
old projects run on new runtimes.

**Scope is defined by the changeset, not by a structural unit.** Axis A binds every new file
and every function actually modified; code merely read or called carries no obligation. This
deliberately avoids defining "module" at all. Build units and package boundaries are either
absent or meaningless in most repos — a flat Python package, a single-artifact Maven build —
whereas the set of functions being changed is always defined, in every language and every
layout.

Four of five downstream decisions branch on this classification, which is why it is
first-class rather than a footnote:

| Decision | Branches? |
|---|---|
| Axis A rigor | No — always full |
| Axis A scope of work | Yes — in brownfield, Axis A binds new files and modified functions only; never a global rewrite |
| Axis B stance | Yes |
| Existing-codebase Deviation | Yes — brownfield only |
| Framework grain | Yes — a selection criterion in greenfield, a fait accompli in brownfield |

### 4.2 Resolution order

```
brownfield with a codebase signal  → follow what is there. Never ask.
                                     (switching effect systems is a Contagious Change)
project has a recorded Stance      → use it. Never re-ask.
otherwise                          → ask the user, then record the answer
```

A codebase signal is read mechanically: the build file (`build.sbt`, `pom.xml`, `build.gradle`,
`pyproject.toml`) naming an effect library, or that library's types appearing broadly in source.

The recognised names are a **fast path, not a closed set**, and the failure mode is
deliberately benign. An unrecognised dependency that looks like effect or FP machinery falls
through to asking — which costs one question and cannot produce a wrong answer. A list going
stale therefore never silently degrades a project to `native`; the worst it does is ask
something it could have inferred.

### 4.3 The option set

Per language, the guideline holds the set of **Axis-A-compliant machinery** available. It
holds no ranking and names no favourite.

`native` is a definite architecture, not an absence. The shell is ordinary code that calls the
database; the core is pure functions over records or frozen dataclasses; expected failure
travels in a hand-written `Result` or the language's own sum type. There is simply no effect
runtime in the picture.

| Language | Shipped option set | Behaviour |
|---|---|---|
| Java | `{ native }` | size 1 → never asks |
| Python | `{ native }` | size 1 → never asks |
| Scala 3 | `{ ZIO 2, cats-effect 3, direct style }` | size > 1 → asks once |
| Scala 2 | `{ ZIO 2, cats-effect 3, direct style }` | size > 1 → asks once |

The rule is one line: **set size > 1 → ask; size = 1 → proceed.** No "aggressiveness level"
threshold for a model to misjudge.

Scala 2 and Scala 3 carry the same members with different notes: ZIO 2 and cats-effect 3 both
cross-publish to 2.12 and 2.13, while direct style on Scala 2 means plain code plus discipline
because Ox requires Scala 3.

### 4.3.1 The set is a floor, refreshed by search

Ecosystem facts are the fastest-moving content in this guideline, and a set baked in at
authoring time will be wrong within a year. So each set carries a `last-verified` date and is
**refreshed by a live search immediately before the question is put to the user**.

This is affordable precisely because asking is rare — once per greenfield project, and never
at all for single-member sets. The shipped set is the floor: a refresh may add an option or
mark one as declining, but it may never yield an empty menu, and every option it adds must
satisfy Axis A.

Java and Python hold `{ native }` because there is nothing worth betting on rather than out of
conservatism. Both reach full Axis A natively, and in Python a hand-written `Result` of roughly
twenty lines reads better than a niche dependency.

For Java the reason is a distinction rather than a scarcity, and the first refresh is what
found it. This spec originally justified the row by calling Java's FP ecosystem thin and Vavr
moribund. **Vavr reached 1.0 in February 2026**, so that justification is simply false — but
the row survives it, because Vavr supplies `Try`, `Either`, and immutable collections, and
those are data types rather than effect machinery. Axis B asks which machinery carries the
effects. Vavr stands to Java as cats core stands to Scala: real, useful, and not an answer to
that question, which is why neither appears in an option set. No Java effect runtime with
adoption comparable to ZIO or cats-effect exists, and Loom makes direct style viable.

A project that already uses Vavr is a different matter, and is handled by a different
mechanism: `vavr` is in the build-file signal list, so a brownfield Java project using it is
followed rather than asked. Option sets govern what a greenfield project is offered; signals
govern what an existing one is already committed to. The two lists are not required to match.

These are exactly the claims the refresh exists to re-check. Had the refresh found an effect
runtime rather than a data-type library, it would have turned `{ native }` into a question that
did not previously exist.

### 4.4 Asking well

When the guideline asks, the question is *which machinery carries the effects*, never *whether
to be functional*. Every option presented satisfies Axis A — including direct style, which
keeps ADTs, immutability, errors-as-values, and a pure core while declining an effect monad.

The question must name each option and present its trade-offs, so a team can actually decide, and it
fires at architecture-design time — never mid-implementation.

### 4.5 Recording the stance

Written into the **project's `CLAUDE.md`**, chosen over a dedicated config file because it is
already the recognised home for project rules and is loaded for free:

```markdown
## functional-first
- Axis B: cats-effect 3
- Decided: 2026-09-23 — team already ships cats/http4s services
```

The reason line is not decoration. Six months later it determines whether someone revisiting
the choice is deciding or guessing.

## 5. Deviation

Applying a principle below full rigor on Axis A. Permitted only against this whitelist, and
the deviation must be stated out loud when it happens.

| Deviation | Greenfield | Brownfield |
|---|:-:|:-:|
| Measured hot path — profiling data exists, mutation confined inside the function | yes | yes |
| Framework grain — the ORM demands mutable entities | see below | yes |
| Existing-codebase consistency | no | yes |

**Framework grain is a selection criterion in greenfield, not an excuse.** Choosing Spring
plus JPA signs up for the mutable-entity tax; the grain was chosen, so it cannot later be
pleaded. Greenfield work should weigh grain compatibility when picking frameworks. In
brownfield the grain is a genuine fait accompli — the response is to keep framework types out
of the core rather than to fight the framework.

**Existing-codebase consistency protects only Contagious Changes.** Adopting an effect library
is contagious: everyone who touches it must learn it. Adding a `record` or a `sealed interface`
is not — it is just a class, and no one else has to change anything. So any native construct
the build target supports is used regardless of surrounding style.

**Substitution is not Deviation.** "This language has no sum type" is not a licence to relax;
the reference supplies the substitute form and rigor is unchanged. Without this rule Go and
Python become permanent exemption zones.

## 6. Language references

### 6.1 Facts only

`references/<lang>.md` describes **capability and idiom** — what the language and its
ecosystem can do, and what the idiomatic form looks like. This includes ecosystem capability:
describing how ZIO code is written is a fact. What a reference never contains is a stance:
*which* to use lives in `SKILL.md`.

The payoff is maintenance. Ecosystem shifts touch `SKILL.md` only; language releases touch one
reference only. It also directly prevents the cargo-cult failure mode, because each reference
states the idiomatic form outright and leaves no room to import Haskell vocabulary into Python.

**A reference names another language only in a see-also pointer or a cross-language substitution
table.** When explaining its own language's situation it may not, because references load one at a
time and the reader has only the file in front of them. The way to tell the two apart is a removal
test, applied to the passage rather than to the single sentence: delete the other language's name.
If the surrounding text still carries the information — because the fact being compared against is
stated in place, or the file holding it is named — the mention was additive and is fine. If the
meaning collapses because the foreign name was the only thing carrying it, restate it in
language-neutral terms.

The sentence-only reading of this test misfires, and did: a passage that names `scala-2.md`, states
the Scala behaviour inline, and only then draws its contrast is self-sufficient, even though the
word "Scala" cannot be deleted from one of its sentences.

This escaped review because the binding constraint was that references must not take a stance on
which library to use, and reviewers checked exactly that. Naming a Scala library inside the Python
reference is not a stance — it recommends nothing — so no constraint covered comprehensibility and
nobody was looking for it.

### 6.2 Version axis

Every idiom carries a minimum-version marker. This is general, not a Java special case —
Python has one (3.10 `match`, 3.12 type syntax) and Scala's is the largest of all.

**One file per language, except Scala.** The test is whether the version difference is an
increment or a rewrite. Java 8 → 21 is an increment: old forms remain legal, newer ones are
better. Scala 2 → 3 is a rewrite: `enum` and `given` are new syntax and implicits are the old
world. Hence `scala-2.md` and `scala-3.md` as separate files, everything else versioned inline.

Effective Language Level is read from the build target (`maven.compiler.release`,
`sourceCompatibility`) plus source evidence — never from the runtime. A project may compile at
21 and be written entirely in Java 8 style.

### 6.3 Java tiers

| Effective level | record | sealed | switch patterns + exhaustiveness | How principle 4 lands |
|---|:-:|:-:|:-:|---|
| 8 / 11 | no | no | no | Immutability via Immutables / AutoValue / Lombok `@Value`. The **visitor pattern** is the only construction with compiler-checked exhaustiveness — add a case and every implementor fails to compile. |
| 16 / 17 | yes | yes | no | `record` + `sealed interface` express the ADT; there is no `switch` form to reach for at all before JEP 441, so matching is an `instanceof` chain closed by `else { throw }`, exhaustiveness unchecked. |
| 21+ | yes | yes | yes | `switch` patterns and record patterns, exhaustiveness checked by the compiler. |

The Java 8 row is the one most often skipped. The visitor pattern is ugly, but without it a
Java 8 project has no mechanical hold on principle 4 at all.

This spec originally described the 16/17 cell's idiom as "an `instanceof` chain with
`default -> throw`". **A `switch` cannot select on a `sealed` type at all before JEP 441
landed in Java 21**, so that description is simply false — and false a second way, because it
also conflates two different constructs: `default` is a `switch` arm, and the `instanceof`
chain actually closes with `else`, which has no `default` of its own. Verified directly against
`javac 17.0.12`: a `switch` over a sealed selector, in its simplest form
(`switch (s) { default -> "no"; }`), fails to compile, with "patterns in switch statements are a
preview feature and are disabled by default". What is true instead is what the corrected cell
above says — matching at 16/17 is only ever an `instanceof` chain, closed by an `else` that
throws — also verified directly against `javac 17`.

### 6.4 Python

A strict type checker (mypy or pyright, strict mode, with `assert_never`) is a **precondition**
for principle 4 in Python. Unlike Java 8 — which at least has the visitor pattern — Python has
no built-in substitute that produces a compile-time error.

Where a project has no strict checker, the reference says plainly that principle 4 carries
documentation value only in that project, and degrades accordingly. Silence here is worse than
absence: it produces rigorous-looking `Union` + `Literal` models with zero enforcement, which
misleads readers into believing they are protected.

Python is the clearest case but may not be the only one. Scala reports a non-exhaustive match
over a sealed hierarchy as a compiler warning rather than an error unless fatal warnings are
enabled, which would make a compiler flag a precondition of the same shape. Each language
reference establishes its own answer during the verification step that opens its work, and
states the flag where one is needed.

### 6.5 Order of work

`scala-2.md` → `scala-3.md` → `java.md` → `python.md`, then `kotlin.md`, `typescript.md`,
`go.md`. References are created lazily; writing one on demand beats writing it early and
letting it rot.

**Scala 2 and Scala 3 ship together, and Scala 2 goes first.** Shipping only one would leave
the other's stance resolvable but unsupported — `SKILL.md` would answer "cats-effect 3" for a
2.13 project and then have no idiom to offer, which is worse than not covering Scala 2 at all.
Scala 2 is written first so it stands on its own terms rather than as a diff against Scala 3,
and it carries the worked example that `scala-3.md` then re-expresses. It is not a legacy tier:
new projects adopt 2.13 for real reasons, Spark's cross-publishing being the common one.

## 7. Review — failure signals

Review is conducted with mechanically observable signals, never subjective questions. "Is this
function pure enough?" cannot be checked; "a `Repository` type appears in a decision function's
parameters" can be grepped.

Holding that line is harder than it looks. A first draft of these six paired a mechanical
clause with a judgement clause in three of them — "while carrying meaning", "the same
validation repeating across layers", "caught as control flow" — each of which smuggles back
exactly the kind of question this section exists to exclude. Every signal below names something
a reader can point at.

| Principle | Failure signal |
|---|---|
| 1 Core/shell | A core module imports a db, http, or time package |
| 2 Decide/execute | A function both computes a value and performs a write; or a core function returns `void`/`Unit` |
| 3 Immutability | A parameter is mutated in place; setters; shared mutable collections |
| 4 Types | A function re-checks the invariant of an already-parsed parameter type; on Java 21+, a `default` branch in a `switch` over a **sealed** hierarchy |
| 5 Errors | A `catch` that returns a normal value instead of rethrowing; a `catch` with an empty body |
| 6 Dependencies | `Instant.now()`, `UUID.randomUUID()`, `new XxxClient()`, or a global singleton inside a function body |

Signal 4 needs its scope stated precisely, because the verdict is not the same at every
Effective Language Level, and at one of them there is no such construct to judge in the first
place (see the correction in §6.3). A `default` branch is a violation **only** when the
selector is a sealed hierarchy **and** the Effective Language Level is 21 or above — there it
discards the compiler's exhaustiveness check, which is the entire reason for sealing the type.
On 16/17 no `switch` over a sealed selector exists to carry a `default` at all — matching there
is an `instanceof` chain closed by `else` — and over a non-sealed selector a `default` branch
is ordinary correct code at any version.

## 8. Artifacts and load timing

```
functimize/                                  local dir; published as functional-first
├── .claude-plugin/marketplace.json          what `/plugin marketplace add` reads
├── CONTEXT.md                               glossary
├── docs/adr/                                decisions
└── plugins/functional-first/
    ├── .claude-plugin/plugin.json
    ├── hooks/hooks.json, session-start  SessionStart hook emitting the block
    └── skills/functional-first/
        ├── SKILL.md                         contract, greenfield gate, stance
        │                                    resolution incl. option sets, deviation
        ├── snippets/claude-md.md            the always-on block, source for the hook
        └── references/
            ├── review-signals.md            the six failure signals
            ├── scala-3.md  scala-2.md
            ├── java.md     python.md
            └── kotlin.md   typescript.md   go.md
```

| Artifact | Loaded when |
|---|---|
| The `CLAUDE.md` block | Always — it carries Axis A itself, see §9.1 |
| `SKILL.md` | Architecture design, library selection, code review |
| `references/<lang>.md` | Implementing in that language |

Structural decisions are worth the most at design time, when they are still cheap to change.
Idiom detail is only needed at implementation time, and loading one language file then is
cheap.

## 9. Distribution

Installation from git requires **two** manifests, not one. A plugin manifest alone is not
installable: `/plugin marketplace add` reads a `marketplace.json` at the repository root, and
that file is what lists the plugins and points at their directories. A bare skill directory is
not distributable at all — it requires manual symlinking, which does not survive handing the
repo to a team.

```
/plugin marketplace add crystailx/functional-first
/plugin install functional-first@functional-first
```

**Every published layer carries the same name.** There is exactly one name to remember:

| Layer | Name | Effect |
|---|---|---|
| local repo directory | `functimize` | none — a directory name on one machine |
| GitHub repo | `functional-first` | what a user adds as a marketplace |
| marketplace | `functional-first` | the `@functional-first` in an install command |
| plugin | `functional-first` | namespace prefix at invocation |
| skill | `functional-first` | triggering depends on the description, not the name |

Both the install command and the invocation therefore repeat the name, and that is accepted
deliberately. The alternative — a distinct brand namespace above a descriptive skill name —
buys a tidier-looking invocation at the price of two names a user must learn and keep straight,
and the repetition costs nothing but a glance. `functimize` survives only as the local
directory, visible to nobody but its owner.

### 9.1 Triggering

This guideline is not a topic anyone raises. Nobody asks for a functional order service; they
ask for an order service. Triggering therefore cannot depend on the subject coming up, which
rules out any mechanism keyed to the user mentioning functional design. The mechanisms below
are layered by how reliably they fire.

**Layer 1 — the always-on block carries Axis A itself, not a pointer to it.** This is the
only layer that fires unconditionally, because it is in context before anything is matched
against anything else. The consequence is the one that matters: in a session where the skill
never loads, the six principles are still present and the design still comes out functional.
The skill supplies depth — per-language idiom, stance resolution, review signals — while the
block supplies the guideline.

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

**Layer 2 — chain off the process skills.** The block names brainstorming and writing-plans
explicitly. Those fire reliably on exactly the work this guideline should shape, and borrowing
a trigger that already works is cheaper and more robust than engineering a new one.

**Layer 3 — a situational description.** The skill description names what the user is doing,
never what the guideline believes: designing a service, module, or API; writing an
implementation plan; choosing a library or framework; implementing backend logic; reviewing
code. A description phrased around "functional architecture" would match only users who
already said the word — precisely the population that least needs it.

**Layer 4 — a hook, for teams wanting hard enforcement.** A `PreToolUse` hook on writes to
source files can inject the principles at the moment code is produced. It is the strongest
mechanism available and the most intrusive, and it is the only one that reaches edits too
small to read as design work. Offered, not required; out of scope for the first release.

Stated plainly rather than implied: **nothing makes a model do something every single time
except putting it in context.** Layer 1 is a guarantee; layers 2 through 4 raise probability.
Installing the plugin is what makes Layer 1 unconditional.

Layer 1 ships as a `SessionStart` hook in the plugin, matching `startup|clear|compact` and
running synchronously, so the block is in context before the model acts. `compact` matters
most: without it the principles vanish exactly when context has been compressed. The hook
script does not restate the principles; it reads `snippets/claude-md.md`, the single source of
truth, and emits it. If that file is unreadable it emits nothing rather than a partial block.
Pasting the block into a `CLAUDE.md` remains available as an optional path for adopters who
want to edit the wording locally.

**Correction.** This section originally designed Layer 1 as an installable snippet that the
adopter pastes into `~/.claude/CLAUDE.md` or a project `CLAUDE.md`. That was a real flaw:
`claude plugin install` touches no `CLAUDE.md`, so the one layer declared unconditional
depended on a human remembering a manual step, and an adopter who skipped it silently lost the
guarantee without knowing. It was replaced by the `SessionStart` hook above, so installing the
plugin delivers Layer 1 with no further action.

## 10. Out of scope

- Kotlin, TypeScript, and Go references — deferred by the order in 6.5, not by exclusion.
- Automated enforcement (lint rules, CI checks) built from the failure signals. The signals are
  designed to be mechanical so this stays possible later; it is not built now.
- The layer-4 `PreToolUse` hook described in §9.1. It is the only mechanism reaching edits too
  small to read as design work, and is deferred rather than rejected.
- Migration guidance for converting an existing OO codebase. Brownfield scope is deliberately
  limited to new files and functions actually being modified.
