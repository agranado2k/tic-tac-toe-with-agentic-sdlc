# Domain glossary — Ubiquitous Language

The registry of canonical terms for Tic Tac Toe. Use these spellings and
meanings consistently across **code** (type names, function names, table names),
commit messages, PR titles, ADRs, the diary, and conversations with agents.

One name per concept. An agent given two names for one thing will invent a
distinction between them.

**Adding a term** — introduce it in the same change that first uses it in code.
Say what it *is*, not what it does, and cross-reference the ADR or spec section
that defines its behavior.

**Changing a term** — rename across the whole codebase in a single change, and
update this file in the same commit. Do **not** leave aliases: the point of a
ubiquitous language is that there is exactly one name per concept.

**Retiring a term** — keep the entry, mark it _(superseded by `NewName`)_, and
say what replaced it. A deleted entry loses the fact that the old name ever
meant something, which is exactly what a reader of old code needs.

> **Source of truth.** This file is canonical for domain *language*. Where other
> documents disagree on a name, this one wins and they are synced to it. They
> still win on architecture — this carve-out is for naming only.

---

<!--
Group terms by bounded context (or by module, or by subsystem — whatever your
seams actually are). One `##` per context. Within a context, no particular
order; alphabetical stops being useful past about thirty terms, and grouping by
aggregate reads better.

Entry shape:

  - **Term** — what it is, in one or two sentences. Its kind (Aggregate root /
    Entity / Value Object / read type / port / adapter). Where it is persisted,
    if it is. Ref: <ADR-NNNN or spec section>.
    - _Avoid_: <the near-synonym people reach for, and why it is wrong>

Keep definitions short enough to read in a session-start scan. When one needs a
page of explanation, that page is an ADR and the entry points at it.
-->

## The game (`lib/tic_tac_toe/`)

- **Board** — the 3×3 grid of nine Cells, as one immutable value. Value Object
  (`Data.define`); not persisted. Ref: ADR-0001.
  - _Avoid_: "grid", "state" (a Board is the whole game state today, but the
    name says what it is, not what it is used for).
- **Cell** — one position on the Board, indexed 0–8 in code and shown as 1–9
  to the player. Holds a Mark or is empty (`nil`). Value.
  - _Avoid_: "square", "slot", "position".
- **Mark** — what a player puts in a Cell: `:x` or `:o`. Value. Ref: ADR-0001.
  - _Avoid_: "symbol", "piece", "token".
- **Move** — placing a Mark in an empty Cell; `Board#place` returns a
  `Success(Board)` or a `Failure(reason)`. Pure transition. Ref: ADR-0001.
  - _Avoid_: "turn" (a turn is whose go it is; a move is what they did).
- **Line** — one of the eight winning sets of three Cells (rows, columns,
  diagonals). Constant on `Board`.
- **Winner** — the Mark holding a complete Line, or none. Derived, never stored.

## The terminal (`lib/tic_tac_toe/ui/`, `lib/tic_tac_toe/cli.rb`)

- **Renderer** — the pure function from a Board to the `String` the player
  sees. Adapter (out). Ref: ADR-0002.
- **Prompt** — the `TTY::Prompt` that asks the player for a Cell. Adapter (in).
  Ref: ADR-0002.
- **Shell** — `TicTacToe::CLI`, the only place that prints and reads.
  Ref: ADR-0001.

---

## Words this project does not use

<!--
The other half of a ubiquitous language, and the half that is usually missing:
the terms that are ambiguous here and are therefore banned. Each line names the
banned word and the word to use instead.
-->

- **square / slot / position** — ambiguous here (position also means "board position" in game-tree talk). Use **Cell**.
- **piece / token / symbol** — ambiguous here (symbol is also a Ruby type). Use **Mark**.
- **turn** — ambiguous here (whose go vs. what they did). Use **Move** for the act; say "current Mark" for whose go it is.
