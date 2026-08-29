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
        TicTacToe::UI::Renderer.render(TicTacToe::Game.new_game.play(4).value!.board,
                                       status: TicTacToe::UI::Renderer.occupied(4))
      )
    end

    it "says which Mark is to move before each Move" do
      script("5", "2", "1", "3", "9")

      described_class.run(prompt: prompt, out: out)

      expect(out.string.scan(/[XO] to move/)).to eq(["X to move", "O to move", "X to move",
                                                     "O to move", "X to move"])
    end

    it "ends a scripted X win with the announcement in the status line" do
      script(*%w[1 4 2 5 3])

      game = described_class.run(prompt: prompt, out: out)

      expect(prompt).to have_received(:keypress).exactly(5).times
      expect(game.outcome).to eq(TicTacToe::Outcome.won(:x))
      expect(out.string).to end_with(
        TicTacToe::UI::Renderer.render(game.board, status: "X wins")
      )
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

    it "renders one frame per keypress and one for the announcement" do
      script(*%w[1 4 2 5 3])

      described_class.run(prompt: prompt, out: out)

      frames = (0..4).map do |n|
        game = %w[1 4 2 5 3].first(n).reduce(TicTacToe::Game.new_game) { |g, k| g.play(k.to_i - 1).value! }
        TicTacToe::UI::Renderer.render(game.board, status: TicTacToe::UI::Renderer.to_move(game.current_mark))
      end
      won = [0, 3, 1, 4, 2].reduce(TicTacToe::Game.new_game) { |g, c| g.play(c).value! }

      expect(out.string).to eq(frames.join + TicTacToe::UI::Renderer.render(won.board, status: "X wins"))
    end

    it "builds its own prompt and writes to $stdout when given neither" do
      allow(TTY::Prompt).to receive(:new).and_return(prompt)
      script(*%w[1 4 2 5 3])

      expect { described_class.run }.to output(/X wins/).to_stdout
    end
  end
end
