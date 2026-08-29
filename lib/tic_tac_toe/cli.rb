# frozen_string_literal: true

require "tty-cursor"
require "tty-prompt"

module TicTacToe
  # The imperative shell: the one place that prints and reads. Everything it
  # calls into is a pure function over immutable values.
  #
  # The Mode is chosen once, before the first frame. Hot seat: X and O
  # alternate at one keyboard. Versus computer: the human is X and the
  # Strategy plays O. Either way a human Move is one keypress, 1-9; a key that
  # is not a Cell and a Cell that is already taken both leave the Board alone
  # and ask again, saying why in the status line. One frame is drawn and then
  # repainted in place after every Move, so the terminal shows one game rather
  # than a log of frames.
  module CLI
    # Key "1" names Cell index 0 … key "9" names Cell index 8 — the same
    # numbers the Renderer draws on the empty Cells.
    CELL_KEYS = (1..Board::CELL_COUNT).map(&:to_s).freeze

    # The question a finished Game ends on.
    PLAY_AGAIN = "Play again?"

    # The Mode question, asked once per run. A yes/no, like "Play again?" —
    # this game's input is keys and answers, never a selection list
    # (ADR-0002's amendment, PRD #2 "Cell input").
    MODE_QUESTION = "Play against the computer?"
    HOT_SEAT = :hot_seat
    VERSUS_COMPUTER = :versus_computer

    # The Difficulty question, asked once per run and only where a Strategy
    # will play. Another yes/no, for the same reason the Mode question is one.
    DIFFICULTY_QUESTION = "Unbeatable computer?"
    EASY = :easy
    HARD = :hard

    # Versus the computer the human is X and opens, so the Strategy plays O
    # (PRD #2 user story 3).
    COMPUTER_MARK = :o

    # The beat between the human's Move and the computer's, so the repaint
    # reads as a Move rather than a flicker (PRD #2 user story 12).
    COMPUTER_PAUSE_SECONDS = 0.5
    PAUSE = ->(seconds) { sleep(seconds) }

    # The status a program ended by SIGINT reports: 128 plus the signal number.
    EXIT_INTERRUPTED = 130

    # A Replay is offered by a finished Game only, and asked exactly once. It
    # restarts with the settings this loop carries — the Mode and the
    # Difficulty, both chosen before the first Game and never asked again.
    def self.run(prompt: TTY::Prompt.new, out: $stdout, pause: PAUSE, random: ::Random.new)
      mode = ask_mode(prompt)
      strategy = computer_strategy(ask_difficulty(prompt, mode), random)

      loop do
        game = play_game(prompt, out, strategy, pause)
        break game unless game.outcome.terminal? && prompt.yes?(PLAY_AGAIN)
      end
    rescue Interrupt
      quit(out)
    end

    # The Mode this run plays in, as a name rather than the raw yes/no.
    def self.ask_mode(prompt)
      prompt.yes?(MODE_QUESTION) ? VERSUS_COMPUTER : HOT_SEAT
    end

    # The Difficulty this run plays at, or none in hot seat — where no Strategy
    # plays, so the question would be asking the player to choose between two
    # opponents they are not going to meet.
    def self.ask_difficulty(prompt, mode)
      return nil unless mode == VERSUS_COMPUTER

      prompt.yes?(DIFFICULTY_QUESTION) ? HARD : EASY
    end

    # The Strategy that plays the computer's Mark, by the Difficulty chosen for
    # it — and none where none was chosen, which is hot seat, where every Move
    # is a keypress. This is the whole of the loop's routing: nothing below
    # here knows which Strategy it is holding.
    def self.computer_strategy(difficulty, random)
      case difficulty
      when HARD then Strategy::Minimax.new
      when EASY then Strategy::Random.new(source: random)
      end
    end

    # Ctrl-C at any Prompt: leave the Frame exactly where it is — nothing is
    # rewound and nothing is announced — step off the line the terminal echoed
    # the key onto, and end the process the way a signalled program does.
    def self.quit(out)
      out.puts
      exit(EXIT_INTERRUPTED)
    end

    # One Game, drawn into a single frame that is repainted in place after
    # every Move, until the Outcome is terminal or the input stream closes.
    def self.play_game(prompt, out, strategy, pause)
      game = Game.new_game
      status = UI::Renderer.to_move(game.current_mark)
      frame = nil

      until game.outcome.terminal?
        frame = repaint(out, frame, game.board, status)
        move = next_move(game, strategy, prompt, pause)
        break if move.nil? # the input stream is closed: leave rather than re-ask forever

        game, status = move
      end

      finish(out, frame, game)
    end

    # The Game and status line after one Move by whoever is to move, or nil
    # when the human's input stream has closed.
    def self.next_move(game, strategy, prompt, pause)
      return computer_move(game, strategy, pause) if computer_to_move?(game, strategy)

      key = prompt.keypress
      return nil if key.nil?

      advance(game, key)
    end

    # The computer moves only where this run chose a Strategy, and only on its
    # own Mark.
    def self.computer_to_move?(game, strategy)
      !strategy.nil? && game.current_mark == COMPUTER_MARK
    end

    # The Strategy's Move, after the beat that makes the next repaint read as
    # a Move. The Strategy names an available Cell of an unfinished Game, so a
    # Failure here would be a bug in the Strategy rather than anything the
    # player did — it belongs raised, not shown in the status line.
    def self.computer_move(game, strategy, pause)
      pause.call(COMPUTER_PAUSE_SECONDS)
      cell = strategy.call(game.board, game.current_mark)

      [game.play(cell).value!, UI::Renderer.computer_plays(cell)]
    end

    # Only a finished Game has an announcement to repaint, so an abandoned one
    # (the input stream closed) keeps the frame it last drew instead of losing
    # its status line.
    def self.finish(out, frame, game)
      repaint(out, frame, game.board, UI::Renderer.announcement(game.outcome)) if game.outcome.terminal?
      game
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
