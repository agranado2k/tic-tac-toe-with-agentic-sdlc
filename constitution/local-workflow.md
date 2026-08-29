# Local workflow — commits, merges, review, docs, the log

Project-specific elaboration of the root `AGENTS.md`'s process rules. The root
carries the binding one-liners; this article carries the detail you need when
you are actually doing the thing.

## Commits

Conventional Commits. The root states the format; this is the practice around it.

- Type is one of `feat` `fix` `docs` `style` `refactor` `perf` `test` `build`
  `ci` `chore` `revert`, optionally `(scope)`, then `: `, then a subject ≤100
  characters.
- Release mapping: `feat` → minor, `fix`/`perf` → patch, `BREAKING CHANGE:` in
  the body → major.
- **Enforcement**: none locally yet. The CI twin ships disabled as
  `.github/workflows/commitlint.yml.example`; rename it to turn it on.
- **Curate your commits before opening the PR** so the landed history reads
  cleanly. A "fix typo" or "address review" commit gets squashed locally first.
- **Refactor-only and behavior-changing work never share a commit**
  (`shared-invariants.md` §10). Not checked by tooling: `scripts/behavior-delta.sh`
  lists the contract surfaces a diff touched, and the reviewer does the rest.

## Merging to `main`

- **Method**: squash and merge, via the GitHub button. GitHub signs the squash
  commit, so the signed-commit history on `main` stays intact.
- **Rejected**: rebase and merge — it rewrites every commit, which drops the
  author's GPG signature.
- **The merge action is human** (shared invariant §7). No agent, bot, or
  automation lands a change. An agent brings a PR to one click away and stops —
  `/pr-iterate` drives a PR to green and explicitly never merges. When you have
  decided a batch should land, `/merge-train` is you delegating the *mechanics*
  of that decision, never the decision.
- Branch protection / required checks: not configured on the forge yet. The
  checks that should be required are `.github/workflows/docs-gate.yml`,
  `.github/workflows/tdd-pairing.yml`, and `.github/workflows/ruby.yml`.
- After a batch lands, `/worktree-cleanup` prunes the merged worktrees and
  fast-forwards the root checkout.

## Before you push

1. `scripts/check.sh` — the docs gate. `.githooks/pre-push` runs it for you.
2. `scripts/tdd-pairing-guard.sh` — the same hook runs it: a change under
   `lib/` with no change under `spec/` is blocked. `bundle exec rubocop` and
   `bundle exec rspec` are run by hand before pushing; the hook does not run
   them, CI does.
3. CI re-runs the same checks: the docs gate, the pairing guard, and
   `.github/workflows/ruby.yml` (RuboCop + RSpec).

### The docs-trigger matrix

The mapping from "what you changed" to "what must change with it". This table is
the executable form of documentation-as-contract: if a row is not enforced by a
check, say so in the row rather than pretending.

| When you change… | You must also update… |
| --- | --- |
| `Gemfile` (a dependency added or removed) | the stack section of `constitution/local-engineering.md`, and an ADR when the gem shapes the architecture. Not enforced by a check |
| `lib/tic_tac_toe/` (a new domain concept) | `docs/domain-glossary.md`, in the same change. Not enforced by a check |
| A skill, hook, or command | the root `AGENTS.md` (or the article that owns the rule) |
| `scripts/agents.config.sh` (a tier's model, or your provider) | the tier rubric below, if the change means a tier's cost/benefit shape moved rather than just its identifier |
| Any manual layer (root, article, or nested) | the other layers, so one home per rule survives: a root rule that grew gets its own article; an article rule that became binding gets promoted to the root. Never leave the same rule in two homes |
| `constitution/shared-invariants.md` | **nothing here** — it is shared layer. A local exception goes in *this* article; the shared copy stays byte-identical to the kit's |

## Capability tiers — the cost/benefit call

The root `AGENTS.md` names the four tiers (`planner`, `implementer`,
`mechanical`, `reviewer`) and where the mapping lives. This is the practice
around them.

**The decision is made at ticket-writing time, by the planner, in the open.**
Not at spawn time, and never by an agent about its own session — an agent asked
to size itself has no view of the wave's total budget and every incentive to say
"the strongest one". `/to-tickets` stamps a tier on every ticket and surfaces
the whole set at its quiz step, which is where a human overrides it.

The rubric, in the order to ask it:

1. **Is the definition of done checkable without judgement?** A rename, a
   codemod, a dependency bump, a mechanical migration of call sites — the suite
   is the oracle. ⇒ `mechanical`. This is the one that saves real money, because
   it is also the most common ticket in an expand–migrate–contract wave.
2. **Does the ticket's outcome constrain other tickets?** Decomposition, a
   design decision, a schema, an interface everything else builds against. A
   wrong answer is paid for by every downstream session, not just this one.
   ⇒ `planner`.
3. **Is the deliverable a verdict on a diff rather than the diff?** Fresh-context
   adversarial reading, the standards axis of a review. ⇒ `reviewer`.
4. **Otherwise** ⇒ `implementer`. This is the default, and defaulting is correct:
   an unsure planner picking the cheap tier turns a saving into a re-run, and a
   re-run costs more than the tier ever saved.

Two rules that keep the rubric honest:

- **Ambiguity resolves upward**, the opposite direction from the autonomy label
  (which resolves to human-in-the-loop). Under-tiering is silent — you get a
  plausible wrong diff — while over-tiering only costs money, and cost is
  visible.
- **A tier is not a permission.** It says which model runs the work, never how
  much autonomy the work carries. The `ready-for-agent` label is the only thing
  that says that, and a `mechanical` ticket with no label still stops for a
  human.

The mapping lives in `scripts/agents.config.sh` and uses the short model names
the Claude Code `Agent` tool accepts. An unmapped tier is a working state: the
spawn inherits the session's own model and the resolver warns once.

## Review

- **Two axes, never merged** (shared invariant §5). Standards findings are
  verifiable from the diff and may be fixed autonomously by an agent; behavior
  findings are not decidable from the diff and go to a human as an explicit
  confirm-list. Never let a behavior question ride into an autonomous fix loop
  dressed as a standards nit. `/review-pr` is that split, executable: its §5
  severity report is axis one, its §5b confirm-list is axis two, and
  `scripts/behavior-delta.sh` supplies the grounded candidate list for the
  second from the contract artifacts named in `scripts/guards.config.sh`.
- **Automated review**: none wired yet; `.github/workflows/ai-review.example.yml`
  is inert until it is renamed and given a provider secret. Bot review is
  advisory, never binding. With nothing wired, `/implement` falls back to an
  in-harness `/review-pr` subagent on the `reviewer` tier — same review,
  narrower reach.
- **Fresh context per phase** (shared invariant §4): the reviewer must not see
  the implementation history. A reviewer who has read the author's narrative
  reviews the narrative instead of the diff.

## Decision records

Decisions live in `docs/adr/`, one file per decision, indexed by
`docs/adr/INDEX.md`, which is updated in the same change.

- When a decision is reversed, **do not edit the old record**: write a new one
  and mark the old one superseded.
- **Decision content never goes in the log.** The log is chronological; it may
  reference a decision by number but is never the source of truth for one.

## The log

Append a dated entry to `docs/diary.md` when **you** finish work that materially
changes state:

- A milestone reached, a decision recorded or reversed, a dependency or vendor
  changed.
- Infrastructure applied — record the environment and a summary of the diff.
- A structural change to the agent manual itself, this article layer included.

Never edit old entries. If the log contradicts the specification, the
specification wins — flag the contradiction in your new entry rather than
quietly rewriting history.
