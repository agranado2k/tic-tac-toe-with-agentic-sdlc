# Development diary

> Living history of the Tic Tac Toe build. The **Current state** block at the
> top is the agent re-orientation summary — read it first when picking up the
> project. Below it: forward-chronological entries, newest at the bottom.

---

## Current state — 2026-08-29

<!--
Update this block IN PLACE. It is the only part of this file that is edited
rather than appended to: it answers "where is this project right now?" for an
agent (or a human) opening a fresh session, and a stale answer here poisons
every session that reads it. Entries below are append-only.

Keep it to facts an agent cannot cheaply derive: the phase, what is live, what
is in flight. Do not restate the README.
-->

| Field | Value |
| --- | --- |
| **Phase** | Both Modes playable: hot seat, and versus the computer with the Random Strategy (easy). One frame repainted in place, number keys, status line, Replay, quiet Ctrl-C. Next: #8 (Minimax, difficulty prompt, ADR-0003) — the last PRD #2 ticket. |
| **Repo** | `~/PetProjects/tic-tac-toe-with-agentic-sdlc` (`main`). Feature work happens in `worktree/<slug>` on a `<type>/<slug>` branch. |
| **Remote** | `git@github.com:agranado2k/tic-tac-toe-with-agentic-sdlc.git` |
| **Last commit on `main`** | `091b1d6` — PR #14 squash: versus-computer Mode with a Random Strategy (ticket #7) |
| **Deployed / live** | Nothing yet. |
| **Active worktrees** | None. |
| **Spec status** | PRD #2 → tickets #4–#9. #4, #5, #6, #7, #9 landed (PRs #10–#14); #8 is the last one. |

### Open questions / unresolved decisions

<!--
Things that are genuinely undecided, one bullet each, with enough context that
future-you can decide without re-deriving the problem. Strike a line through or
mark **RESOLVED <date>:** in place when it is settled — deleting it loses the
record that it was ever open.
-->

- ~~Should the game get a computer opponent, and if so how strong (random / minimax)?~~ **RESOLVED 2026-08-29:** yes, selectable easy (random) / hard (minimax) — PRD #2.
- ~~Redraw in place (`tty-cursor`) vs. print a new board each move?~~ **RESOLVED 2026-08-29:** redraw in place — PRD #2.

### Memory pointers for future-me

<!--
The half-dozen facts you keep re-learning. Not documentation — pointers at it.
-->

- **The diary is the orientation document.** Read this `Current state` block at
  session start; everything below it is history.
- **The spec wins** in disputes. When the diary and the spec disagree, the spec
  is the contract and the diary is the log.
- **Decisions live in `docs/adr/`**, not here. A diary entry may *announce* a
  decision, but the ADR is the record.
- **Terms live in `docs/domain-glossary.md`.** One name per concept, everywhere.

### Update protocol

<!--
Shared invariant §8: a rule nothing checks decays into a lie. This protocol is
the cheapest honest form of "when does the diary get written?" — keep it short
enough that it is actually followed, and make the triggers observable events
rather than feelings.
-->

- **Phase milestone reached** → append a new dated entry below.
- **ADR added, decision reversed, or vendor changed** → append a new dated
  entry; do **not** edit old entries.
- **Worktree created for a non-trivial feature** → note it in the next entry;
  remove it from the active list when it merges.
- **Infrastructure changed** → append an entry naming the environment, the size
  of the change, and what moved.
- **Anything above happened** → also refresh the `Current state` block in place.

---

## Entries

