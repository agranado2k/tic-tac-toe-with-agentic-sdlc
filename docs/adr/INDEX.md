# Architecture Decision Records

Each ADR captures **one** architectural decision for Tic Tac Toe, in
[MADR format](https://adr.github.io/madr/). The record is the contract; the
development chronology lives in `docs/diary.md`.

Copy `NNNN-template.md` to start a new one.

## Index

<!--
One row per ADR, in numeric order. The Status column carries the *live* status
plus the date it reached it, and any supersession/amendment note — so this table
alone answers "what is currently binding?" without opening 40 files.
-->

| # | Title | Status |
|---|---|---|
| 0001 | [Adopt a functional core with an imperative shell](0001-functional-core-imperative-shell.md) | Accepted 2026-08-29 |
| 0002 | [Adopt the TTY toolkit for terminal rendering and input](0002-tty-toolkit-for-the-terminal.md) | Accepted 2026-08-29 |

## Conventions

- **File name**: `NNNN-short-kebab-title.md`, zero-padded to four digits.
  Numbers are never reused, even for a rejected ADR.
- **Status values**: `Proposed` · `Accepted` · `Rejected` · `Deprecated` ·
  `Superseded by NNNN`.
- **The "Decision outcome" section is the contract.** Implementation detail and
  historical context go in `More information` at the bottom, kept short.
- **When a decision is reversed or revised, do NOT edit the old ADR.** Write a
  new one and set the old one's status to `Superseded by NNNN`. An amendment
  that only *narrows or clarifies* the same decision may be recorded in place,
  dated and labelled as an amendment — but a reversal never is.
- **Write the ADR when the decision is made**, not when the code lands. An ADR
  written after the fact documents a rationalization, not a decision.
- **One decision per record.** If the title needs an "and", it is two ADRs.

## Decisions recorded in the diary, not as ADRs

<!--
Some material decisions do not warrant a standalone record but are still binding
policy. List them here with a date, so "it is not in docs/adr/" never means "it
was never decided". If one grows consequential enough, promote it to an ADR and
leave a back-reference in the diary entry.
-->

- **2026-08-29** — Ctrl-C ends the run from the Shell: `CLI.run` rescues `Interrupt` once at its outer edge and exits with status 130; `bin/tic-tac-toe` stays a one-line call and the core is untouched (ADR-0001's split unchanged). Recorded in the diary entry "Ctrl-C quits quietly"; open question on PR #13 whether the `exit` should move to the binary.
- **2026-08-29** — Mutation testing with `mutant-rspec`, run on demand and never as a gate (shared invariant §9). Free for open source (`usage: opensource` in `.mutant.yml`); the repo is public. Recorded in the diary entry of that date.
