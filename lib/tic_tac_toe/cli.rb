# frozen_string_literal: true

require "tty-prompt"

module TicTacToe
  # The imperative shell: the one place that prints and reads. Everything it
  # calls into is a pure function over immutable values.
  #
  # Tracer bullet: render the empty Board, take one Move for X, render again.
  # The full game loop arrives through the spec -> tickets -> /implement chain.
  module CLI
    def self.run(prompt: TTY::Prompt.new, out: $stdout)
      board = Board.empty
      out.puts UI::Renderer.render(board)

      index = prompt.select("Where does X go?", choices_for(board), cycle: true, per_page: Board::CELL_COUNT)
      board = board.place(index, :x).value!

      out.puts UI::Renderer.render(board)
      board
    end

    def self.choices_for(board)
      board.available_cells.to_h { |i| ["Cell #{i + 1}", i] }
    end
  end
end
