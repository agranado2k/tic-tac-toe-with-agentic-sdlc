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

      # Every status is padded to the width of the longest one, so a re-ask
      # never resizes the frame between Moves.
      NOT_A_CELL = "Not a Cell — press 1–9"
      STATUS_WIDTH = NOT_A_CELL.length

      # `status` is the status line — one message drawn inside the frame under
      # the Board. Omitting it draws the bare Board.
      def self.render(board, status: nil, pastel: Pastel.new)
        content = [grid(board, pastel)]
        content += ["", pastel.bold(status.center(STATUS_WIDTH))] if status

        TTY::Box.frame(content.join("\n"),
                       title: { top_left: " Tic Tac Toe " }, padding: [0, 2],
                       border: :thick, align: :center)
      end

      def self.grid(board, pastel)
        divider = "\n#{pastel.dim('───┼───┼───')}\n"
        board.rows.each_with_index.map do |row, r|
          row.each_with_index.map { |cell, c| glyph(cell, (r * Board::SIZE) + c, pastel) }
             .join(pastel.dim("│"))
        end.join(divider)
      end

      def self.glyph(cell, index, pastel)
        return pastel.dim(" #{index + 1} ") if cell.nil?

        pastel.decorate(" #{GLYPH.fetch(cell)} ", :bold, COLOR.fetch(cell))
      end

      # The status line while the Game is in progress.
      def self.to_move(mark)
        "#{GLYPH.fetch(mark)} to move"
      end

      # The status line refusing a Move onto a Cell that already holds a Mark.
      # The Cell is named as the player sees it, 1-based.
      def self.occupied(cell)
        "Cell #{cell + 1} is taken"
      end

      # The status line of a finished Game. A plain case on the kind:
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
