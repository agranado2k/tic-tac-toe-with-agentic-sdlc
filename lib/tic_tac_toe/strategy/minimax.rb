# frozen_string_literal: true

module TicTacToe
  module Strategy
    # The hard opponent: a full-depth search over the immutable Board that
    # never loses. Pure — no I/O, no randomness, no cache (ADR-0003).
    Minimax = Data.define

    class Minimax
      # A win is worth this much less the Moves it took to reach, so a win now
      # outranks the same win later and a forced loss is put off as long as it
      # can be. The slowest possible win fills the Board and still scores 1,
      # which keeps every win above a draw (ADR-0003 §3).
      WIN_SCORE = Board::CELL_COUNT + 1
      DRAW_SCORE = 0

      # Cells the search scores equal are separated by this fixed order — the
      # centre, then the four corners, then the four edges. It chooses only
      # among Cells already proved equally good, so it can never cost a Move;
      # it exists because every opening on an empty Board draws under perfect
      # play, and the centre is the one a player expects (ADR-0003 §4).
      PREFERENCE = [4, 0, 2, 6, 8, 1, 3, 5, 7].freeze

      # The best-scoring available Cell; among equals, the earliest in
      # PREFERENCE. The tie rule is spelled out in the sort key rather than
      # left to what `max_by` happens to return first.
      def call(board, mark)
        board.available_cells.min_by { |cell| [-move_score(board, mark, cell, 1), PREFERENCE.index(cell)] }
      end

      private

      # What playing `cell` is worth to `mark`: whatever the Board it leaves is
      # worth to the opponent, negated — their gain is this Mark's loss.
      def move_score(board, mark, cell, depth)
        -value(board.place(cell, mark).value!, Game::NEXT_MARK.fetch(mark), depth)
      end

      # What `board` is worth to `mark`, who is to move in it, `depth` Moves
      # below the Board the search started from. A Winner on a Board it is your
      # go in is always the opponent's: you are the one who did not stop it.
      def value(board, mark, depth)
        return depth - WIN_SCORE if board.winner
        return DRAW_SCORE if board.full?

        board.available_cells.map { |cell| move_score(board, mark, cell, depth + 1) }.max
      end
    end
  end
end
