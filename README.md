# Tic Tac Toe

A functional-style tic-tac-toe game for the terminal, written in Ruby.

Immutable `Data.define` values and `Dry::Monads::Result` in the core, the
[TTY toolkit](https://ttytoolkit.org) (`tty-prompt`, `pastel`, `tty-box`) in a
thin shell that is the only code allowed to print or read. The reasoning is in
`docs/adr/`.

## Getting started

```sh
# Ruby, as pinned in .ruby-version (rbenv reads the file)
rbenv install
bundle install

# Play
bundle exec bin/tic-tac-toe

# Check
bundle exec rspec
bundle exec rubocop
bundle exec mutant run   # mutation testing, on demand

# Clone-time wiring: the git hooks. Hook path is per-clone config and cannot
# be committed, so every collaborator runs this once.
git config core.hooksPath .githooks

# The docs gate. Runs automatically before every push.
sh scripts/check.sh
```

What exists today is a hot-seat game: X and O alternate at one keyboard, a Move
is one keypress `1`–`9`, and a status line inside the frame says who is to move,
why a key was refused, and who won. A computer opponent and redraw-in-place
arrive through the chain described below.

## How this repo is run

This project is built with an **agent-first SDLC**: a written spec before code,
vertical slices, tests as the specification, a fresh context per phase, and a
human merge gate. The rules are in the repo, not in anyone's head.

| Path | What it is |
| --- | --- |
| `AGENTS.md` | The agent operating manual. Loaded into **every** agent session, so it is deliberately short. Yours to edit. |
| `CLAUDE.md`, `GEMINI.md` | Shims — one import line each, pointing at `AGENTS.md` so a tool that looks for its own filename finds the same manual. Never edit them. |
| `constitution/shared-invariants.md` | The portable rulebook — the invariants that hold regardless of stack, domain, or vendor. **Shared layer:** copied verbatim, not edited here. |
| `docs/diary.md` | The development diary. The **Current state** block at the top is the orientation document — read it first when picking the project up. |
| `docs/adr/` | Architecture Decision Records (MADR). `INDEX.md` lists what is currently binding; `NNNN-template.md` starts a new one. |
| `docs/domain-glossary.md` | The ubiquitous language. One name per concept, used in code and in conversation. |
| `.github/PULL_REQUEST_TEMPLATE.md` | The PR checklist, including the human confirm-list for behavior findings. |
| `scripts/check.sh` | The docs gate — fails when the docs and the repo stop describing the same thing. |
| `.githooks/pre-push` | Runs the gate before every push, with a loud, logged bypass. |
| `VERSION` | Which release of the shared layer this repo took. |
| `UPDATING.md` | How to move the shared layer forward when the kit does. |

## The shared layer

Almost everything here is **yours** — this README, `AGENTS.md`, the docs, the
code. A small part is not: the files listed under `files:` in `VERSION` are the
**shared layer**, copied verbatim from the
[agentic-sdlc](https://github.com/agranado2k/agentic-sdlc) kit and deliberately
not edited downstream. They name no product, no command, and no vendor, which is
exactly what makes them copyable at all.

A local exception to a shared rule does **not** get edited into the shared file.
It goes in a local article, and the shared copy stays byte-identical — otherwise
the next update becomes an archaeology exercise instead of a diff.

See `UPDATING.md` for the update recipe.

## The gate

A process rule that nothing checks decays into a lie, and a stale standing
instruction is worse than an absent one — every agent session loads it. So the
rules here are executable or CI-verified rather than merely written down.

`sh scripts/check.sh` is this repo's docs gate. It runs on `git push` via
`.githooks/pre-push`; `PUSH_WITHOUT_DOCS=1 git push` is the documented,
warning-printing escape hatch.
