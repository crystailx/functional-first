# Scala 3

last-verified: 2026-09

This reference covers capability and idiom for Scala 3's three Axis-B options — ZIO 2,
cats-effect 3, and direct style — and for the native language capability underneath all three,
which is where the worked example below lives before any of the three shells are layered on top
of it. It states what each option can do and what code written in it looks like, and holds no
preference among them: the choice is recorded per project in `SKILL.md`.

Scala 3 ships as one evolving line rather than Scala 2's parallel 2.12/2.13 tracks, so a
`since:` marker here names the Scala 3 minor version a construct first shipped in, not a choice
between two lines a project might target. `enum`, `opaque type`, and `given`/`using` have all
been present since 3.0.0, the first stable Scala 3 release, and need no gate on that account.
Where a `since:` marker does real work below, it is on the ecosystem around the language, not
the language itself — see the direct-style library in the last section.

## Enforcing principle 4

A `match` over an `enum` or a `sealed` type that omits a case produces a compiler warning by
default, not a compile error — the same default Scala 2 ships, reported here under a dedicated
error code, E029, Pattern Match Exhaustivity. The check itself runs with no extra flag; only its
severity is a warning, exactly as on Scala 2.

Where Scala 3 differs from Scala 2 is the shape of the flag that closes the gap, not whether the
gap exists:

- `-Werror` turns every warning in the compilation into an error, exhaustivity included, and is
  Scala 3's current, canonical name for the flag. `-Xfatal-warnings` still compiles and still
  works, but is now a deprecated alias for `-Werror` — the reverse of Scala 2, where
  `-Xfatal-warnings` is the original flag and `-Werror` is 2.13's newer name for the same thing.
- `-Wconf:id=E029:error` scopes the same promotion to only this diagnostic, leaving the rest of
  the build's warnings as warnings. Scala 3 keeps the `-Wconf:<filter>:<action>` syntax from
  Scala 2.13's `-Wconf`, but its own `-Wconf` help text lists `deprecation`, `feature`, and
  `unchecked` as message categories and no match-exhaustivity category — this reference found
  none — so the scoped filter below keys on the diagnostic's own message id instead of a
  category name the way Scala 2.13's `cat=other-match-analysis` does.

```scala
// build.sbt — either line is sufficient on its own
scalacOptions += "-Werror"
scalacOptions += "-Wconf:id=E029:error"
```

Without one of these set, principle 4 is advisory only in that project — the same shape as
Scala 2: the `enum` or `sealed` type still documents the intended set of states and the compiler
still points at a missed case, but nothing stops a build from shipping with that case unhandled.

## Native capability

- `enum` builds an algebraic data type in one declaration (since: 3.0) — the exhaustivity
  check above is what turns it from documentation into a mechanical guarantee once a
  fatal-warnings flag is set. `sealed trait` plus `case class`/`case object` still compiles and
  is in fact what `enum` desugars to; `enum` is the direct, idiomatic spelling for a closed set
  of cases going forward.
- `case class` builds a plain immutable record — unchanged from Scala 2 — for a type with one
  shape rather than several, such as `Order` below.
- `opaque type` wraps an existing type under a new name that is erased at compile time, so it
  costs nothing at runtime while a raw `String` and a typed identifier stop being interchangeable
  at the type level (since: 3.0).
- `given`/`using` pass a dependency without a container (since: 3.0): a function's trailing
  parameter list reads `(using repo: OrderRepository)`, and the caller supplies a `given`
  instance once, near the edge — the same shape as Scala 2's implicit parameter, spelled with
  dedicated keywords instead of the overloaded `implicit`.
- `Either[E, A]` remains right-biased, unchanged from Scala 2.12 onward — `.map` and `.flatMap`
  act on the `Right` case directly, so it composes in a `for`-comprehension with no `.right`
  projection needed.

The worked example below carries unchanged through the ZIO, cats-effect, and direct-style
sections that follow — only the shell around the same `cancel` function changes. It is the same
small order model as `scala-2.md`: three states, one decision, now spelled with `enum`.

```scala
enum OrderStatus:
  case Placed, Paid, Cancelled

opaque type OrderId = String
object OrderId:
  def apply(value: String): OrderId = value

final case class Order(id: OrderId, status: OrderStatus)

enum CancellationError:
  case AlreadyCancelled

final case class OrderCancelled(id: OrderId)

// The core: pure, total, no import of anything that talks to the outside world.
def cancel(order: Order): Either[CancellationError, OrderCancelled] =
  order.status match
    case OrderStatus.Placed | OrderStatus.Paid => Right(OrderCancelled(order.id))
    case OrderStatus.Cancelled                 => Left(CancellationError.AlreadyCancelled)
```

`cancel` returns `OrderCancelled` — a plain value describing what happened — instead of
performing the write itself; the shell below is what performs it. That is principle 2 with no
effect type in sight: the description is just data.

```scala
trait OrderRepository:
  def load(id: OrderId): Order
  def save(event: OrderCancelled): Unit

def cancelOrder(id: OrderId)(using repo: OrderRepository): Either[CancellationError, OrderCancelled] =
  val order = repo.load(id)
  cancel(order).map { event => repo.save(event); event }
```

