# frozen_string_literal: true

require "stringio"
require "tty-cursor"

RSpec.describe TicTacToe::CLI do
  describe ".run" do
    let(:prompt) { instance_double(TTY::Prompt) }
    let(:out) { StringIO.new }

    before { allow(prompt).to receive(:yes?).and_return(false) }

    def script(*keys)
      allow(prompt).to receive(:keypress).and_return(*keys)
    end

    # The keys of one scripted X win, and the frames it draws: one per Move,
    # then the announcement.
    def x_win_keys
      %w[1 4 2 5 3]
    end

    def x_win_games
      (0..x_win_keys.size).map { |n| game_after(*x_win_keys.first(n).map { |k| k.to_i - 1 }) }
    end

    def x_win_frames
      renderer = TicTacToe::UI::Renderer
      games = x_win_games
      asking = games[0...-1].map { |g| renderer.render(g.board, status: renderer.to_move(g.current_mark)) }
      asking + [renderer.render(games.last.board, status: "X wins")]
    end

    # The bytes that put the cursor back at the top-left of a frame just
    # written and clear from there down, so the next frame lands on top of it.
    def rewind_over(frame)
      TTY::Cursor.up(frame.lines.count) + TTY::Cursor.column(1) + TTY::Cursor.clear_screen_down
    end

    # The byte stream of a sequence of frames all drawn in one place: the first
    # printed, every one after it preceded by a rewind over its predecessor.
    def in_place(frames)
      frames.each_cons(2).map { |previous, frame| rewind_over(previous) + frame }.unshift(frames.first).join
    end

    it "repaints in place: the frame after the first is preceded by a rewind over it" do
      script("5", nil)

      described_class.run(prompt: prompt, out: out)

      first = TicTacToe::UI::Renderer.render(TicTacToe::Board.empty, status: "X to move")
      second = TicTacToe::UI::Renderer.render(game_after(4).board, status: "O to move")
      expect(out.string).to eq(in_place([first, second]))
    end

    it "places the current Mark in the Cell the pressed number names" do
      script("5", "2", "1", "3", "9")

      game = described_class.run(prompt: prompt, out: out)

      expect(game.board.cells).to eq([:x, :o, :o, nil, :x, nil, nil, nil, :x])
    end

    it "repaints a re-ask in place, over the frame that asked for the key" do
      script("q", "5", nil)

      described_class.run(prompt: prompt, out: out)

      renderer = TicTacToe::UI::Renderer
      asking = renderer.render(TicTacToe::Board.empty, status: renderer.to_move(:x))
      refused = renderer.render(TicTacToe::Board.empty, status: renderer::NOT_A_CELL)
      played = renderer.render(game_after(4).board, status: renderer.to_move(:o))
      expect(out.string).to eq(in_place([asking, refused, played]))
    end

    it "re-asks with a status when the key is not a Cell, leaving the Board alone" do
      script("q", "5", "2", "1", "3", "9")

      described_class.run(prompt: prompt, out: out)

      expect(prompt).to have_received(:keypress).exactly(6).times
      expect(out.string).to include(
        TicTacToe::UI::Renderer.render(TicTacToe::Board.empty, status: TicTacToe::UI::Renderer::NOT_A_CELL)
      )
    end

    it "re-asks with a status naming the taken Cell, leaving the Board alone" do
      script("5", "5", "2", "1", "3", "9")

      described_class.run(prompt: prompt, out: out)

      expect(prompt).to have_received(:keypress).exactly(6).times
      expect(out.string).to include(
        TicTacToe::UI::Renderer.render(game_after(4).board, status: TicTacToe::UI::Renderer.occupied(4))
      )
    end

    it "says which Mark is to move before each Move" do
      script("5", "2", "1", "3", "9")

      described_class.run(prompt: prompt, out: out)

      expect(out.string.scan(/[XO] to move/)).to eq(["X to move", "O to move", "X to move",
                                                     "O to move", "X to move"])
    end

    it "ends a scripted O win with the announcement in the status line" do
      script(*%w[1 4 2 5 9 6])

      game = described_class.run(prompt: prompt, out: out)

      expect(prompt).to have_received(:keypress).exactly(6).times
      expect(out.string).to end_with(
        TicTacToe::UI::Renderer.render(game.board, status: "O wins")
      )
    end

    it "ends a scripted draw with the announcement in the status line" do
      script(*%w[1 2 3 5 4 6 8 7 9])

      game = described_class.run(prompt: prompt, out: out)

      expect(prompt).to have_received(:keypress).exactly(9).times
      expect(out.string).to end_with(
        TicTacToe::UI::Renderer.render(game.board, status: "Draw")
      )
    end

    it "plays a scripted X win in five keypresses, one frame each plus the announcement" do
      script(*x_win_keys)

      game = described_class.run(prompt: prompt, out: out)

      expect(prompt).to have_received(:keypress).exactly(5).times
      expect(game.outcome).to eq(TicTacToe::Outcome.won(:x))
      expect(out.string).to eq(in_place(x_win_frames))
    end

    it "offers Play again? after a finished Game, and returns when the answer is no" do
      script(*x_win_keys)

      game = described_class.run(prompt: prompt, out: out)

      expect(prompt).to have_received(:yes?).with("Play again?").once
      expect(game.outcome).to eq(TicTacToe::Outcome.won(:x))
      expect(out.string).to end_with(x_win_frames.last)
    end

    it "plays a fresh Game below the last frame when the answer is yes, and asks again after it" do
      script(*(x_win_keys * 2))
      allow(prompt).to receive(:yes?).and_return(true, false)

      game = described_class.run(prompt: prompt, out: out)

      expect(prompt).to have_received(:keypress).exactly(10).times
      expect(prompt).to have_received(:yes?).twice
      expect(game).to eq(game_after(0, 3, 1, 4, 2))
      expect(out.string).to eq(in_place(x_win_frames) * 2)
    end

    it "does not offer Play again? for a Game abandoned when the input stream closed" do
      script("5", nil)

      described_class.run(prompt: prompt, out: out)

      expect(prompt).not_to have_received(:yes?)
    end

    it "leaves when the input stream is closed instead of re-asking forever" do
      script("5", nil)

      game = described_class.run(prompt: prompt, out: out)

      expect(prompt).to have_received(:keypress).exactly(2).times
      expect(game).to eq(game_after(4))
      expect(game.outcome).not_to be_terminal
    end

    it "builds its own prompt and writes to $stdout when given neither" do
      allow(TTY::Prompt).to receive(:new).and_return(prompt)
      script(*%w[1 4 2 5 3])

      expect { described_class.run }.to output(/X wins/).to_stdout
    end
  end

  describe ".advance" do
    let(:won) { game_after(0, 3, 1, 4, 2) }

    it "plays the Cell the key names and says who is to move next" do
      game, status = described_class.advance(TicTacToe::Game.new_game, "5")

      expect(game).to eq(game_after(4))
      expect(status).to eq("O to move")
    end

    it "refuses a key that is not a Cell, leaving the Game untouched" do
      game, status = described_class.advance(TicTacToe::Game.new_game, "q")

      expect(game).to eq(TicTacToe::Game.new_game)
      expect(status).to eq(TicTacToe::UI::Renderer::NOT_A_CELL)
    end

    it "refuses a taken Cell, naming it" do
      game, status = described_class.advance(game_after(4), "5")

      expect(game).to eq(game_after(4))
      expect(status).to eq("Cell 5 is taken")
    end

    it "refuses a Move on a finished Game with the announcement, not a taken-Cell message" do
      game, status = described_class.advance(won, "9")

      expect(game).to eq(won)
      expect(status).to eq("X wins")
    end
  end
end
