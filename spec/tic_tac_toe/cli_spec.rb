# frozen_string_literal: true

require "stringio"

RSpec.describe TicTacToe::CLI do
  describe ".run" do
    it "renders, takes one move for X, and renders the result" do
      prompt = instance_double(TTY::Prompt)
      out = StringIO.new
      allow(prompt).to receive(:select).and_return(4)

      board = described_class.run(prompt: prompt, out: out)

      expect(board.cells).to eq([nil, nil, nil, nil, :x, nil, nil, nil, nil])
      expect(prompt).to have_received(:select)
        .with("Where does X go?", described_class.choices_for(TicTacToe::Board.empty), cycle: true, per_page: 9)

      first, second = out.string.split(/^(?=╔)/)
      expect(first).to include(" 5 ")
      expect(second).to include(" X ")
      expect(second).not_to include(" 5 ")
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
