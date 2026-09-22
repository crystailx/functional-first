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
