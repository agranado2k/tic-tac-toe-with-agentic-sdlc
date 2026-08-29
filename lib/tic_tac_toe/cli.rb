# frozen_string_literal: true

require "tty-cursor"
require "tty-prompt"

module TicTacToe
  # The imperative shell: the one place that prints and reads. Everything it
  # calls into is a pure function over immutable values.
  #
  # Hot seat: X and O alternate at one keyboard until the Outcome is terminal.
  # A Move is one keypress, 1-9; a key that is not a Cell and a Cell that is
  # already taken both leave the Board alone and ask again, saying why in the
  # status line. One frame is drawn and then repainted in place after every
  # Move, so the terminal shows one game rather than a log of frames.
  module CLI
    # Key "1" names Cell index 0 … key "9" names Cell index 8 — the same
    # numbers the Renderer draws on the empty Cells.
    CELL_KEYS = (1..Board::CELL_COUNT).map(&:to_s).freeze

    def self.run(prompt: TTY::Prompt.new, out: $stdout)
      play_game(prompt, out)
    end

    # One Game, drawn into a single frame that is repainted in place after
    # every Move, until the Outcome is terminal or the input stream closes.
    def self.play_game(prompt, out)
      game = Game.new_game
      status = UI::Renderer.to_move(game.current_mark)
      frame = nil

      until game.outcome.terminal?
        frame = repaint(out, frame, game.board, status)
        key = prompt.keypress
        break if key.nil? # the input stream is closed: leave rather than re-ask forever

        game, status = advance(game, key)
      end

      game.tap { announce(out, frame, game) }
    end

    # The last repaint of a finished Game: the announcement in its status line.
    # Only a finished Game has one, so an abandoned Game (the input stream
    # closed) keeps the frame it last drew instead of losing its status line.
    def self.announce(out, frame, game)
      return unless game.outcome.terminal?

      repaint(out, frame, game.board, UI::Renderer.announcement(game.outcome))
    end

    # Draw one frame where the previous one is, and answer with it: the first
    # frame of a Game is printed, every frame after it lands on top of its
    # predecessor. Returns the frame now on screen.
    def self.repaint(out, previous, board, status)
      out.print(rewind_over(previous)) if previous
      frame = UI::Renderer.render(board, status: status)
      out.print(frame)
      frame
    end

    # The cursor sequence that returns to the top-left of a frame already on
    # screen and clears from there down. The column is set explicitly because
    # the Prompt may have left the cursor anywhere on the line below.
    def self.rewind_over(frame)
      TTY::Cursor.up(frame.lines.count) + TTY::Cursor.column(1) + TTY::Cursor.clear_screen_down
    end

    # The Game and the status line after one keypress: the Move played and the
    # next Mark to move, or the Game untouched and the reason it was refused.
    def self.advance(game, key)
      cell = CELL_KEYS.index(key)
      return [game, UI::Renderer::NOT_A_CELL] if cell.nil?

      game.play(cell).either(
        ->(played) { [played, UI::Renderer.to_move(played.current_mark)] },
        ->(reason) { [game, refusal(game, cell, reason)] }
      )
    end

    # The status line for a refused Move, by the reason the Game gave.
    def self.refusal(game, cell, reason)
      case reason
      when :occupied then UI::Renderer.occupied(cell)
      when :game_over then UI::Renderer.announcement(game.outcome)
      else UI::Renderer::NOT_A_CELL # :out_of_bounds — the key named no Cell
      end
    end
  end
end
