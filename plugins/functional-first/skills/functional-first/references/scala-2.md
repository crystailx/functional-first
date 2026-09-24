# Scala 2

last-verified: 2026-09

This reference covers capability and idiom for Scala 2's three Axis-B options — ZIO 2,
cats-effect 3, and direct style — and for the native language capability underneath all three,
which is where the worked example below lives before any of the three shells are layered on top
of it. It states what each option can do and what code written in it looks like, and holds no
preference among them: the choice is recorded per project in `SKILL.md`.

Scala 2.13 is a current target, not a prior one. Spark 4.x, for instance, currently requires
Scala 2.13 and has no Scala 3 build — a new project built on Spark is on 2.13 by requirement,
not by inertia. The `since:` markers below are relative to the two 2.x lines such a project
targets today, 2.12 and 2.13, both still cross-published by the libraries this reference
covers.

## Making principle 4 enforced

A `match` over a `sealed trait` that omits a case produces a compiler warning —
`match may not be exhaustive` — not a compile error, by default in both 2.12 and 2.13. The
check itself runs with no extra flag; only its severity is a warning.

Two flags close the gap:

- `-Xfatal-warnings` turns every warning in the compilation into an error, exhaustivity
  included, and is understood on both 2.12 and 2.13. 2.13 also accepts the newer name
  `-Werror` for the same flag.
- `-Wconf:cat=other-match-analysis:error` (since: 2.13.2; backported to 2.12.13) turns only
  match-exhaustivity and related match-analysis warnings into errors, leaving the rest of the
  build's warnings as warnings.

```scala
// build.sbt — either line is sufficient on its own
scalacOptions += "-Xfatal-warnings"
scalacOptions += "-Wconf:cat=other-match-analysis:error"
```

Without one of these set, principle 4 is advisory only in that project: the `sealed trait`
still documents the intended set of states and the compiler still points at a missed case, but
nothing stops a build from shipping with that case unhandled. This is the same shape as the
strict-checker precondition on the Python side of this guideline, and for the same reason — a
guarantee nobody enforces is not a guarantee.

## Native capability

- `sealed trait` plus `case class` (`case object` for a state with no fields) builds an
  algebraic data type; the exhaustivity check above is what turns it from documentation into a
  mechanical guarantee once a fatal-warnings flag is set.
- A value class (`case class X(value: T) extends AnyVal`) wraps a single field with no runtime
  allocation at most call sites, so a raw `String` and a typed identifier stop being
  interchangeable at the type level.
- Implicit parameters pass a dependency without a container: a function's last parameter list
  reads `(implicit repo: OrderRepository)`, and the caller supplies it once, near the edge.
- `Either[E, A]` is right-biased (since: 2.12) — `.map` and `.flatMap` act on the `Right` case
  directly, so it composes in a `for`-comprehension without a `.right` projection.

The worked example below carries unchanged through the ZIO, cats-effect, and direct-style
sections that follow — only the shell around the same `cancel` function changes. It is a small
order model: three states, one decision.

```scala
sealed trait OrderStatus
object OrderStatus {
  case object Placed    extends OrderStatus
  case object Paid      extends OrderStatus
  case object Cancelled extends OrderStatus
}

final case class OrderId(value: String) extends AnyVal
final case class Order(id: OrderId, status: OrderStatus)

sealed trait CancellationError
object CancellationError {
  case object AlreadyCancelled extends CancellationError
}

final case class OrderCancelled(id: OrderId)

// The core: pure, total, no import of anything that talks to the outside world.
def cancel(order: Order): Either[CancellationError, OrderCancelled] =
  order.status match {
    case OrderStatus.Placed | OrderStatus.Paid => Right(OrderCancelled(order.id))
    case OrderStatus.Cancelled                 => Left(CancellationError.AlreadyCancelled)
  }
```

`cancel` returns `OrderCancelled` — a plain value describing what happened — instead of
performing the write itself; the shell below is what performs it. That is principle 2 with no
effect type in sight: the description is just data.

```scala
trait OrderRepository {
  def load(id: OrderId): Order
  def save(event: OrderCancelled): Unit
}

def cancelOrder(id: OrderId)(implicit repo: OrderRepository): Either[CancellationError, OrderCancelled] = {
  val order = repo.load(id)
  cancel(order).map { event => repo.save(event); event }
}
```

`cancelOrder` is the shell: it loads, hands the decision to `cancel`, and performs the write —
the only place in this example that imports anything I/O-shaped.

## ZIO 2 idiom

