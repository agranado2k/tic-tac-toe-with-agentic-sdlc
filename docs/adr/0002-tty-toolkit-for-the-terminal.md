# ADR-0002: Adopt the TTY toolkit for terminal rendering and input

- **Status**: Accepted
- **Date**: 2026-08-29
- **Deciders**: Andre Granado (project owner), with Claude Code drafting
- **Supersedes / amends**: —
- **Superseded by**: —

## Context and problem statement

The owner wants "a beautiful CLI game design", which means colour, a framed
board, and a prompt that reacts to arrow keys rather than a bare `gets`. Hand
rolling ANSI escapes is possible but is exactly the kind of code that hides
bugs in terminal edge cases (width, colour support, Windows). The choice of
library shapes the whole imperative shell (ADR-0001), so it is made once, here.

## Decision drivers

- Composable: pick only the pieces needed (colour, frame, prompt), keep the
  shell small.
- Maintained and widely used — verified on rubygems.org on 2026-08-29, not
  assumed.
- Testable without a terminal: colours can be disabled, prompts can be
  doubled.
- Fits a pure renderer: a function that returns a `String`.

## Considered options

1. **The TTY toolkit** — `tty-prompt` 0.23.1 (89.9M downloads), `pastel` 0.8.0
   (115M), `tty-box` 0.7.0 (13M), `tty-cursor` 0.7.1, `tty-screen` 0.8.2
   *(chosen)* — independent gems with one author and one style; each does one
   thing; `Pastel.new(enabled: false)` and a `TTY::Prompt` double make the shell
   testable.
2. **Shopify `cli-ui`** 2.7.0 (9.1M downloads) — rejected: a full framework with
   its own frame/spinner/prompt conventions and a global `CLI::UI::StdoutRouter`;
   more opinionated than a 3×3 board needs, and its output is harder to assert
   on as a plain string.
3. **`colorize` + hand-written prompt loop on `gets`** — rejected: cheapest, but
   no arrow-key selection, no frame, and every terminal edge case becomes ours.

## Decision outcome

Chosen: **the TTY toolkit**.

1. `pastel` is the only way colour is applied; the renderer receives a
   `Pastel` instance so tests pass `Pastel.new(enabled: false)`.
2. `tty-box` draws the frame around the board; `tty-prompt` reads the player's
   choice; `tty-cursor` and `tty-screen` are available for in-place redraws.
3. Every use of these gems lives in `lib/tic_tac_toe/ui/` or
   `lib/tic_tac_toe/cli.rb` — never in the core (ADR-0001 §4).
4. **Explicit non-goal**: this does not choose a full-screen TUI (curses-style
   event loop). If the game outgrows redraw-on-prompt, that is a new ADR.

## Consequences

- **Good**: five small gems, all verified live; a renderer whose output is a
  string a spec can `include?`; a prompt the spec can double.
- **Bad / trade-off**: the toolkit's last releases are from 2023; if Ruby 4
  breaks one of them, the fix is upstream or a fork. Pinning Ruby 3.4 keeps
  that risk at zero today.
- **Neutral**: the frame width depends on terminal width detection
  (`tty-screen`); in a non-TTY (CI) it falls back to defaults.
- **Honest limitation**: nothing verifies the output *looks* good — that is
  what `/dogfood` and a human's eyes are for.

## More information

- Implemented in: the bootstrap commit's `lib/tic_tac_toe/ui/renderer.rb` and `lib/tic_tac_toe/cli.rb`
- Related: ADR-0001, `constitution/local-product.md`
- **Amendment 2026-08-29 (ticket #5, PR #11)** — narrows the input clause
  without changing the decision: a Cell is chosen with a single keypress
  `1`–`9` through `tty-prompt`'s keypress reader, not an arrow-key selection
  list. The context paragraph's "reacts to arrow keys" and option 3's "no
  arrow-key selection" describe the tracer bullet as it stood when this was
  written; the toolkit choice is unchanged (PRD #2, "Cell input").
