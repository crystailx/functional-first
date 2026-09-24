# Python

last-verified: 2026-09

This reference covers capability and idiom for Python's native capability, the sole
Axis-B option on this language line — there is no ZIO- or cats-effect-style shell layered
on top of it here, and no per-library section below, for the same reason as Java: there
is no such library to describe. What has to be read before any of the capability below is
trusted is a single fact stated first rather than last, because it governs everything
that follows: none of it is a guarantee until a particular external tool is actually
turned on, and a project remains free, at every point, not to turn it on.

## Making principle 4 enforced

A strict type checker — mypy or pyright, run in strict mode, together with
`typing.assert_never` — is a precondition for principle 4 in Python, not an enhancement
to it. Without that combination, everything below this section is still legal, idiomatic
Python: the `Literal`/`match`/`assert_never` shape still tells a reader which states are
legal and reads as a closed set. But nothing checks it. Where a project has no strict
checker configured, principle 4 carries **documentation value only** there, and this file
means that literally — say so plainly in that project rather than presenting the shape
as if it were protected. A rigorous-looking model with zero enforcement is worse than no
model, because it misleads a reader into believing a guarantee exists where none does.

`scala-2.md` names this file's shape before this file exists: "a guarantee nobody
enforces is not a guarantee." Python's version of that sentence is the stronger of the
two, and the difference is structural, not rhetorical. Both of the Scala references
found the same fact — a `match` missing a case is a compiler warning, not an error, with
no flag set — but the check itself still *runs*, unconditionally, on every build, in
every project, whether or not anyone reads the warning or sets a flag to promote it.
Python has no equivalent floor. There is no partial, always-on, severity-only-configurable
check waiting underneath — the entire mechanism, from the first line of narrowing to the
final `assert_never`, exists only for a project that opted a specific external tool in.

Java 8 sits between the two, which is what makes it the closer comparison. Java 8 has no
`switch`-based exhaustiveness either, but it has the **visitor pattern** — see `java.md`'s
Tier 8/11 section — a construction native to the language itself: adding a case means
adding an abstract method to a `Visitor<R>` interface, and every existing implementor
then fails to *compile*, with no external tool, whether or not the incomplete implementor
is ever instantiated anywhere. Python's nearest analog, an `abc.ABC` with an
`@abstractmethod` per case, looks similar and is meaningfully weaker: verified directly —
an incomplete subclass of such an ABC, missing one abstract method, compiles nothing
(Python has no separate compile step to fail), imports cleanly, and defines cleanly; the
`TypeError: Can't instantiate abstract class ... with abstract method ...` fires only at
the moment something actually calls the constructor. A subclass stubbed out but not yet
wired anywhere produces no signal at all. Checked directly against both tools, too:
neither `mypy --strict` nor `pyright` in strict mode flags the same incomplete subclass
when the file never instantiates it — both report zero errors on a class definition that
is, in fact, broken. Python has no built-in construction that turns a missing case into
an error the way Java 8's visitor pattern does. The guarantee comes entirely from the
checker, and only at the points the checker actually looks.

**Current strict-mode invocation**, verified directly against each tool's own
documentation and by running both:

- mypy (current release 2.3.1): `mypy --strict` on the command line, or `strict = true`
  under `[tool.mypy]` in `pyproject.toml` (`strict = True` in `mypy.ini` is the
  equivalent outside `pyproject.toml`). `--strict` is a bundle, not one switch — currently
  `--disallow-any-generics`, `--disallow-subclassing-any`, `--disallow-untyped-calls`,
  `--disallow-untyped-defs`, `--disallow-incomplete-defs`, `--check-untyped-defs`,
  `--disallow-untyped-decorators`, `--warn-redundant-casts`, `--warn-unused-ignores`,
  `--warn-return-any`, `--no-implicit-reexport`, `--strict-equality`, `--extra-checks` —
  and mypy's own docs note the bundle's membership may change release to release, so a
  project depending on the exact set should pin mypy's version, not just pass `--strict`.
- pyright (current release 1.1.414): `typeCheckingMode` set to `"strict"` — in
  `pyrightconfig.json`, or under `[tool.pyright]` in `pyproject.toml` if no
  `pyrightconfig.json` file is present (a `pyrightconfig.json` file always wins over
  `pyproject.toml` when both exist). Verified against pyright's own configuration
  reference: its default `typeCheckingMode`, absent either file, is `"standard"` — one
  level down from `"strict"` — so a project that merely has pyright installed, with
  nothing committed to select a mode, is not running it in strict mode by default. An
  editor showing pyright's inline diagnostics is exactly this case unless the project's
  config says otherwise.