<!--
Forward-chronological, newest at the BOTTOM (so reading top-to-bottom reads the
project's history in order). One `###` heading per entry:

    ### YYYY-MM-DD — <headline: what changed, not what you did>

Write what was decided and why, not a commit log — `git log` already exists.
Never edit a past entry; correct it with a new one that references it.
-->

### 2026-08-29 — Bootstrapped from the agentic-sdlc kit

A functional-style tic-tac-toe game for the terminal, written in Ruby.

The repo was created from the `agentic-sdlc` template and personalized by
`bootstrap.sh`: the root `AGENTS.md` agent manual, the portable
`constitution/shared-invariants.md` rulebook, the `scripts/check.sh` docs gate
wired to `.githooks/pre-push`, and this documentation set (diary, ADR index +
MADR template, domain glossary, PR template).

The shared layer taken is recorded in `VERSION`; `UPDATING.md` is the recipe for
moving it forward when the kit does.

First real decisions go in `docs/adr/`; first real progress goes below this
line.

### 2026-08-29 — Ruby stack scaffolded; two decisions recorded

Same day as the bootstrap. The stack was chosen and wired in one pass:

- **Ruby 3.4.10 via rbenv** (`.ruby-version`); system Ruby on the dev machine
  is 2.6 and cannot run `Data.define`.
- **ADR-0001** — functional core / imperative shell, `Data.define` values,
  `dry-monads` Results. **ADR-0002** — the TTY toolkit (`tty-prompt`, `pastel`,
  `tty-box`, `tty-cursor`, `tty-screen`) for the shell; Shopify `cli-ui`
  considered and rejected. Gem versions and download counts were checked live
  on rubygems.org before deciding.
- Tracer bullet: `TicTacToe::Board` (place / winner / full?) with specs, a pure
  `UI::Renderer`, and `CLI.run` taking one move. `bin/tic-tac-toe` runs it.
- The three local articles are filled in and pointed at from `AGENTS.md`; the
  TDD pairing guard is armed on `lib/`; tiers are mapped in
  `scripts/agents.config.sh`; `adapters/node-ts/` removed (stack mismatch).
- `.github/workflows/ruby.yml` runs RuboCop + RSpec in CI.

Remote created on GitHub, deliberately not pushed — the first push is the
owner's.

### 2026-08-29 — Mutation testing wired; the first run measured the suite

`mutant-rspec` 0.16.3 added (dev/test group, `.mutant.yml`, `usage: opensource`).
The kit's bootstrap path never asks for this decision — reported upstream as
agentic-sdlc issue #85.

The first run reported 1.5% coverage: not weak tests, invisible code. Methods
defined inside a `Data.define do … end` block are not subjects to mutant, and
`module_function` methods are mutated on the instance copy while the tests call
the singleton copy. `Board` is now reopened as a class after `Data.define`, and
the shell modules use `def self.`. Second run: 81.8% with 89 survivors, which
named the gaps — `full?` returning a truthy array, the untested `dup` in
`Board.new`, `rows`/`winner` only exercised through the renderer, uncoloured
glyphs, the default `Pastel.new`. Specs added for each.

Also found: RuboCop reads `AllCops/Exclude` from the topmost `.rubocop.yml`, so
the root `worktree/**/*` exclude made it inspect 0 files inside a worktree. The
pattern is now rooted at `Dir.pwd`.

### 2026-08-29 — PR #1 landed by /merge-train; PRD #2 published

`/review-pr` under `/pr-iterate` found one real bug in the mutation branch
(a dead duplicate `TicTacToe::LINES` left by the constant move), an un-dimmed
divider row, and a `$PWD` dependency in the RuboCop worktree exclude — all
fixed in-branch; the owner accepted the behaviour confirm-list as-is, including
the mixed refactor+behaviour commit. Squash-merged as `f3f65f0`; worktree
pruned.

`/grill-me` settled the game's shape and `/to-prd` published it as issue #2.
The two open questions above are resolved by it. GitHub Issues is the tracker
(PR #3 records that in the workflow article); `ready-for-agent` and `prd`
labels exist on the repo. Upstream kit findings filed as agentic-sdlc #85
(no mutation-tool decision at bootstrap) and #86 (skills invisible to the
installing session).

### 2026-08-29 — Hot-seat game: the first PRD #2 ticket, and the seams it fixes

Ticket #4 (`feat/hot-seat-game`) adds the two values every later ticket
builds on. `Game` is `Data.define(:board, :current_mark)` — the field is named
after the glossary's "current Mark", never "turn" — with `Game#play(cell)`
reusing `Board#place` and failing with `:game_over` once the Game is finished.
`Outcome` is `Data.define(:kind, :mark)` with constructors `won(mark)`, `draw`,
`in_progress`, derived by `Outcome.of(board)` with the Winner taking precedence
over a full Board; `terminal?` is the loop's exit test. Both are reopened as
classes after `Data.define` so mutant sees them. `CLI.run` now loops to the
announcement ("X wins" / "O wins" / "Draw") and returns the finished Game
instead of a Board.

One tooling finding: mutant 0.16.3 raises a `GenerationError` on a `case … in`
hash pattern and aborts the whole run, so the shell announces the Outcome with
a plain `case outcome.kind`. Pattern matching on `Outcome` is still fine in
specs; avoid it under `lib/` until mutant can mutate it.


### 2026-08-29 — PRs #3 and #10 landed by /merge-train; ticket #4 done

`/pr-iterate 10` applied three of the independent review's six findings
(player-facing strings moved into the Renderer, `Outcome` refuses an unknown
kind, `NEXT_MARK` derived from `Board::MARKS`) and held two that overlap the
human confirm-list (`announcement` totality; pinning `:game_over` precedence)
plus one deferred to ticket #5 (re-ask on a refused Move). The owner chose to
merge with the confirm-list open; its items stay on PR #10 for the record.

Landed in order #3 (tracker named in the workflow article) then #10 (updated
against the new base through the forge API before merging). Both worktrees
pruned; `main` is `0939fbb`. Found on the way: the AI-review workflow runs
despite its `.example` name — GitHub registers every `.yml` — and only skips
because no provider secret is set; and mutant 0.16 crashes on `case … in`
pattern matching, so shell code uses `case … when` on the Outcome kind.

