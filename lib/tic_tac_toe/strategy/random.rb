# frozen_string_literal: true

module TicTacToe
  # A Strategy is the function a computer opponent is: a Board and the Mark to
  # move in, the Cell it chooses out — a function of those two and of whatever
  # state was injected into it, never of anything global. Nothing here prints,
  # reads, or reaches for global randomness (ADR-0001).
  module Strategy
    # The easy opponent: any available Cell, uniformly. The random source is
    # injected — anything that responds like ::Random — so the Shell owns the
    # one piece of state a draw needs and a spec can seed it.
    Random = Data.define(:source)

    class Random
      # The Mark is part of the Strategy seam, not of this choice: which Mark
      # is to move cannot change a uniform draw. Precondition: the Board has at
      # least one available Cell — the Shell only asks a Strategy to move while
      # the Outcome is in progress, and a full Board is never that.
      def call(board, _mark)
        available = board.available_cells
        available.fetch(source.rand(available.length))
      end
    end
  end
end