`cancelOrder` is the shell: it loads, hands the decision to `cancel`, and performs the write —
the only place in this example that imports anything I/O-shaped.

## ZIO 2 idiom

Published as `zio_3` from `dev.zio`, alongside the `zio_2.13` and `zio_2.12` artifacts covered
in `scala-2.md`; current release 2.1.26, part of the ZIO 2 (2.1.x) line — the same release line
on every Scala binary version it supports, since ZIO 2 ships one version number across all of
them rather than staggering releases per Scala version. `ZIO[R, E, A]` carries the environment it
needs, the typed error it can fail with, and the result it produces, all in one type. `ZLayer`
builds the `R` an application provides.

Principle 2 is satisfied structurally here, not by convention: a `ZIO` value is already a
description of a computation, built and passed around before anything runs. Nothing executes
until the runtime interprets it, so returning a `ZIO` from the core *is* returning a
description — there is no separate discipline to hold onto, the type carries it.

`cancel` is unchanged from Native capability above. Only the shell differs:

```scala
trait OrderRepository:
  def load(id: OrderId): UIO[Order]
  def save(event: OrderCancelled): UIO[Unit]

def cancelOrder(id: OrderId): ZIO[OrderRepository, CancellationError, OrderCancelled] =
  for
    repo  <- ZIO.service[OrderRepository]
    order <- repo.load(id)
    event <- ZIO.fromEither(cancel(order))
    _     <- repo.save(event)
  yield event

val live: ZLayer[Any, Nothing, OrderRepository] =
  ZLayer.succeed(new OrderRepository {
    def load(id: OrderId): UIO[Order]          = ???
    def save(event: OrderCancelled): UIO[Unit] = ???
  })
```

`OrderRepository` here is kept infallible (`UIO`) to keep the wiring visible; a repository that
can fail carries its own error type through `E` the same way `cancel`'s does.

## cats-effect 3 idiom

Published as `cats-effect_3` from `org.typelevel`, alongside the `cats-effect_2.13` and
`cats-effect_2.12` artifacts covered in `scala-2.md`; current release 3.7.1, part of the
cats-effect 3 (3.7.x) line. `IO[A]` describes an asynchronous computation; `Resource[F, A]`
describes acquisition paired with guaranteed release; `Ref[F, A]` is a concurrent mutable cell
reached through `F`, for the rare case the core needs shared state without reaching for a `var`.
Typical companions: `http4s` for HTTP, `fs2` for streaming, `doobie` for the database.

Principle 6 is carried by constructor injection — a class or function takes its dependencies as
plain constructor parameters — or by tagless final, writing against `F[_]` with a constraint such
as `Concurrent[F]` and supplying the concrete `IO` only at the program's edge. The example below
uses constructor injection, since it reads closest to the native and direct-style shells either
side of it.

`cancel` is unchanged from Native capability above. Only the shell differs:

```scala
trait OrderRepository:
  def load(id: OrderId): IO[Order]
  def save(event: OrderCancelled): IO[Unit]

final class OrderService(repo: OrderRepository):
  def cancelOrder(id: OrderId): IO[Either[CancellationError, OrderCancelled]] =
    repo.load(id).flatMap { order =>
      cancel(order) match
        case Right(event) => repo.save(event).map(_ => Right(event))
        case left         => IO.pure(left)
    }
```

## Direct style idiom

Scala 3 has a dedicated direct-style library where Scala 2 has none: Ox (`softwaremill/ox`),
current release 1.0.7, released within the month of this writing and on a steady release
cadence — the point this reference cares about is that it is actively maintained, not the exact
patch number. Ox needs a floor beyond "Scala 3" (since: JDK 21+): it requires JDK 21 or later
regardless of which Scala 3 minor version is in use, so it is unavailable on an older JDK even
on an otherwise-current Scala 3 project. It gives ordinary, sequential-looking code structured
concurrency and resiliency: `supervised` opens a scope, `fork` starts concurrent work inside it
that cannot outlive the scope, and operators such as `par`, `timeout`, and `raceSuccess` compose
plain values without an effect type wrapping them.

`cancel` is unchanged from Native capability above. Nothing in this worked example needs
concurrency, so the shell is the same shape as Native capability's, with the dependency threaded
through a constructor instead of a `using` clause — both are ordinary Scala 3, and either is
legitimate. Ox's operators would sit inside `cancelOrder` only if, for instance, the load raced
against a second independent lookup:

```scala
trait OrderRepository:
  def load(id: OrderId): Order
  def save(event: OrderCancelled): Unit

final class OrderService(repo: OrderRepository):
  def cancelOrder(id: OrderId): Either[CancellationError, OrderCancelled] =
    cancel(repo.load(id)).map { event => repo.save(event); event }
```

## Substitutions

None needed here — every Axis A principle Scala 3 expresses, it expresses natively, with the
constructs named above. The direction that breaks is the other one: a Scala 3 construct reached
for out of habit will not compile on Scala 2.13. See `scala-2.md`'s substitution table for the
Scala 2 form of each Scala 3 construct listed there.
