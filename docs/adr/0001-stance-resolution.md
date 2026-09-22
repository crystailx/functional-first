# Axis B is resolved by asking, not by a built-in default

**Status:** accepted

Which machinery carries a project's effects — ZIO, cats-effect, direct style — is a team
decision, not something derivable from the language. So the guideline holds, per language, the
*set* of Axis-A-compliant options and nothing more: when the set has one member it proceeds,
and when it has several it asks the user once and records the answer in the project's
`CLAUDE.md`. Brownfield projects skip the question entirely — an existing codebase signal
always wins, because switching effect systems is a Contagious Change.

## Considered options

- **Hardcode a stance per language** (`Scala → ZIO`, `Java → native`). Predictable and cheap to
  follow, but it goes stale as ecosystems shift, and in a project that has already chosen
  differently it instructs the model to work against the grain.
- **Run a decision procedure every time.** Correct in principle, but the model re-derives the
  answer on each encounter and can misjudge it; the result is unpredictable across sessions.
- **Constants as default, with a mechanical override.** This was the working design for most of
  the discussion and was abandoned once the guideline was scoped as team-neutral: a default
  *is* a house favourite, and a guideline meant for teams with opposite tastes cannot hold one.

## Consequences

- The guideline names no preferred library anywhere, so teams on opposite sides of the
  ZIO/cats divide can both adopt it unchanged.
- Asking is rare by construction rather than by a tunable threshold. Java and Python hold
  single-member sets and never produce a question.
- The menu offered to the user never contains a non-functional option. Axis B is negotiable;
  Axis A is not. A team that wants out of Axis A removes the skill.
- A recorded Stance must carry its reason, or the next person revisiting it is guessing rather
  than deciding.
- The shipped option sets are a floor rather than a closed list. Ecosystem facts move faster
  than the guideline is edited, so each set carries a `last-verified` date and is refreshed by
  a live search immediately before the question is asked — affordable only because asking is
  rare by construction. A refresh may add an option or mark one as declining; it may never
  produce an empty menu or admit an option that fails Axis A.
- Detection of an existing stance fails benignly on purpose: an unrecognised dependency falls
  through to asking rather than to `native`, so a stale recognition list costs one question and
  never a wrong answer.
