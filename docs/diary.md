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
| **Phase** | Stack scaffolded on top of the kit: Ruby 3.4 + Bundler, functional core (`lib/tic_tac_toe/board.rb`), TTY-toolkit shell, RSpec + RuboCop, CI. One tracer bullet runs end to end (render → one move → render). No game loop yet. |
| **Repo** | `~/PetProjects/tic-tac-toe-with-agentic-sdlc` (`main`). Feature work happens in `worktree/<slug>` on a `<type>/<slug>` branch. |
| **Remote** | `git@github.com:agranado2k/tic-tac-toe-with-agentic-sdlc.git` — created empty, never pushed yet |
| **Last commit on `main`** | `f3f65f0` — PR #1 squash: mutant wired, specs hardened, review fixes |
| **Deployed / live** | Nothing yet. |
| **Active worktrees** | `worktree/name-the-tracker` on `docs/name-the-tracker` — PR #3, names GitHub Issues as the tracker; awaiting merge. |
| **Spec status** | PRD published as GitHub issue #2 (2026-08-29) after `/grill-me`: hot-seat + versus computer (easy/hard), number-key input, in-place redraw, replay. `/to-tickets` in progress. |

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