Cross-published as `zio_2.13` and `zio_2.12` from `dev.zio`; current release 2.1.26, part of
the ZIO 2 (2.1.x) line. `ZIO[R, E, A]` carries the environment it needs, the typed error it can
fail with, and the result it produces, all in one type. `ZLayer` builds the `R` an application
provides.

Principle 2 is satisfied structurally here, not by convention: a `ZIO` value is already a
description of a computation, built and passed around before anything runs. Nothing executes
until the runtime interprets it, so returning a `ZIO` from the core *is* returning a
description — there is no separate discipline to hold onto, the type carries it.

`cancel` is unchanged from Native capability above. Only the shell differs:

```scala
trait OrderRepository {
  def load(id: OrderId): UIO[Order]
  def save(event: OrderCancelled): UIO[Unit]
}

def cancelOrder(id: OrderId): ZIO[OrderRepository, CancellationError, OrderCancelled] =
  for {
    repo  <- ZIO.service[OrderRepository]
    order <- repo.load(id)
    event <- ZIO.fromEither(cancel(order))
    _     <- repo.save(event)
  } yield event

val live: ZLayer[Any, Nothing, OrderRepository] =
  ZLayer.succeed(new OrderRepository {
    def load(id: OrderId): UIO[Order]          = ???
    def save(event: OrderCancelled): UIO[Unit] = ???
  })
```

`OrderRepository` here is kept infallible (`UIO`) to keep the wiring visible; a repository that
can fail carries its own error type through `E` the same way `cancel`'s does.

## cats-effect 3 idiom

Cross-published as `cats-effect_2.13` and `cats-effect_2.12` from `org.typelevel`; current
release 3.7.1, part of the cats-effect 3 (3.7.x) line. `IO[A]` describes an asynchronous
computation; `Resource[F, A]` describes acquisition paired with guaranteed release; `Ref[F, A]`
is a concurrent mutable cell reached through `F`, for the rare case the core needs shared state
without reaching for a `var`. Typical companions: `http4s` for HTTP, `fs2` for streaming,
`doobie` for the database.

Principle 6 is carried by constructor injection — a class or function takes its dependencies as
plain constructor parameters — or by tagless final, writing against `F[_]` with a constraint
such as `Concurrent[F]` and supplying the concrete `IO` only at the program's edge. The example
below uses constructor injection, since it reads closest to the native and direct-style shells
either side of it.

`cancel` is unchanged from Native capability above. Only the shell differs:

```scala
trait OrderRepository {
  def load(id: OrderId): IO[Order]
  def save(event: OrderCancelled): IO[Unit]
}

final class OrderService(repo: OrderRepository) {
  def cancelOrder(id: OrderId): IO[Either[CancellationError, OrderCancelled]] =
    repo.load(id).flatMap { order =>
      cancel(order) match {
        case Right(event) => repo.save(event).map(_ => Right(event))
        case left          => IO.pure(left)
      }
    }
}
```

## Direct style idiom

No library stands in for Ox here — Ox requires Scala 3. Async/await-style sugar does exist on
Scala 2 (`cats-effect-cps` and its successor `cats-effect-direct`, both cross-published to
2.12, 2.13, and 3.0), but both desugar onto the same `IO` underneath; they are a syntax variant
of the cats-effect option above, not a monad-free runtime. Direct style on Scala 2 is therefore
ordinary code plus discipline: no effect type, no structured-concurrency library holding the
edges together. Where concurrency is needed, it is `scala.concurrent.Future` or the JDK's
`java.util.concurrent` primitives — nothing in the compiler or the runtime enforces the
edges-only discipline the way Ox's structured scopes do on Scala 3, so it is held by convention
alone.

`cancel` is unchanged from Native capability above. The shell is the same shape as Native
capability's, with the dependency threaded through a constructor instead of an implicit
parameter — both are ordinary Scala, and either is legitimate:

```scala
trait OrderRepository {
  def load(id: OrderId): Order
  def save(event: OrderCancelled): Unit
}

final class OrderService(repo: OrderRepository) {
  def cancelOrder(id: OrderId): Either[CancellationError, OrderCancelled] =
    cancel(repo.load(id)).map { event => repo.save(event); event }
}
```

## Substitutions

A Scala 3 construct reached for out of habit will not compile here. This table gives the
Scala 2 form — the direction that actually breaks, since Scala 2 forms remain legal in Scala 3.

| Scala 3 construct | Scala 2 form |
|---|---|
| `enum` | `sealed trait` + `case class` / `case object` |
| `opaque type` | value class (`extends AnyVal`) |
| `given` / `using` | implicit parameters / implicit `def` |
| union types (`A \| B`) | no equivalent — model the alternative explicitly (a wrapping `sealed trait`, or separate signatures) |
