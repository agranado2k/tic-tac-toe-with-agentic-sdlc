# frozen_string_literal: true

require "tty-prompt"

module TicTacToe
  # The imperative shell: the one place that prints and reads. Everything it
  # calls into is a pure function over immutable values.
  #
  # Hot seat: X and O alternate at one keyboard until the Outcome is terminal.
  # A Move is one keypress, 1-9; a key that is not a Cell and a Cell that is
  # already taken both leave the Board alone and ask again, saying why in the
  # status line. The Board is printed after every Move; in-place redraw is a
  # later ticket.
  module CLI
    # Key "1" names Cell index 0 … key "9" names Cell index 8 — the same
    # numbers the Renderer draws on the empty Cells.
    CELL_KEYS = (1..Board::CELL_COUNT).map(&:to_s).freeze

    def self.run(prompt: TTY::Prompt.new, out: $stdout)
      game = Game.new_game
      status = UI::Renderer.to_move(game.current_mark)

      until game.outcome.terminal?
        out.puts UI::Renderer.render(game.board, status: status)
        game, status = advance(game, prompt.keypress)
      end

      out.puts UI::Renderer.render(game.board, status: UI::Renderer.announcement(game.outcome))
      game
    end

    # The Game and the status line after one keypress: the Move played and the
    # next Mark to move, or the Game untouched and the reason it was refused.
    def self.advance(game, key)
      cell = CELL_KEYS.index(key)
      return [game, UI::Renderer::NOT_A_CELL] if cell.nil?

      game.play(cell).either(
        ->(played) { [played, UI::Renderer.to_move(played.current_mark)] },
        ->(_reason) { [game, UI::Renderer.occupied(cell)] }
      )
    end
  end
end
