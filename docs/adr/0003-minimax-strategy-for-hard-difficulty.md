# ADR-0003: Adopt full-depth minimax as the hard Difficulty's Strategy

- **Status**: Accepted
- **Date**: 2026-08-29
- **Deciders**: Andre Granado (project owner), decided in the `/grill-me`
  session recorded in PRD #2, with Claude Code drafting
- **Supersedes / amends**: —
- **Superseded by**: —

## Context and problem statement

PRD #2 promises two computer opponents behind one Difficulty choice: an easy
one that is "genuinely winnable" and a hard one that is "genuinely unbeatable
and a draw is my best result" (user stories 18 and 19). The easy half landed
with ticket #7 as `Strategy::Random`, which picks uniformly among available
Cells and therefore misses wins and blocks — exactly what makes it easy, and
exactly what makes it useless as the hard opponent.

The hard opponent is the first piece of this game whose correctness is not
obvious from reading it. "Never loses" is a claim about every position the
player can reach, and a handful of examples cannot establish it: an opponent
that takes wins, blocks losses and opens on the centre still loses to the
standard double-corner fork. So the decision is not only *which algorithm*, but
*what evidence* the suite is required to produce — and both have to be settled
before the code lands, because they shape the same seam.

The seam itself is already fixed: ticket #7 established **Strategy** as a value
answering `#call(board, mark)` with the Cell it chooses, so whatever plays hard
plugs in beside Random with no change to the Shell's loop. What is open is what
goes behind it.

## Decision drivers

- **Correctness as a provable property, not a claim.** The evidence must be a
  statement over all reachable positions, checkable by the suite.
- **Simplicity.** 3×3 is small. An implementation that is obviously right beats
  a faster one that needs its own tests to be believed.
- **Purity** (ADR-0001). No I/O, no randomness, no mutable state, no cache: a
  function of the Board and the Mark to move, and nothing else.
- **Determinism.** Equal choices must resolve the same way every run, or no
  spec of the Strategy can be exact.
- **Purposeful play.** A player watching the computer must not see it dawdle on
  a win it could take now; that reads as a bug, not as strength.

## Considered options

1. **Full-depth minimax over the immutable Board, depth-aware scoring, no
   pruning and no memoisation** *(chosen)* — search every continuation to a
   terminal Board, score it by who wins and how soon, take the best Cell.
2. **Minimax with alpha-beta pruning** — rejected: it returns the same Cell
   values on a search that already finishes in milliseconds, so it buys nothing
   the drivers ask for, and it costs on two of them. Pruning interacts with the
   depth-aware scoring and with the tie-break — a cut-off branch is not merely
   unexplored, it is *reported* with a bound — so it needs tests that exist only
   to rule out a bug the simple version cannot have.
3. **Memoised minimax (a transposition table over the 5,478 reachable
   positions)** — rejected: a cache is mutable state, and mutable state in the
   functional core is what ADR-0001 exists to keep out. It would buy a
   millisecond on a search whose cost is already invisible to the player.
4. **A hand-written rule table** (the Newell–Simon ordering: win, block, fork,
   block the fork, centre, opposite corner, empty corner, empty side) —
   rejected: it is unbeatable only if every rule *and their order* is right, so
   correctness becomes a claim about a transcription rather than a property of a
   search. The never-loses property would then be testing whether the table was
   copied correctly, which is a much weaker thing to know.
5. **A precomputed lookup table** from every reachable position to its best Cell
   — rejected: it is minimax's own output, frozen. Producing it needs the search
   anyway, and it moves the source of truth from thirty readable lines into
   thousands of rows nobody reviews.

## Decision outcome

Chosen: **full-depth minimax, unpruned and unmemoised**.

1. `Strategy::Minimax` is a second implementation of the existing Strategy
   seam — `#call(board, mark)` answering a Cell index — and is a pure value:
   no I/O, no randomness, no global state, no cache. It composes the core it
   already has (`Board#place`, `Board#available_cells`, `Board#winner`,
   `Board#full?`, `Game::NEXT_MARK`) and adds nothing to `Board`.
2. The search is **full depth**: every continuation is explored to a Board that
   has a Winner or is full. There is no pruning, no depth limit, and no
   memoisation.
3. Scoring is **depth-aware**, from the perspective of the Mark to move: a win
   is worth `Board::CELL_COUNT + 1` minus the number of Moves it took, a loss
   is that negated, a draw is zero. A win in fewer Moves therefore outranks a
   slower one and a forced loss is put off as long as possible — this clause is
   the whole of "play looks purposeful", and it is the only reason the score is
   not a bare win/draw/loss.
4. Ties are broken by a **fixed Cell preference order — the centre, then the
   corners, then the edges** — applied only among Cells the search has already
   scored equal. It can never change *which* Cells are best, only which of
   several equally best is taken. It exists because every opening Move on an
   empty Board draws under perfect play, so without it the opening is decided by
   an arbitrary index; PRD #2 and ticket #8 both require the centre there.
5. **The enforcement is the exhaustive property, not the examples.** The suite
   plays Minimax as O against *every* reachable sequence of X Moves on the 3×3
   Board and asserts that no final Outcome is `won(:x)`. The example positions
   (takes an immediate win, blocks an immediate loss, opens on the centre,
   prefers the faster of two wins) stay as documentation of intent; they are not
   what makes the claim true.
6. **Explicit non-goal**: this decides nothing about Board sizes other than 3×3,
   about which Mark the human plays, or about a Difficulty between easy and hard
   — all three are out of scope in PRD #2. It also does not decide the Shell's
   Difficulty question, which is a wording choice, not an architecture one.

## Consequences

- **Good**: correctness is a property the suite proves over the whole reachable
  game rather than a claim over four examples; the implementation is around
  thirty lines with no tuning, no cache to invalidate and no bound to get wrong;
  it is a pure function of two values, so its specs need no doubles.
- **Bad / trade-off**: the search re-runs from scratch on every Move and walks
  the *game tree*, not the set of positions. 3×3 has 5,478 reachable positions
  but 255,168 complete games, so an unmemoised search from an empty Board visits
  roughly half a million nodes, each allocating a Board. That cost is paid by
  the suite (the empty-Board example and the exhaustive property are the two
  slowest things in it) and by mutation runs, never by the player: the computer
  plays O, so in the product it never searches more than eight empty Cells, and
  its answer arrives well inside the 0.5 s Pause the Shell already waits.
- **Neutral**: the tie-break makes the opening deterministic and therefore
  repetitive — hard always opens the same way against the same play. For an
  unbeatable opponent that is what "unbeatable" looks like; variety would have
  to come from randomness, which clause 1 rules out.
- **Honest limitation**: **this does not generalise past 3×3.** The whole
  argument for "no pruning, no memoisation, and an exhaustive property as the
  test" is that the game tree is small enough to walk twice — once by the
  Strategy and once by the suite. On 4×4 both the search and the property
  explode, and every rejected option above would have to be reconsidered. The
  property is also exhaustive over *X's* choices only: it fixes O's play as
  Minimax's own, which is the side the product needs and is not a claim about
  Minimax as X.

## More information

- Implemented in: ticket #8 (`lib/tic_tac_toe/strategy/minimax.rb`)
- Related: ADR-0001 (the purity this depends on), PRD #2 (user stories 18, 25
  and the Testing Decisions), `docs/domain-glossary.md` (Strategy, Difficulty)