### 2026-08-29 — Number keys replace the selection list; the frame gained a status line

Ticket #5 (`feat/number-key-input`). The tracer bullet's arrow-key
`TTY::Prompt#select` and its `choices_for` label-to-index mapping are gone. A
Move is now one keypress read with `TTY::Prompt#keypress`; `CLI::CELL_KEYS`
maps key `"1"` to Cell index 0 … `"9"` to index 8, the same numbers the
Renderer already draws on the empty Cells.

`Renderer.render` gained a `status:` input drawn inside the frame beneath the
Board — the **Status line**, now a glossary term. It carries whose go it is,
why a keypress was refused, and the announcement at the end, so
`Renderer.question` ("Where does X go?") is gone: the frame is the question.
Every status is padded to `STATUS_WIDTH` (the length of the longest one) and
`TTY::Box` centres the content, so a re-ask does not resize the frame between
Moves — worth having before ticket #6 redraws in place. The parameter landed in
its own commit ahead of the shell change (shared invariant §10): with `status`
omitted the frame is byte-identical to the old one.

`CLI.advance` answers every keypress with a `[Game, status]` pair, so a refused
Move re-asks instead of raising — this closes the `.value!`-on-the-public-seam
finding PR #10 deferred here. A key that is not a Cell shows
`"Not a Cell — press 1–9"`; a `Failure(:occupied)` shows `"Cell 5 is taken"`,
naming the Cell 1-based as the player sees it.

Found while writing the demo: when the keypress source is exhausted (`nil`,
which is what a piped or closed stdin gives), `advance` treats `nil` as "not a
Cell" and the loop re-asks forever. Harmless against a real TTY, where
`keypress` blocks; recorded as a behaviour finding on the PR, and the natural
home for the fix is ticket #6/#9's Ctrl-C and quit handling.

### 2026-08-29 — Ticket #5 landed (PR #11)

`/pr-iterate 11` applied all six review findings: the loop now leaves when
the input stream is closed (`keypress` returns `nil` — it re-asked forever
before, reproducible with `< /dev/null`), a refused Move is reported by its
reason instead of always "Cell N is taken", ADR-0002 carries a dated
amendment narrowing the input clause to a single keypress, the three copies
of the play-a-Game reduce became one `game_after` spec helper, and
`Renderer.rows` became `grid`. Five behaviour questions (fixed 28-column
frame, status styling, silent keypress prompt, wording, the product-article
prerequisite) stay on the PR for the owner. Merged under the standing
"merge-train after each ticket" authorization for this run.

### 2026-08-29 — One frame per game: redraw in place, and "Play again?"

