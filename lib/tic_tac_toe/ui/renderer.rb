# frozen_string_literal: true

require "pastel"
require "tty-box"

module TicTacToe
  module UI
    # Pure: Board in, String out. The only side effect allowed anywhere near
    # here is the caller printing the result.
    module Renderer
      GLYPH = { x: "X", o: "O" }.freeze
      COLOR = { x: :cyan, o: :magenta }.freeze

      def self.render(board, pastel: Pastel.new)
        divider = "\n#{pastel.dim('───┼───┼───')}\n"
        grid = board.rows.each_with_index.map do |row, r|
          row.each_with_index.map { |cell, c| glyph(cell, (r * Board::SIZE) + c, pastel) }
             .join(pastel.dim("│"))
        end.join(divider)

        TTY::Box.frame(grid, title: { top_left: " Tic Tac Toe " }, padding: [0, 2], border: :thick)
      end

      def self.glyph(cell, index, pastel)
        return pastel.dim(" #{index + 1} ") if cell.nil?

        pastel.decorate(" #{GLYPH.fetch(cell)} ", :bold, COLOR.fetch(cell))
      end

      # The question the shell asks the current Mark.
      def self.question(mark)
        "Where does #{GLYPH.fetch(mark)} go?"
      end

      # The line printed after the final frame. A plain case on the kind:
      # mutant 0.16 cannot mutate a `case … in` pattern match, and a crash
      # there aborts the whole run.
      def self.announcement(outcome)
        case outcome.kind
        when :won then "#{GLYPH.fetch(outcome.mark)} wins"
        when :draw then "Draw"
        end
      end
    end
  end
end
