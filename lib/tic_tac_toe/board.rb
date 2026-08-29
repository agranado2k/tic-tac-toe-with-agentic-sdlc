# frozen_string_literal: true

require "dry/monads"

module TicTacToe
  # A Board is an immutable value: nine Cells, each empty (nil) or holding a
  # Mark (:x or :o). Every operation returns a new Board or a Result; nothing
  # here mutates, prints, or reads input (ADR-0001).
  Board = Data.define(:cells)

  class Board
    include Dry::Monads[:result]

    SIZE = 3
    CELL_COUNT = SIZE * SIZE
    MARKS = %i[x o].freeze
    LINES = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], # rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], # columns
      [0, 4, 8], [2, 4, 6]             # diagonals
    ].freeze

    def self.empty
      new(cells: Array.new(CELL_COUNT, nil))
    end

    def initialize(cells:)
      super(cells: cells.dup.freeze)
    end

    # Success(Board) with the Mark placed, or Failure(:out_of_bounds |
    # :occupied | :invalid_mark).
    def place(index, mark)
      return Failure(:invalid_mark) unless MARKS.include?(mark)
      return Failure(:out_of_bounds) unless (0...CELL_COUNT).cover?(index)
      return Failure(:occupied) unless cells[index].nil?

      Success(with(cells: cells.dup.tap { |c| c[index] = mark }))
    end

    def available_cells
      cells.each_index.reject { |i| cells[i] }
    end

    def full?
      available_cells.empty?
    end

    # The Mark holding a complete Line, or nil.
    def winner
      LINES.each do |line|
        marks = line.map { |i| cells[i] }
        return marks.first if marks.first && marks.uniq.size == 1
      end
      nil
    end

    def rows
      cells.each_slice(SIZE).to_a
    end
  end
end