Ticket #6 (`feat/redraw-and-replay`). The terminal now shows one game rather
than a scrolling log of frames. The Shell keeps the frame it last wrote and,
before every repaint, emits `TTY::Cursor.up(<frame height>) + column(1) +
clear_screen_down` over it — the use ADR-0002 §2 already reserved `tty-cursor`
for, so no new ADR. The Renderer is unchanged: still a pure Board-plus-status
to `String` function, and still the only thing that knows what a frame looks
like. The fixed 28-column, 9-line frame that ticket #5 built for exactly this
is what makes the arithmetic (`frame.lines.count`) safe.

`CLI.run` became a loop over Games: `play_game` runs one Game to its Outcome,
then `replay?` asks the Prompt's `yes?` — "Play again?" — exactly once per
finished Game. Yes starts a fresh `Game.new_game` (the whole of "the same
settings" while hot seat is the only Mode; `Game.new_game` was left alone, as
PR #10's confirm-list item 6 asked) drawn as a new frame below the question,
because the question is written by the Prompt to its own stream and its height
is not ours to count. No returns the finished Game with the final frame on
screen.

One behaviour change the ticket did not name: a Game abandoned when the input
stream closes is no longer repainted with a statusless frame. That frame is two
lines shorter than the others, and a frame that changes height cannot be redrawn
in place. It also gets no "Play again?" — it never finished.

Glossary gained **Frame** and **Replay**; **Prompt** and **Shell** were widened
to name the yes/no answer and the cursor sequences. `constitution/local-product.md`
records the yes/no prompt in the surface prerequisites and states the redraw as
a dogfood tell: a second board below the first is a fault.

Mutation: 27 alive / 18 timeouts / 97.35% coverage over 1019 mutations, against
23 alive / 11 timeouts / 97.35% over 869 on `main`. All four new survivors are
in `CLI.rewind_over` and all four are equivalent — `Array#count`/`length`/`size`
on the same array, and `TTY::Cursor.column(1)` versus its default argument.

### 2026-08-29 — Ticket #6 landed (PR #12)

The Shell now repaints one frame in place (`tty-cursor`: up 9, column 1,
clear down) and asks "Play again?" once per finished Game; a Replay opens a
fresh frame below the question. `/pr-iterate 12` applied all eight review
findings, the notable one being a dogfood tell in `local-product.md` that
would have filed the Replay's own frame as a fault — now scoped to "within a
game". Six behaviour questions (where a Replay frame lands, the abandoned-Game
repaint, five new public shell functions, `yes?` defaulting to yes, no
terminal-width detection, the tell's wording) stay on the PR for the owner.

### 2026-08-29 — Ctrl-C quits quietly

Ticket #9 (`feat/ctrl-c-quits-quietly`). Pressing Ctrl-C at a Prompt used to
print a twenty-five frame Ruby backtrace over the Board and kill the process by
signal. The Shell now rescues `Interrupt` once, at the outer edge of `CLI.run`,
prints one blank line and ends the process with status 130 — 128 plus SIGINT,
the status a shell reports for a program that took that signal.

Two facts decided the shape, both read out of the installed gems rather than
assumed. `tty-prompt`'s reader defaults to `interrupt: :error` and raises
`TTY::Reader::InputInterrupt`, which is a subclass of `Interrupt`; and when the
key lands while the terminal is *not* inside the reader's raw read, the terminal
driver turns it into SIGINT and Ruby raises a bare `Interrupt` instead. Rescuing
the parent covers both, and which one arrives is a race the player cannot see.

Nothing is rescued inside `play_game`, so the interrupt skips `finish`: no
rewind is emitted after it and the Frame on screen is the last one drawn. The
core is untouched, and so is `bin/tic-tac-toe` — the exit lives in the Shell so
that a spec can observe the status (`SystemExit#status`) without the process
dying, which is what ticket #9 asked for.

The binary itself stays un-automated, as PRD #2 decided ("exercised by
`/dogfood`, not by an automated tier"): the review of PR #13 caught a
pseudo-terminal spec of `bin/tic-tac-toe` that this branch had added against
that decision, and it was removed. The pty run (`PTY.spawn`, Ctrl-C byte
`0x03`, `exitstatus == 130`, no backtrace on screen) lives on as the PR's demo
evidence and as the by-hand check the ticket asked for.

Mutation: 1017 mutations, 27 alive, 21 timeouts, 97.34% coverage — against 998 /
27 / 21 / 97.29% on `main` with the branch stashed. Every one of the 19 new
mutations dies; the survivors are the pre-existing ones in `Board`, `Outcome`,
`Renderer` and `CLI.advance` / `refusal` / `rewind_over`.

### 2026-08-29 — Ticket #9 landed (PR #13)

Ctrl-C at any Prompt now leaves the Frame on screen, prints one blank line
and ends with status 130 — no backtrace. The review caught the branch adding
an automated pseudo-terminal spec of the binary against PRD #2's decision
that the binary is exercised by `/dogfood` only; the spec was removed and the
pty run kept as demo evidence. Open for the owner on the PR: whether the
`exit` should move from `CLI.run` to `bin/tic-tac-toe`, and the rescue being
`Interrupt` rather than only the reader's `InputInterrupt`.

### 2026-08-29 — A computer to play against: the Mode question and the Random Strategy

Ticket #7 (`feat/versus-computer`). The game now asks, before it draws
anything, "Play against the computer?" — a yes/no, the same shape as "Play
again?", because PRD #2's grill-me decision rules out selection lists and
cursors and ADR-0002's amendment already narrowed input to keys and answers.
The answer becomes a **Mode**, `:hot_seat` or `:versus_computer`, and the Shell
carries it for the whole run: a Replay never asks it again.

**Strategy** is the new core seam — a value answering `#call(board, mark)` with
the Cell it chooses, so the Minimax ticket adds a second implementation and the
Shell's routing changes in one place (`CLI.computer_strategy`). Its first
implementation is `Strategy::Random`: `available.fetch(source.rand(available
.length))`, where `source` is an injected object responding like `::Random`.
The core therefore draws no randomness of its own — the Shell owns the one
`::Random.new` — and the spec seeds it to get a deterministic answer, plus a
draw-spread example that kills a "always take the first Cell" implementation.

In the loop, ownership of a Move is one predicate: `computer_to_move?` is true
where this run chose a Strategy and the current Mark is O. Nothing else in
`play_game` knows about Modes; the human branch is the code that was already
there. The computer's go pauses first — an injectable callable, default
`->(seconds) { sleep(seconds) }` at `COMPUTER_PAUSE_SECONDS = 0.5`, a no-op in
specs — and then repaints with `Renderer.computer_plays(cell)`, "Computer plays
N", 1-based as the player sees it. At 16 characters it is well inside
`STATUS_WIDTH` (22, still `NOT_A_CELL`), so the Frame keeps its one width and
the in-place repaint arithmetic is untouched.

One thing the ticket did not name and the specs now pin: because the Mode
question and "Play again?" are both `yes?`, every `yes?` stub in the CLI spec
had to name its question (`.with(described_class::PLAY_AGAIN)`). That is a
sharper contract than the bare stub it replaces — a spec that meant "the Replay
question" no longer accidentally answers a different one.

Mutation: 1228 mutations (1017 on `main`), 29–30 alive and 97.55–97.63%
coverage over four runs, against 27 alive and 97.34% on `main`. Every mutation
of `Strategy::Random#call` and of the loop's new routing dies; the two or three
extra survivors are all the same equivalent pair on `CLI.run`'s `random:`
default — `::Random.new` mutated to `Random.new` (the same constant) and to
`::Random` itself, which answers `rand` as a module method and is therefore a
working random source too. Timeouts swung between 23 and 49 across those runs
with the code unchanged, so on this machine mutant's timeout count is a
measure of load under eight parallel jobs, not a property of the suite.

### 2026-08-29 — Ticket #7 landed (PR #14)

The run opens with "Play against the computer?"; versus the computer the
human is X and O comes from a Strategy — a core function of the Board, the
Mark and its injected state, first implemented as Random over an injected
source — with a "Computer plays N" status after an injectable 0.5 s pause.
`/pr-iterate 14` applied all six review findings (Ctrl-C on the Mode question
pinned, README brought back to reality, the Strategy wording corrected).
Five behaviour questions stay on the PR for the owner, notably that Enter on
the Mode question defaults to yes (versus computer).
