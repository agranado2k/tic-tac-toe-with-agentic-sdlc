# frozen_string_literal: true

module TicTacToe
  # An Outcome is derived from a Board and never stored: won(mark), draw, or
  # in_progress. A value, so the shell and the specs can pattern-match on it.
  Outcome = Data.define(:kind, :mark)

  class Outcome
    KINDS = %i[won draw in_progress].freeze

    # The three constructors below are the intended entry points; an unknown
    # kind is a programming error, not an expected outcome.
    def initialize(kind:, mark:)
      raise ArgumentError, "unknown Outcome kind #{kind.inspect}" unless KINDS.include?(kind)

      super
    end

    def self.won(mark)
      new(kind: :won, mark: mark)
    end

    def self.draw
      new(kind: :draw, mark: nil)
    end

    def self.in_progress
      new(kind: :in_progress, mark: nil)
    end

    def self.of(board)
      winner = board.winner
      return won(winner) if winner
      return draw if board.full?

      in_progress
    end

    def terminal?
      kind != :in_progress
    end
  end
end
