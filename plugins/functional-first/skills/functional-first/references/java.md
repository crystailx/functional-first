# Java

last-verified: 2026-09

This reference covers capability and idiom for Java's native capability, the sole Axis-B option
on this language line — there is no effect runtime layered on top of it here,
and no per-library section below for that reason. What the rest of this file organizes by
instead is effective language level: `record`, `sealed`, and switch pattern matching arrived
across several JDK feature releases rather than together, so the same worked example is written
out below once per tier, because which of those constructs a given project's build target
actually permits is the question this file exists to answer.

## Reading the Effective Language Level

A project's effective language level comes from its build file, never from the JVM running it:
`maven.compiler.release` in a Maven `pom.xml`, or `sourceCompatibility` (or a Gradle Java
toolchain's language version) in a Gradle build. That number is a ceiling — the highest
construct the compiler will accept — and it is the fact to read first.

It is not the whole picture. A project can compile at 21 and be written entirely in Java 8
style: no `record`, no `sealed`, nothing later than what Java 8 offered, simply because the
build target was raised for an unrelated reason — a dependency that needed a newer runtime, say
— and nobody has touched the code since. Whether `record` or `sealed` actually appear anywhere
in the source is a second, independent fact, and the two can disagree. The runtime the code
happens to execute on is evidence of neither: a project built at `--release 8` runs fine on a
JDK 21 runtime, and that says nothing about what the source is permitted or written to use.

Read both — the build file for the ceiling, the source for what has actually been adopted under
it — before reaching for any construct below.

## Capability by tier

| Effective level | `record` | `sealed` | switch patterns + exhaustiveness |
|---|---|---|---|
| 8 / 11 | no | no | no — `switch` statements only; no pattern labels, no expression form, no exhaustiveness check of any kind |
| 16 / 17 | yes (since: 16) | yes (since: 17) | no — before JEP 441, `switch` accepts only a primitive, `String`, or `enum` selector; `sealed interface OrderStatus` below is none of those, so there is no `switch` form to reach for at all, checked or not |
| 21+ | yes | yes | yes (since: 21) — a `sealed`-selector `switch` with no `default` is exhaustive by compile error, not by warning |

Pattern matching for `switch` (JEP 441, since: 21) does two things worth separating. First, it
generalizes what a `switch` selector is allowed to be: before 21, only
`byte`/`short`/`char`/`int` (and their wrapper types), `String`, or an `enum` are legal
selectors, so a `sealed interface` cannot be switched on at all until this tier — this is why
the 16/17 tier below matches by hand. Second, once the selector can be an arbitrary reference
type, the compiler checks whether a `switch` over a `sealed` one covers every permitted
subtype, and it does so as a compile error when no `default` is present. Verified directly: a
`switch` expression over the three-case `OrderStatus` used below, with one case omitted and no
`default`, fails with `javac`'s own message, "the switch expression does not cover all possible
input values" — not a warning, and there is no flag that changes that, unlike Scala's
warning-by-default `match`.

A `default` branch satisfies that check rather than being caught by it: the switch becomes
exhaustive by definition, because `default` matches whatever is left over. That is what makes it
a trap specifically on a `sealed` selector at this tier — verified directly alongside the above,
the identical switch with the same case omitted but a `default` branch added compiles cleanly,
with no error and no warning. A fourth `OrderStatus` implementation added later, with its case
forgotten, produces nothing at compile time; the `default` arm absorbs it silently.
`review-signals.md`'s Signal 4 names this: a `default` branch over a `sealed`
selector at 21+ is a violation, for exactly this reason. The same branch is correct, even
necessary, one tier down — see Tier 16/17 below — because there is no switch-based check at that
tier for a `default` to discard, and correct as ordinary code at any tier over a selector that
isn't `sealed` in the first place.

Even a switch that is exhaustive by construction — one case per permitted subtype, no `default`
— is a compile-time approximation rather than an absolute proof. Because Java permits separate
compilation, `javac` cannot always be certain no other module contributes a further implementor
at run time, so an exhaustive `sealed` switch has a hidden `default` synthesized underneath it
that throws `MatchException` if that ever happens. This does not arise from ordinary
single-module code — it matters to an author shipping a sealed API for others to compile against
— but it is the honest boundary of what the compile-time guarantee covers.

The worked example below is the same small order model as the Scala references use: three
states, one decision. It is written out once per tier, because what differs tier to tier is how
much of the ADT the language can express directly, not what the ADT means.

## Tier 21+ idiom

- `record` (since: 16, carried forward) builds an immutable data carrier in one declaration —
  `OrderId`, `Order`, and `OrderCancelled` below are all records.
- `sealed interface` plus `permits` (since: 17, carried forward) closes a hierarchy to a named,
  fixed set of implementors — `OrderStatus`, `CancellationError`, and `CancellationResult` below
  are all sealed.
- Pattern matching for `switch` (since: 21) lets the selector be a `sealed` type, matched by
  which permitted subtype an instance is rather than by an `equals`-style constant.
- Record patterns (since: 21) deconstruct a record's components directly in a `case` label —
  `case Order(OrderId id, OrderStatus.Placed())` binds `id` without a call to `order.id()`, and
  nests a further pattern, `OrderStatus.Placed()`, against the `status` component in the same
  step. An empty `()` matches a zero-component record like `Placed` by type, binding nothing,
  since there is nothing in it to bind.

```java
sealed interface OrderStatus permits OrderStatus.Placed, OrderStatus.Paid, OrderStatus.Cancelled {
    record Placed() implements OrderStatus {}
    record Paid() implements OrderStatus {}
    record Cancelled() implements OrderStatus {}
}

record OrderId(String value) {}
record Order(OrderId id, OrderStatus status) {}

sealed interface CancellationError permits CancellationError.AlreadyCancelled {
    record AlreadyCancelled() implements CancellationError {}
}

record OrderCancelled(OrderId id) {}

sealed interface CancellationResult permits CancellationResult.Success, CancellationResult.Failure {
    record Success(OrderCancelled event) implements CancellationResult {}
    record Failure(CancellationError error) implements CancellationResult {}
}

final class Cancellation {
    // The core: pure, total, no import of anything that talks to the outside world.
    static CancellationResult cancel(Order order) {
        return switch (order) {
            case Order(OrderId id, OrderStatus.Placed())    -> new CancellationResult.Success(new OrderCancelled(id));
            case Order(OrderId id, OrderStatus.Paid())      -> new CancellationResult.Success(new OrderCancelled(id));
            case Order(OrderId id, OrderStatus.Cancelled()) -> new CancellationResult.Failure(new CancellationError.AlreadyCancelled());
        };
    }
}
```

No `default` appears above: all three permitted subtypes of `OrderStatus` have their own case,
which is what lets `javac` check the switch at all. Adding a fourth `OrderStatus` implementation
without adding its case here is a compile error in this form. It would not be, if this read
instead:

```java
// Trips Signal 4 — compiles whether or not every OrderStatus subtype has its
// own case, which is exactly the problem: a future fourth subtype falls
// through here silently instead of failing the build.
static CancellationResult cancelUnchecked(Order order) {
    return switch (order.status()) {
        case OrderStatus.Placed p -> new CancellationResult.Success(new OrderCancelled(order.id()));
        default -> new CancellationResult.Failure(new CancellationError.AlreadyCancelled());
    };
}
```

Both forms were checked directly against `javac 21`: the first fails to compile with `Paid`'s
case deleted, exactly as claimed above; the second — `default` present, a case missing —
compiles without complaint.

## Tier 16/17 idiom

- `record` (since: 16) — unchanged from the 21+ tier above; the type declarations below are
  identical to those above for exactly this reason.
- `sealed interface` plus `permits` (since: 17) — also unchanged, and already a real
  compile-time guarantee at this tier even without a checked `switch`: any class outside
  `OrderStatus`'s `permits` clause that tries to `implements` it fails to compile. What `sealed`
  does not yet buy here is an exhaustive `switch` — that needs JEP 441, below.
- What's missing is JEP 441's generalized `switch` selector (since: 21) — see Capability by
  tier above: pre-21 `switch` accepts only a primitive, `String`, or `enum` selector, and
  `sealed interface OrderStatus` is none of those, so there is no `switch` form to reach for
  here at all. Matching is an `instanceof` chain instead, one branch per permitted subtype,
  closed by an `else` that throws — a hand-written stand-in for `default`, since plain
  `if`/`else` has none. Pattern matching for `instanceof` (since: 16) would bind a variable per
  branch — `status instanceof OrderStatus.Placed placed` — if any branch needed a field off the
  matched value; none does here, since every `OrderStatus` case is empty, so the classic,
  binding-free form of `instanceof` is used below instead.

The type declarations are unchanged from Tier 21+ above. Only `cancel` differs:

```java
final class Cancellation {
    // The core: pure, total. The instanceof chain is closed by an else that
    // throws — there is no compiler check that every OrderStatus subtype is
    // handled, only that the chain is well-formed. Exhaustiveness here is
    // enforced by the author re-reading OrderStatus's permits clause, not by
    // javac.
    static CancellationResult cancel(Order order) {
        OrderStatus status = order.status();
        if (status instanceof OrderStatus.Placed) {
            return new CancellationResult.Success(new OrderCancelled(order.id()));
        } else if (status instanceof OrderStatus.Paid) {
            return new CancellationResult.Success(new OrderCancelled(order.id()));
        } else if (status instanceof OrderStatus.Cancelled) {
            return new CancellationResult.Failure(new CancellationError.AlreadyCancelled());
        } else {
            throw new AssertionError("unreachable: unknown OrderStatus " + status);
        }
    }
}
```

Checked directly against `javac 17`: this compiles and runs correctly, and the same source
rejected with "sealed classes are not supported in -source 16" when compiled at `--release 16`
— `sealed` genuinely needs 17, not 16, confirming the two `since:` markers above are not
interchangeable. `record` alone, without `sealed` anywhere in the file, compiles fine at
`--release 16`.

The final `else` above is this tier's version of Signal 4's `default` row, and the verdict
inverts on purpose: at 16/17 it is correct, even the prescribed idiom, because nothing here
claims to be compiler-checked in the first place. The risk it carries is not a defeated
compiler guarantee — there is none to defeat — but a silent one: if a fourth `OrderStatus`
subtype is added and this chain is not updated, nothing fails until the `AssertionError` throws
at run time, on whatever request first exercises the new case.

## Tier 8/11 Substitution

No `record` (since: 16) and no `sealed` (since: 17) — both unavailable. Immutability is
hand-written: every field `final`, assigned once from the constructor, no setter, and no method
that mutates a field in place. (An annotation processor is the other way to get this without
writing it by hand; this reference states the capability, not a recommendation between the two.)

Without `sealed`, nothing closes `OrderStatus` to a fixed set of implementors, and without
`record`-plus-pattern-matching there is no deconstruction. There is also no exhaustiveness
signal available from a plain `enum` and a `switch` statement either: `switch` **expressions**
don't exist before Java 14, so every `switch` at this tier is a statement, and a statement
missing an `enum` constant is not flagged by `javac` at all — not an error, not a warning. The
**visitor pattern** is the one construction at this tier that gives a compile-time check when a
case is missing: not a check on a `switch` — there is no pattern-matching `switch` here to check
— but a check on the interface implementation itself. Each state is a class implementing an
`accept` method; a `Visitor<R>` interface declares one abstract method per state. Adding a
state means adding both a class and a matching abstract method to `Visitor<R>`, and that second
edit is what breaks every existing implementation of `Visitor<R>` — including the one inside
`cancel` below — until it is updated to handle the new case. This is a real, compiler-enforced
guarantee; it costs more ceremony than `sealed` plus `switch` does at the higher tiers, not less
correctness. A reader whose build targets 8 or 11 is not left with "this cannot be done
properly."

```java
// No record, no sealed at this tier. The interface plus one implementing
// class per state is hand-written; immutability comes from declaring every
// field final and giving each class no setters.
interface OrderStatus {
    <R> R accept(Visitor<R> visitor);

    interface Visitor<R> {
        R placed();
        R paid();
        R cancelled();
    }
}

final class Placed implements OrderStatus {
    public <R> R accept(Visitor<R> visitor) {
        return visitor.placed();
    }
}

final class Paid implements OrderStatus {
    public <R> R accept(Visitor<R> visitor) {
        return visitor.paid();
    }
}

final class Cancelled implements OrderStatus {
    public <R> R accept(Visitor<R> visitor) {
        return visitor.cancelled();
    }
}

final class OrderId {
    private final String value;

    OrderId(String value) {
        this.value = value;
    }

    String value() {
        return value;
    }
}

final class Order {
    private final OrderId id;
    private final OrderStatus status;

    Order(OrderId id, OrderStatus status) {
        this.id = id;
        this.status = status;
    }

    OrderId id() {
        return id;
    }

    OrderStatus status() {
        return status;
    }
}

// Left an ordinary, open interface: nothing in cancel dispatches on
// CancellationError, so there is no exhaustiveness to enforce here. The
// Visitor treatment below is applied where it is actually exercised —
// OrderStatus and CancellationResult — not decoratively everywhere a closed
// set could in principle appear.
interface CancellationError {
}

final class AlreadyCancelled implements CancellationError {
}

final class OrderCancelled {
    private final OrderId id;

    OrderCancelled(OrderId id) {
        this.id = id;
    }

    OrderId id() {
        return id;
    }
}

interface CancellationResult {
    <R> R accept(Visitor<R> visitor);

    interface Visitor<R> {
        R success(OrderCancelled event);
        R failure(CancellationError error);
    }
}

final class Success implements CancellationResult {
    private final OrderCancelled event;

    Success(OrderCancelled event) {
        this.event = event;
    }

    public <R> R accept(Visitor<R> visitor) {
        return visitor.success(event);
    }
}

final class Failure implements CancellationResult {
    private final CancellationError error;

    Failure(CancellationError error) {
        this.error = error;
    }

    public <R> R accept(Visitor<R> visitor) {
        return visitor.failure(error);
    }
}

final class Cancellation {
    // The core: pure, total, no import of anything that talks to the outside world.
    static CancellationResult cancel(Order order) {
        return order.status().accept(new OrderStatus.Visitor<CancellationResult>() {
            public CancellationResult placed() {
                return new Success(new OrderCancelled(order.id()));
            }

            public CancellationResult paid() {
                return new Success(new OrderCancelled(order.id()));
            }

            public CancellationResult cancelled() {
                return new Failure(new AlreadyCancelled());
            }
        });
    }
}
```

Checked directly against `javac 8` (`--release 8`): the whole example above compiles and runs
correctly. Nothing in it needs anything newer than generics (Java 5) and anonymous classes
(Java 1.1), which is why no line above carries a `since:` marker — every construct here has
been available since long before this tier's floor.

## Errors as values across all tiers

`cancel` never throws for the one failure this domain expects — an already-cancelled order — at
any tier above. What changes tier to tier is only how `CancellationResult` is built: a `sealed`
interface plus `record` cases at 21+ and 16/17, unpacked the same way `OrderStatus` is at each
of those tiers; a `Visitor`-based interface at 8/11, unpacked by `accept` the same way
`OrderStatus` is at that tier. In every case, `CancellationError.AlreadyCancelled` (or
`AlreadyCancelled` at 8/11) is data returned to the caller inside `CancellationResult`'s failure
case, not a `throw` — principle 5 holds at every tier because a result type is available at
every tier, built from whatever that tier's capability actually supports.

A checked exception would express the same "this can fail" fact — Java's checked-exception
mechanism is in fact the language's own native form of forcing a caller to acknowledge a
failure, the closest thing it has to principle 5 outside of a result type. What it does not give
is a value: a caught, hypothetical checked `AlreadyCancelledException` is control flow, unwound
and gone once handled, not something that can be `.map`-transformed, stored, or passed on to
another function the way `CancellationResult` above is. That is the distinction the result types
in every tier section above are for.

## Dependencies

A `Clock` passed into a constructor is a dependency like any other — swappable for a fixed
instant in a test, without that test waiting on the real clock. `Instant.now()` called from
inside a method body reaches past the constructor for the system clock directly; nothing in the
method's signature admits that it did, and no caller can substitute a different clock without
changing the system's actual time source.

```java
// Good: the clock is a dependency, passed in and swappable in tests.
final class CancellationAudit {
    private final Clock clock;

    CancellationAudit(Clock clock) {
        this.clock = clock;
    }

    Instant recordedAt() {
        return clock.instant();
    }
}

// Bad — Signal 6: Instant.now() reaches for the system clock from inside the
// method body instead of the constructor, so no caller can supply a
// different "now" without changing the system clock itself.
final class CancellationAuditUnchecked {
    Instant recordedAt() {
        return Instant.now();
    }
}
```

This holds at every tier in this file: `Clock` and `Instant` are `java.time`, available since
Java 8, and constructor injection needs nothing newer than a constructor. The same applies to
whatever loads an `Order` and saves an `OrderCancelled` around a call to `cancel` — a
repository-shaped dependency passed into whatever shell calls `cancel`, never reached for as a
static method or a singleton from inside it.
