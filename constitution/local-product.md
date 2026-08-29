# Local product — who uses this, and how they reach it

Project-specific elaboration of the root `AGENTS.md`. Read it before running
`/dogfood`, and before making any change to a user-facing entry point.

## DOGFOOD DECLARATION

### SURFACES — the real thing a person touches

| Surface | What it is | How to bring it up | Notes / prerequisites |
| --- | --- | --- | --- |
| Terminal game | CLI binary, interactive, in the developer's own terminal | `bundle exec bin/tic-tac-toe` | Ruby per `.ruby-version` (rbenv) and `bundle install` once. Needs a real TTY: the prompt reads a yes/no answer to "Play against the computer?" — and, if that answer was yes, a second one to "Unbeatable computer?" — before the first frame, then a single keypress, `1`–`9`, per Move, and a yes/no answer to "Play again?" at the end |

**Ready means reachable, not started.** The Mode question, and versus the
computer the Difficulty question, have been answered, the
framed board is on screen and a prompt is waiting for a key — that is how you
know the surface is up; a process that has spawned is not a product that
answers. There is one frame per game and
it repaints where it stands, so *within a game* a second board appearing below
the first is a fault, not progress. A Replay is the one exception: it opens a
fresh frame below the "Play again?" line.

**Versus the computer the human is X and opens.** O is played by a Strategy, not
by a keypress: after your Move the frame repaints, waits about half a second, and
repaints again with "Computer plays N" under the board naming the Cell it took.
Being asked for a key on O's go is a fault, and so is the board changing with no
pause and no status line saying what changed.

**The Difficulty is what O is playing with.** Answer no to "Unbeatable
computer?" and O is the Random Strategy: it is meant to miss wins and blocks, so
losing to you is not a fault. Answer yes and O is Minimax, which never loses — a
human win on hard is a fault, and a draw is the best result the surface should
ever give you.

**Ctrl-C is how you leave.** At any prompt it quits the game quietly: exit
status 130, no backtrace, and the frame that was on screen still on screen.
Abandoning a game is not an error, so a stack trace in the terminal is a fault.

### PERSONAS — who is trying to do what

| Persona | Goal | Enters at | Permission level | Surface |
| --- | --- | --- | --- | --- |
| Two friends at one keyboard | Play a full game of tic-tac-toe, taking turns as X and O, and see who won | `bundle exec bin/tic-tac-toe` | local user, no auth | Terminal game |
| Curious newcomer | Work out how to play from the screen alone — which key does what, what the numbers mean, when the game is over — without reading the README | `bundle exec bin/tic-tac-toe` | local user, no auth | Terminal game |
| Solo player vs computer | Beat the easy computer, or grind out a draw against the unbeatable one, with nobody else at the keyboard — and see what it just played | `bundle exec bin/tic-tac-toe`, answering yes to "Play against the computer?", then choosing a Difficulty at "Unbeatable computer?" | local user, no auth | Terminal game |

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

A game of tic-tac-toe on a 3×3 Board, played in one terminal — by two people
sitting at it, or by one against the computer — that looks good enough to be
worth opening a terminal for.
It exists to be a small, complete, functional-style Ruby program built end to
end through the agentic-sdlc chain — the product is the game, and the game is
also the demonstration.