**What strict mode actually contributes** is narrower than it first appears, and worth
stating precisely rather than left to guesswork, because the honest boundary matters as
much here as it does in `java.md`'s discussion of the hidden `default` a sealed switch
still carries. Verified directly: the `assert_never` mechanism itself is *not*
strict-gated. A bare `mypy` invocation with no configuration at all, and a bare `pyright`
with no config file present, both still reject a `match` with a deleted branch, with the
identical message strict mode produces (see the worked example below) — argument-type
checking against `Never` is ordinary type checking in both tools, not a strict-only rule.
What strict mode buys instead is **coverage**. Verified directly: an entirely unannotated
function that builds an `Order` with a `status` value never actually checked against
`OrderStatus` — `def build_order(raw): return Order(id=OrderId(raw["id"]),
status=raw["status"])`, called with a `status` string not among the three legal ones —
passes both `mypy` and `pyright` with **zero** complaint under each tool's own default
settings, because neither tool looks inside an unannotated function body by default.
`mypy --strict` rejects the same file outright, with `error: Function is missing a type
annotation [no-untyped-def]` — the bundled `--disallow-untyped-defs` and
`--check-untyped-defs` forcing that function into view for the first time. Pyright's
strict mode rejects it too, with `reportMissingParameterType` and
`reportUnknownParameterType` on the same line. `assert_never` protects the one function
it sits in, strict or not; strict mode is what stops the rest of the codebase from being
a blind spot the checker never enters, through which an unvalidated value reaches that
function in the first place.

`typing.assert_never` itself is `since: 3.11`. `typing_extensions.assert_never` backports
the identical function — confirmed from `typing_extensions`'s own changelog — and has
done so since `typing_extensions` 4.1.0 (February 2022), which predates Python 3.11's own
release; a project targeting 3.10 loses nothing by reaching for the backport instead of
waiting for the stdlib version.

## Native capability

- `@dataclass(frozen=True)` builds an immutable record in one declaration: generated
  `__init__`, `__eq__`, and `__repr__`, and a `dataclasses.FrozenInstanceError` raised on
  any attempt to assign to a field after construction.
- A tagged union is a `Literal` discriminant on each variant plus a `Union` alias (or
  `X | Y`, `since: 3.10`) joining the variants — the idiom this reference uses throughout,
  including for `OrderStatus` below. It is a type-checker construction, not a language
  one: see Substitutions for what that costs.
- `match`/`case` structural pattern matching (`since: 3.10`) dispatches on a value's shape
  — a literal, a class pattern, a positional or keyword capture of a `dataclass`'s fields
  (dataclasses generate `__match_args__` from field order automatically) — and is what a
  strict checker narrows through, branch by branch, to determine what is left at a
  wildcard case.
- `assert_never` (`since: 3.11`, `typing_extensions` fallback noted above) placed in a
  `match`'s final `case` turns "every branch above is exhaustive" from an assumption into
  something a strict checker actively verifies, by requiring the type left over at that
  point to be `Never` — nothing. It also has a real runtime behavior, not just a
  checker-time one: read from CPython's own `typing` source, the call itself is
  `raise AssertionError(f"Expected code to be unreachable, but got: {value}")` — so even
  in a project with no strict checker at all, a case actually missed still fails loudly
  the moment that exact branch is exercised, the same safety net `java.md`'s Tier 16/17
  `else { throw }` is, and the same limitation: it catches nothing until that input
  arrives.
- `typing.NewType` wraps an existing type under a new, checker-distinct name — the
  nearest Python equivalent to Scala's value class or `opaque type`. Read from its own
  docstring in CPython's source: "NewType creates simple unique types with almost zero
  runtime overhead... At runtime, `NewType(name, tp)` returns a dummy callable that
  simply returns its argument." A raw `str` and `OrderId` stop being interchangeable to
  the checker; at runtime they are, and always were, the same object.

The worked example below carries the same small order model the other three references
use — three states, one decision — expressed with the constructs named above.

## A hand-written `Result`

Roughly twenty lines, shown in full rather than imported, because at this size it reads
more like ordinary Python than a dependency would:

```python
from dataclasses import dataclass
from typing import Generic, TypeVar, Union

T = TypeVar("T")  # the success type
E = TypeVar("E")  # the failure type


@dataclass(frozen=True)
class Ok(Generic[T]):
    value: T


@dataclass(frozen=True)
class Err(Generic[E]):
    error: E


# Two free type variables -- Result[OrderCancelled, CancellationError] below
# substitutes T and E independently.
Result = Union[Ok[T], Err[E]]
```

Nothing here is specific to this domain. `Ok` and `Err` take whatever `T` and `E` a
caller's signature supplies, the same way a hand-rolled `Either` would in a language with
no built-in one.

## The worked example

```python
from dataclasses import dataclass
from typing import Literal, NewType, Protocol, assert_never

OrderId = NewType("OrderId", str)

OrderStatus = Literal["placed", "paid", "cancelled"]


@dataclass(frozen=True)
class Order:
    id: OrderId
    status: OrderStatus


@dataclass(frozen=True)
class CancellationError:
    """The one failure this domain expects: the order is already cancelled."""


@dataclass(frozen=True)
class OrderCancelled:
    id: OrderId


# The core: pure, total, no import of anything that talks to the outside world.
def cancel(order: Order) -> Result[OrderCancelled, CancellationError]:
    match order.status:
        case "placed" | "paid":
            return Ok(OrderCancelled(order.id))
        case "cancelled":
            return Err(CancellationError())
        case _ as unreachable:
            assert_never(unreachable)
```

