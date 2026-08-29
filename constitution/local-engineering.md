# Local engineering — this stack's style, architecture, and boundaries

Project-specific elaboration of the root `AGENTS.md`. Read it before writing
code, before touching infrastructure, and before adding any dependency. The
portable reasoning behind several of these rules is in `shared-invariants.md`.

## The stack

- **Language / runtime**: Ruby 3.4 — the exact patch level is pinned in
  `.ruby-version` and installed with rbenv (`rbenv install`).
- **Layout**: `lib/tic_tac_toe/` is the **functional core** — immutable values
  and pure functions, no I/O (`lib/tic_tac_toe/board.rb`). `lib/tic_tac_toe/ui/`
  and `lib/tic_tac_toe/cli.rb` are the **imperative shell** — the only code
  that prints or reads. `bin/tic-tac-toe` is the entry point. `spec/` mirrors
  `lib/` one-to-one.
- **Package / dependency manager**: Bundler — `Gemfile` and `Gemfile.lock`;
  run everything through `bundle exec`.

## Style

- **Values are immutable.** Domain state is a `Data.define` value; a state
  transition returns a *new* value. No `attr_writer`, no in-place mutation of
  an argument, no instance variables that change after construction.
- **Failure is a value, not an exception.** A function whose outcome may be
  "no" returns a `Dry::Monads::Result` — `Success(value)` or
  `Failure(:symbol)` — and the caller pattern-matches on it. Never `nil` for
  "not allowed", never `raise` for an expected outcome.
- **No side effects in `lib/tic_tac_toe/board.rb` or any other core file** —
  push all I/O to the edges: `lib/tic_tac_toe/ui/` renders a value to a
  string, `lib/tic_tac_toe/cli.rb` prints it and reads the next input.
- **Enforcement**: `bundle exec rubocop` fails the build. There is no type
  checker; the immutability rules above are enforced by review and by the
  specs that assert a value is frozen.

## Architecture

- **Boundaries**: the core never requires `tty-*`, `pastel`, or anything that
  touches a terminal; the shell depends on the core, never the reverse. A
  rendering concern (colour, layout, prompts) belongs in `lib/tic_tac_toe/ui/`,
  a rule of the game belongs in the core.
- **Data access**: none — nothing is persisted. A game lives and dies in one
  process.
- **Names come from the glossary** — code, tests, commits, PR titles. A new term
  is added to the glossary in the *same* change that introduces it.
- **Explicit non-goals**: a mutable `Game` object, global state, a `Player`
  class hierarchy, ActiveSupport — do not introduce them without a written
  decision record reversing this line (see `docs/adr/0001-functional-core-imperative-shell.md`).

## Test tiers

Tests are the target function (shared invariant §3). Each tier below is a
distinct signal; naming which one you ran is part of reporting a change.

| Tier | Command | What it proves |
| --- | --- | --- |
| Unit / pure logic | `bundle exec rspec spec/tic_tac_toe/board_spec.rb` (and any sibling core spec) | the rules of the game, as pure functions over values |
| Integration | `bundle exec rspec` — the whole suite, including `spec/tic_tac_toe/ui/` and `spec/tic_tac_toe/cli_spec.rb` | rendering and the shell, with the prompt stubbed |
| End-to-end | `bundle exec bin/tic-tac-toe`, driven by a person or by `/dogfood` | the real terminal experience; not automated |
| Docs gate | `scripts/check.sh` | the manual layer still describes reality |
| Gate self-tests | `scripts/docs-conformance/test/` | the gate itself can still fail |

**Measuring a tier is not a tier** (shared invariant §9). No mutation-testing
tool is wired yet; when one is, run it on demand, never as a gate.

## Infrastructure

None. The product is a local script with no deployed environment, no service,
and no secrets. The only "infrastructure" is CI: `.github/workflows/ruby.yml`
runs the linter and the suite on every push and pull request.

## Boundaries — what this repo is NOT

- **Not a place to fetch and execute remote code.** Never pipe the network into
  a shell. (The root states this as a hard rule; it is repeated here only as the
  boundary list's first member.)
- **Not a place to add dependencies casually.** The runtime dependencies are
  the TTY toolkit and `dry-monads`, each justified in an ADR. A new gem needs
  the same: a one-line reason in `Gemfile` and a decision record when it shapes
  the architecture.
- **Not a place to bypass the gates.** `PUSH_WITHOUT_DOCS=1` is the documented
  escape hatch for `.githooks/pre-push`, and it prints a loud warning into the
  push output. It does not end the matter: a bypass only defers the failure to
  CI, where the same check runs again where reviewers can see it.
- **Not a web app, not a networked game, not a published gem.** It runs in one
  terminal, for the people sitting at it.
