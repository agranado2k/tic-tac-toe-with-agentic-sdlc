# ADR-0001: Adopt a functional core with an imperative shell

- **Status**: Accepted
- **Date**: 2026-08-29
- **Deciders**: Andre Granado (project owner), with Claude Code drafting
- **Supersedes / amends**: —
- **Superseded by**: —

## Context and problem statement

The project is a terminal tic-tac-toe game in Ruby, and its owner asked for a
"more functional" approach than the idiomatic-Ruby default of mutable objects
that both hold state and talk to the terminal. Ruby does not force a style: a
`Game` class with `@board` mutated by `play!` and `puts` scattered through it
is the path of least resistance and the one every newcomer (human or agent)
reaches for on day one.

The decision has to be made before the first line of game logic lands, because
the two styles do not mix: a single mutable seam in the core makes every test
above it order-dependent and every renderer a side effect.

## Decision drivers

- Testability: the rules of the game must be checkable with no terminal, no
  stub, and no ordering between tests.
- Readability for a functional-leaning reader: state transitions as values in,
  values out.
- Staying idiomatic Ruby — no framework that turns Ruby into something else.
- Small footprint: one runtime dependency at most for the style itself.

## Considered options

1. **Functional core / imperative shell, with `Data.define` values and
   `dry-monads` Results** *(chosen)* — immutable value objects, pure
   transition functions returning `Success`/`Failure`, all I/O confined to a
   thin shell.
2. **Idiomatic mutable OO** (`Game#play!`, `Board#[]=`) — rejected: every test
   of a rule needs a fresh fixture and an ordering; rendering leaks into the
   model; it is exactly the default the owner asked to move away from.
3. **Plain hashes and arrays with module functions, no monads** — rejected:
   tenable, but "no" has to be `nil` or an exception, and both hide the reason
   for the refusal at the call site. `dry-monads` is one small, well-maintained
   gem (32.9M downloads, v1.10) that gives `Failure(:occupied)` a name.

## Decision outcome

Chosen: **functional core / imperative shell**.

1. Domain state is an immutable `Data.define` value. A transition is a method
   that returns a new value; nothing under `lib/tic_tac_toe/` mutates its
   receiver or its arguments.
2. A transition that may be refused returns a `Dry::Monads::Result`:
   `Success(new_value)` or `Failure(:reason_symbol)`. Expected outcomes never
   raise and never return `nil`.
3. Only `lib/tic_tac_toe/ui/` and `lib/tic_tac_toe/cli.rb` may perform I/O.
   Rendering is a pure function from a value to a `String`; printing that
   string and reading the next input is the shell's job alone.
4. The core never requires a terminal library. The shell may depend on the
   core; the reverse is forbidden.
5. **Explicit non-goal**: this does not decide the game's features (AI
   opponent, board size, scoring); those go through the spec chain.

## Consequences

- **Good**: the rules are tested with plain values and no doubles; the renderer
  is tested by asserting on a string; the shell is the only place a
  `TTY::Prompt` double is ever needed.
- **Bad / trade-off**: one more concept (`Result`) for a reader who has never
  seen a monad; each move allocates a new `Board`. Both are paid by the
  developer, never by the player — a 3×3 board makes the allocation invisible.
- **Neutral**: `Data.define` requires Ruby ≥ 3.2; the project pins 3.4.
- **Honest limitation**: nothing enforces purity mechanically. RuboCop does not
  know what a side effect is; the boundary is held by review and by the specs
  asserting values are frozen.

## More information

- Implemented in: the bootstrap commit's `lib/tic_tac_toe/board.rb` tracer bullet
- Related: ADR-0002 (the terminal toolkit the shell uses),
  `constitution/local-engineering.md`
