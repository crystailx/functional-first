# Functimize

A cross-language guideline that biases architecture, planning, and implementation toward
functional design. This glossary pins the vocabulary the guideline is built on — fuzzy terms
here cause the guideline to be applied at the wrong strength in the wrong places.

## Language

**Axis A — Principle Rigor**:
How strictly the language-invariant structural principles are applied: pure decision logic,
immutable data, errors as values, illegal states unrepresentable, explicit dependencies.
Requires no library, only some way to express a sum type.
_Avoid_: aggressiveness, FP-ness, how functional

**Axis B — Abstraction Weight**:
How heavy an abstraction a project adopts on top of those principles: effect systems,
higher-kinded types, typeclasses, monad transformers. Carries a real learning curve and
ecosystem lock-in.
_Avoid_: aggressiveness, library choice

**Deviation**:
Applying a principle below full rigor on Axis A. Requires justification and must be stated
out loud when it happens.
_Avoid_: exception, compromise

**Substitution**:
Expressing a principle differently because the language lacks a construct — Go modelling a
sum type as an interface plus type switch. Rigor is unchanged; only the form differs.
Never a Deviation.
_Avoid_: workaround, limitation

**Effective Language Level**:
The language version a codebase is actually *written* in, read from the build target and from
evidence in the source. Distinct from the runtime version it happens to execute on, and it
says nothing about a project's age — new projects adopt old language versions for real
reasons, and old projects run on new runtimes.
_Avoid_: JDK version, language version

**Contagious Change**:
A change that forces other people to learn something or to modify code they own — adopting an
effect system, reshaping a shared abstraction. Only contagious changes qualify for the
existing-codebase-consistency Deviation; adding a record or a sealed interface does not.
_Avoid_: breaking change, invasive change

**Stance**:
A project's resolved position on Axis B — a level, plus a specific library where the level
admits more than one. Resolved once per project and recorded, never re-derived.
_Avoid_: setting, config, preference

**Taste Fork**:
A decision the guideline cannot derive from facts and must put to the user — which machinery
carries the effects. Every option offered satisfies Axis A; opting out of functional design is
never on the menu. The guideline asks, never guesses, and holds no house favourite.
_Avoid_: opinion, default, recommendation

**Failure Signal**:
A mechanically observable marker that a principle has been violated — an import, a type in a
signature, a call inside a function body. Review is conducted with signals, never with
subjective questions.
_Avoid_: smell, checklist item, review question
