# frozen_string_literal: true

require "stringio"

RSpec.describe TicTacToe::CLI do
  describe ".run" do
    let(:prompt) { instance_double(TTY::Prompt, select: 4) }
    let(:out) { StringIO.new }

    it "places X in the chosen cell" do
      board = described_class.run(prompt: prompt, out: out)

      expect(board.cells).to eq([nil, nil, nil, nil, :x, nil, nil, nil, nil])
    end

    it "offers the empty cells to the prompt on one cycling page" do
      described_class.run(prompt: prompt, out: out)

      expect(prompt).to have_received(:select)
        .with("Where does X go?", hash_including("Cell 1" => 0, "Cell 9" => 8),
              cycle: true, per_page: TicTacToe::Board::CELL_COUNT)
    end

    it "renders the board exactly twice: before and after the move" do
      described_class.run(prompt: prompt, out: out)

      render = TicTacToe::UI::Renderer.method(:render)
      expect(out.string).to eq(render[TicTacToe::Board.empty] + render[TicTacToe::Board.empty.place(4, :x).value!])
    end

    it "builds its own prompt and writes to $stdout when given neither" do
      allow(TTY::Prompt).to receive(:new).and_return(prompt)

      board = nil
      expect { board = described_class.run }.to output(/Tic Tac Toe/).to_stdout
      expect(board.cells[4]).to eq(:x)
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
