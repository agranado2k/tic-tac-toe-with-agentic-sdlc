# frozen_string_literal: true

require "stringio"

RSpec.describe TicTacToe::CLI do
  describe ".run" do
    let(:prompt) { instance_double(TTY::Prompt) }
    let(:out) { StringIO.new }

    def script(*keys)
      allow(prompt).to receive(:keypress).and_return(*keys)
    end

    it "places the current Mark in the Cell the pressed number names" do
      script("5", "2", "1", "3", "9")

      game = described_class.run(prompt: prompt, out: out)

      expect(game.board.cells).to eq([:x, :o, :o, nil, :x, nil, nil, nil, :x])
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
      keys = %w[1 4 2 5 3]
      script(*keys)

      game = described_class.run(prompt: prompt, out: out)

      games = (0..keys.size).map { |n| game_after(*keys.first(n).map { |k| k.to_i - 1 }) }
      frames = games[0...-1].map do |g|
        TicTacToe::UI::Renderer.render(g.board, status: TicTacToe::UI::Renderer.to_move(g.current_mark))
      end
      expect(prompt).to have_received(:keypress).exactly(5).times
      expect(game.outcome).to eq(TicTacToe::Outcome.won(:x))
      expect(out.string).to eq(frames.join + TicTacToe::UI::Renderer.render(games.last.board, status: "X wins"))
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
