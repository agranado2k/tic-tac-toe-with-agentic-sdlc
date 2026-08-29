# frozen_string_literal: true

require "tty-prompt"

module TicTacToe
  # The imperative shell: the one place that prints and reads. Everything it
  # calls into is a pure function over immutable values.
  #
  # Hot seat: X and O alternate at one keyboard until the Outcome is terminal.
  # The Board is printed after every Move; in-place redraw is a later ticket.
  module CLI
    def self.run(prompt: TTY::Prompt.new, out: $stdout)
      game = Game.new_game
      out.puts UI::Renderer.render(game.board)

      until game.outcome.terminal?
        game = game.play(ask_for_cell(prompt, game)).value!
        out.puts UI::Renderer.render(game.board)
      end

      out.puts announcement(game.outcome)
      game
    end

    # The Prompt only offers empty Cells, so the Move it returns cannot fail.
    def self.ask_for_cell(prompt, game)
      prompt.select(question_for(game.current_mark), choices_for(game.board), cycle: true, per_page: Board::CELL_COUNT)
    end

    def self.question_for(mark)
      "Where does #{UI::Renderer::GLYPH.fetch(mark)} go?"
    end

    def self.choices_for(board)
      board.available_cells.to_h { |i| ["Cell #{i + 1}", i] }
    end

    # A plain case on the kind: mutant 0.16 cannot mutate a `case … in`
    # pattern match, and a crash there aborts the whole run.
    def self.announcement(outcome)
      case outcome.kind
      when :won then "#{UI::Renderer::GLYPH.fetch(outcome.mark)} wins"
      when :draw then "Draw"
      end
    end
  end
end