`OrderStatus` is a plain `Literal` union rather than three fieldless wrapper classes: none
of the three states carries data beyond its own identity, the same shape as Scala's
`case object` or Java's zero-component `record Placed()`, and a bare `Literal` says that
more directly than three empty classes would. `CancellationError` stays a single, plain
`dataclass` rather than a tagged union of its own — `java.md` makes the same call for the
same reason: nothing in `cancel` dispatches on it, so there is nothing here for
exhaustiveness to check.

`cancel` returns a `Result` — a plain value describing what happened — instead of
performing a write itself; the shell below is what performs it. That is principle 2 with
no effect type in sight: the description is just data.

```python
class OrderRepository(Protocol):
    def load(self, order_id: OrderId) -> Order: ...
    def save(self, event: OrderCancelled) -> None: ...


def cancel_order(
    order_id: OrderId, repo: OrderRepository
) -> Result[OrderCancelled, CancellationError]:
    order = repo.load(order_id)
    outcome = cancel(order)
    match outcome:
        case Ok(event):
            repo.save(event)
        case Err():
            pass
    return outcome
```

`cancel_order` is the shell: it loads, hands the decision to `cancel`, and performs the
write — the only place in this example that imports anything I/O-shaped. `Protocol`
(structural typing) is what lets a test supply a fake `OrderRepository` without
inheriting from anything real.

Verified directly, in an isolated environment with no ambient configuration: the complete
example above — `Result`, the worked example, and the dependencies example below — passes
both `mypy --strict` and `pyright` in strict mode with zero errors. Deleting the
`case "cancelled":` branch from `cancel` above and re-running both tools produces, in
mypy, `error: Argument 1 to "assert_never" has incompatible type "Literal['cancelled']";
expected "Never"  [arg-type]`, and in pyright, `error: Argument of type
"Literal['cancelled']" cannot be assigned to parameter "arg" of type "Never" in function
"assert_never"`. Both reproduce with no strict flag set at all, confirming the claim
above: the mechanism itself is ordinary type checking, not a strict-only feature — strict
mode's own contribution is described above, under Making principle 4 enforced.

## Dependencies

A `Clock` passed in as a dependency is swappable for a fixed instant in a test, without
the test waiting on the real clock. `datetime.now()` called from inside a function body
reaches past the caller for the system clock directly; nothing in the function's
signature admits that it did, and no caller can substitute a different "now" without
changing the system's actual time source.

```python
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Protocol


class Clock(Protocol):
    def now(self) -> datetime: ...


@dataclass(frozen=True)
class CancellationAudit:
    clock: Clock

    def recorded_at(self) -> datetime:
        return self.clock.now()


# Bad -- Signal 6: datetime.now() reaches for the system clock from inside
# the method body instead of taking a Clock, so no caller can supply a
# different "now" without changing the system clock itself.
@dataclass(frozen=True)
class CancellationAuditUnchecked:
    def recorded_at(self) -> datetime:
        return datetime.now(timezone.utc)
```

`Clock` here is a `Protocol`, not an `abc.ABC` — a real clock and a test's fixed-instant
fake both satisfy it structurally, with no shared base class required. The same applies
to whatever loads an `Order` and saves an `OrderCancelled` around a call to `cancel`:
`OrderRepository` above is a dependency threaded through `cancel_order`'s parameters,
never reached for as a module-level singleton or constructed fresh from inside it.

## Substitutions

| What another language provides | Python's substitute |
|---|---|
| `sealed`/`permits` (Java), `sealed trait` (Scala) — the compiler refuses to load an unlisted implementor at all | `Literal` discriminant + a `Union`/`X \| Y` alias — a type-checker-level promise only; nothing stops a value the checker never examined from reaching a variable typed `OrderStatus` |
| Java 8's visitor pattern — a missing case fails the build itself, with no external tool, whether or not the incomplete class is ever instantiated | none, natively. `assert_never` under a strict checker is the nearest equivalent, and — verified above — it only fires at the points the checker actually looks |
| `opaque type` (Scala 3) / value class (Scala 2) — checker-distinct, zero runtime cost, enforced by the compiler | `typing.NewType` — checker-distinct, "almost zero runtime overhead" by its own docstring, enforced by nothing at runtime: `OrderId("not-a-real-id")` and a plain `str` are the same object the moment either is constructed |

Every row traces back to the fact Making principle 4 enforced opens with: Python's type
system is fully erased at runtime, and everything in this file is something a checker
verifies about the source, never something the language itself enforces. A `Literal`
discriminant is real, and matching on it is real structural pattern matching — but the
set it discriminates over is closed only because a `Union` alias says so and a checker is
reading that alias at the time it matters. State that limitation outright rather than
letting the `match`/`assert_never` shape imply otherwise on its own: the guarantee comes
from the checker, not the language.
