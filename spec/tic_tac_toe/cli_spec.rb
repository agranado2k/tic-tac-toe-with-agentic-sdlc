# frozen_string_literal: true

require "stringio"

RSpec.describe TicTacToe::CLI do
  let(:x_win) { [0, 3, 1, 4, 2] }
  let(:o_win) { [0, 3, 1, 4, 8, 5] }
  let(:draw) { [0, 1, 2, 4, 3, 5, 7, 6, 8] }

  describe ".run" do
    let(:prompt) { instance_double(TTY::Prompt) }
    let(:out) { StringIO.new }
    let(:per_page) { TicTacToe::Board::CELL_COUNT }

    def script(*cells)
      allow(prompt).to receive(:select).and_return(*cells)
    end

    it "plays a scripted X win in exactly five Moves and announces it" do
      script(*x_win)

      game = described_class.run(prompt: prompt, out: out)

      expect(prompt).to have_received(:select).exactly(5).times
      expect(out.string).to end_with("X wins\n")
      expect(game.outcome).to eq(TicTacToe::Outcome.won(:x))
    end

    it "plays a scripted O win and announces it" do
      script(*o_win)

      described_class.run(prompt: prompt, out: out)

      expect(prompt).to have_received(:select).exactly(6).times
      expect(out.string).to end_with("O wins\n")
    end

    it "plays a scripted draw in exactly nine Moves and announces it" do
      script(*draw)

      described_class.run(prompt: prompt, out: out)

      expect(prompt).to have_received(:select).exactly(9).times
      expect(out.string).to end_with("Draw\n")
    end

    it "asks the current Mark for a Cell, offering the empty Cells on one cycling page" do
      script(*x_win)

      described_class.run(prompt: prompt, out: out)

      expect(prompt).to have_received(:select)
        .with("Where does X go?", hash_including("Cell 1" => 0, "Cell 9" => 8), cycle: true, per_page: per_page).once
      expect(prompt).to have_received(:select)
        .with("Where does O go?", hash_including("Cell 9" => 8), cycle: true, per_page: per_page).twice
      expect(prompt).not_to have_received(:select).with("Where does O go?", hash_including("Cell 1" => 0), any_args)
    end

    it "renders the Board once before each Move and once after the last" do
      script(*x_win)

      described_class.run(prompt: prompt, out: out)

      boards = (0..x_win.size).map do |n|
        x_win.first(n).reduce(TicTacToe::Game.new_game) { |g, c| g.play(c).value! }.board
      end
      expect(out.string).to eq("#{boards.map { |b| TicTacToe::UI::Renderer.render(b) }.join}X wins\n")
    end

    it "builds its own prompt and writes to $stdout when given neither" do
      allow(TTY::Prompt).to receive(:new).and_return(prompt)
      script(*x_win)

      expect { described_class.run }.to output(/X wins/).to_stdout
    end
  end

  describe ".choices_for" do
    it "maps 1-based labels to 0-based cell indexes, empty cells only" do
      board = TicTacToe::Board.empty.place(1, :o).value!

      expect(described_class.choices_for(board)).to eq(
        "Cell 1" => 0, "Cell 3" => 2, "Cell 4" => 3, "Cell 5" => 4,
        "Cell 6" => 5, "Cell 7" => 6, "Cell 8" => 7, "Cell 9" => 8
      )
    end
  end
end
