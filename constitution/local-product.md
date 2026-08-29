# Local product — who uses this, and how they reach it

Project-specific elaboration of the root `AGENTS.md`. Read it before running
`/dogfood`, and before making any change to a user-facing entry point.

## DOGFOOD DECLARATION

### SURFACES — the real thing a person touches

| Surface | What it is | How to bring it up | Notes / prerequisites |
| --- | --- | --- | --- |
| Terminal game | CLI binary, interactive, in the developer's own terminal | `bundle exec bin/tic-tac-toe` | Ruby per `.ruby-version` (rbenv) and `bundle install` once. Needs a real TTY: the prompt reads a single keypress, `1`–`9`, and a yes/no answer to "Play again?" at the end |

**Ready means reachable, not started.** The framed board is on screen and a
prompt is waiting for a key — that is how you know the surface is up; a process
that has spawned is not a product that answers. There is one frame per game and
it repaints where it stands, so a second board appearing below the first is a
fault, not progress.

### PERSONAS — who is trying to do what

| Persona | Goal | Enters at | Permission level | Surface |
| --- | --- | --- | --- | --- |
| Two friends at one keyboard | Play a full game of tic-tac-toe, taking turns as X and O, and see who won | `bundle exec bin/tic-tac-toe` | local user, no auth | Terminal game |
| Curious newcomer | Work out how to play from the screen alone — which key does what, what the numbers mean, when the game is over — without reading the README | `bundle exec bin/tic-tac-toe` | local user, no auth | Terminal game |

### Where a dogfood session may and may not go

- **Environments it may drive**: the local terminal only — and never a
  shared production environment unless it is named on that list.
- **Data it may create**: none. The game persists nothing.
- **Credentials**: none exist — a session that needs a login
  is given one deliberately; it never signs itself up for a real account.
- **Off limits entirely**: nothing in the product reaches the network, sends
  mail, or touches files; journeys that would are out of scope until an ADR
  says otherwise.

## What the product is for

A two-player game of tic-tac-toe on a 3×3 Board, played in one terminal by the
people sitting at it, that looks good enough to be worth opening a terminal for.
It exists to be a small, complete, functional-style Ruby program built end to
end through the agentic-sdlc chain — the product is the game, and the game is
also the demonstration.
