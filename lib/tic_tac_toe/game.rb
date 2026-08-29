# frozen_string_literal: true

require "dry/monads"

module TicTacToe
  # A Game is an immutable value: the Board and the current Mark — whose go it
  # is. Nothing here mutates, prints, or reads input (ADR-0001).
  Game = Data.define(:board, :current_mark)

  class Game
    include Dry::Monads[:result]

    # Each Mark hands the go to the next one in Board::MARKS, wrapping round.
    NEXT_MARK = Board::MARKS.zip(Board::MARKS.rotate).to_h.freeze

    def self.new_game
      new(board: Board.empty, current_mark: :x)
    end

    def outcome
      Outcome.of(board)
    end

    # Success(Game) with the current Mark placed and the other Mark current;
    # Failure(:game_over) on a finished Game, else Board#place's
    # Failure(:occupied | :out_of_bounds).
    def play(cell)
      return Failure(:game_over) if outcome.terminal?

      board.place(cell, current_mark).fmap do |placed|
        with(board: placed, current_mark: NEXT_MARK.fetch(current_mark))
      end
    end
  end
end
