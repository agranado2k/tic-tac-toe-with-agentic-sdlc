# frozen_string_literal: true

RSpec.describe TicTacToe::UI::Renderer do
  let(:plain) { Pastel.new(enabled: false) }
  let(:colour) { Pastel.new(enabled: true) }

  describe ".render" do
    it "draws the numbered, framed board exactly" do
      board = TicTacToe::Board.empty.place(4, :x).value!.place(0, :o).value!

      expect(described_class.render(board, pastel: plain)).to eq(<<~BOARD)
        ╔ Tic Tac Toe ══╗
        ║   O │ 2 │ 3   ║
        ║  ───┼───┼───  ║
        ║   4 │ X │ 6   ║
        ║  ───┼───┼───  ║
        ║   7 │ 8 │ 9   ║
        ╚═══════════════╝
      BOARD
    end

    it "needs no Pastel handed in (it auto-detects colour support)" do
      output = described_class.render(TicTacToe::Board.empty.place(0, :x).value!)

      expect(output).to include(" X ").and include(" 2 ")
    end
  end

  describe ".glyph" do
    it "renders X bold cyan and O bold magenta" do
      expect(described_class.glyph(:x, 0, colour)).to eq(colour.bold.cyan(" X "))
      expect(described_class.glyph(:o, 0, colour)).to eq(colour.bold.magenta(" O "))
    end

    it "renders an empty cell as its dim 1-based number" do
      expect(described_class.glyph(nil, 8, colour)).to eq(colour.dim(" 9 "))
    end
  end
end
