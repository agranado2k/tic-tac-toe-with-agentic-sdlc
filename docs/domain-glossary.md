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
- **Game** — a Board together with the current Mark (whose go it is), as one
  immutable value. `Game.new_game` is an empty Board with X current;
  `Game#play` is a Move by the current Mark, returning `Success(Game)` or
  `Failure(:occupied | :out_of_bounds | :game_over)`. Value Object
  (`Data.define`); not persisted. Ref: ADR-0001, PRD #2.
  - _Avoid_: "match", "session", "state".
- **Outcome** — what a Game has come to: `won(mark)`, `draw`, or
  `in_progress`. Derived from the Board (Winner takes precedence over a full
  Board), never stored; `terminal?` says whether another Move is possible.
  Value Object (`Data.define`). Ref: ADR-0001, PRD #2.
  - _Avoid_: "result" (a `Dry::Monads::Result` is a different thing here),
    "status", "end state".

## The terminal (`lib/tic_tac_toe/ui/`, `lib/tic_tac_toe/cli.rb`)

- **Renderer** — the pure function from a Board and a Status line to the
  `String` the player sees. Adapter (out). Ref: ADR-0002.
- **Status line** — the one line the Renderer draws inside the frame beneath
  the Board: which Mark is to move, why a keypress was refused, or the Winner
  or draw. An input to `Renderer.render`, padded to one width so a re-ask never
  resizes the frame; derived per Move by the Shell, never stored.
  Ref: ADR-0002, PRD #2.
  - _Avoid_: "message", "prompt", "banner" (a Prompt is the input adapter).
- **Frame** — the block of text one call to `Renderer.render` returns: the
  bordered Board with the Status line beneath it. Fixed in width and height by
  `STATUS_WIDTH`, which is what lets the Shell repaint it in place over its
  predecessor instead of printing a new one below. Ref: ADR-0002, PRD #2.
  - _Avoid_: "screen", "box", "window".
- **Prompt** — the `TTY::Prompt` that reads the player's single keypress, `1`–`9`
  for the Cell of that number, and the yes/no answer to "Play again?".
  Adapter (in). Ref: ADR-0002.
- **Replay** — a fresh Game started after a finished one, on the player
  answering yes to the Prompt's "Play again?". It carries the Shell's settings
  forward; hot seat is the only Mode today, so a Replay is `Game.new_game`.
  Ref: PRD #2.
  - _Avoid_: "restart", "rematch", "round", "new session".
- **Shell** — `TicTacToe::CLI`, the only place that prints and reads. It owns
  the cursor sequences that repaint the Frame in place; the Renderer never
  emits one. Ref: ADR-0001, ADR-0002.

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
