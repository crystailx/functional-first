# Functional-First

A cross-language guideline that biases architecture, planning, implementation, and library
selection toward functional design. Six structural principles are held at full rigor in every
language; the only thing that varies per project is which effect machinery, if any, carries
them out.

## The contract

From `plugins/functional-first/skills/functional-first/SKILL.md`:

> Adopting this skill means accepting Axis A. Only Axis B is negotiable, and only among options
> that already satisfy Axis A. A team that does not want functional design should remove the
> skill rather than configure it away.

| Axis | What it covers |
|---|---|
| A — principle rigor | Applied at full rigor in every language. Never discounted for language capability: where a language lacks a construct, use the Substitution given in its reference. Rigor does not change, only form. |
| B — abstraction weight | Which machinery carries the effects. Resolved per project by Step 2, never assumed. |

## The six principles

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

That is the whole of Axis A. It is also enough to decide whether to adopt this guideline —
nothing below requires installing anything to evaluate it.

## Installing the plugin

`functional-first` ships as a Claude Code plugin:

```
/plugin marketplace add crystailx/functional-first
/plugin install functional-first@functional-first
```

The marketplace, the plugin, and the skill inside it are all published under the same name.
`SKILL.md` describes when the installed skill loads: "Use when designing a service, module, or
API; when writing an implementation plan; when choosing a library or framework; when
implementing backend logic; or when reviewing code — applies functional structure in any
language, resolves which effect machinery a project uses, and supplies per-language idiom."

## Layer 1 arrives with the install

This guideline is not a topic anyone raises on purpose — nobody asks for a "functional" order
service, they ask for an order service, so nothing that depends on the user raising the subject
can fire reliably. The plugin therefore ships a `SessionStart` hook that puts the six
principles into context at `startup`, `clear`, and `compact`, so they hold
even when the skill never loads. Installing the plugin is the whole story; there is nothing to paste. The skill
supplies depth on demand; the hook supplies the guideline.

The hook reads `plugins/functional-first/skills/functional-first/snippets/claude-md.md` and
emits it unchanged, so that file is the single source of the wording. If it cannot be read, the
hook emits nothing.

Optionally, to edit the wording locally, paste the block into `~/.claude/CLAUDE.md` (all of your
projects) or a project `CLAUDE.md` (everyone on the repo). Do this only if you want your own
wording; the hook already supplies it.

The block, verbatim, from
`plugins/functional-first/skills/functional-first/snippets/claude-md.md`:

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

## Recording a project's Stance

`SKILL.md`'s Step 2 resolves Axis B in this order:

```
brownfield with a build-file signal   → follow what is there. Never ask.
project records a Stance in CLAUDE.md → use it. Never re-ask.
otherwise                             → refresh, ask once, record
```

Whether asking is even possible depends on how many Axis-A-compliant options a language
currently has:

| Language | Axis-A-compliant machinery | Last verified |
|---|---|---|
| Scala 3 | ZIO 2, cats-effect 3, direct style | 2026-09 |
| Scala 2 | ZIO 2, cats-effect 3, direct style | 2026-09 |
| Java | native | 2026-09 |
| Python | native | 2026-09 |

Java and Python have exactly one option today, so Step 2 proceeds without asking. A greenfield
Scala project has three, so it is asked once, at design time, and the answer is recorded so it
is never asked again:

```markdown
## functional-first stance
- Axis B: cats-effect 3
- Decided: 2026-09-23 — team already ships cats/http4s services
```

`SKILL.md` explains why the second line matters: "The reason line decides whether the next
person revisiting this is deciding or guessing."

## Language references

Each reference below carries capability and idiom for one language — what the language and its
ecosystem can do, and what code written in it looks like — never a preference among options;
the preference is the Stance above, decided once per project.

| Language | Reference |
|---|---|
| Scala 3 | `references/scala-3.md` |
| Scala 2 | `references/scala-2.md` |
| Java | `references/java.md` |
| Python | `references/python.md` |

All four live under `plugins/functional-first/skills/functional-first/references/`, alongside
`review-signals.md`, which review mode loads instead of a per-language file:

> Review runs on observable markers, not on judgement questions. "Is this function pure enough"
> cannot be checked; "a `Repository` type appears in a decision function's parameters" can be
> grepped.

More languages are added as their references are written.
