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

    it "dims the cell separators and the row dividers" do
      output = described_class.render(TicTacToe::Board.empty, pastel: colour)

      expect(output).to include(colour.dim("│"))
      expect(output).to include(colour.dim("───┼───┼───"))
    end

    it "renders without an injected Pastel" do
      output = described_class.render(TicTacToe::Board.empty.place(0, :x).value!)

      expect(output).to include(" X ").and include(" 2 ")
    end
  end

  describe ".question" do
    it "asks where the current Mark goes" do
      expect(described_class.question(:x)).to eq("Where does X go?")
      expect(described_class.question(:o)).to eq("Where does O go?")
    end
  end

  describe ".announcement" do
    it "names the winning Mark" do
      expect(described_class.announcement(TicTacToe::Outcome.won(:x))).to eq("X wins")
      expect(described_class.announcement(TicTacToe::Outcome.won(:o))).to eq("O wins")
    end

    it "names the draw" do
      expect(described_class.announcement(TicTacToe::Outcome.draw)).to eq("Draw")
    end
  end

  describe ".glyph" do
    it "renders X bold cyan" do
      expect(described_class.glyph(:x, 0, colour)).to eq(colour.bold.cyan(" X "))
    end

    it "renders O bold magenta" do
      expect(described_class.glyph(:o, 0, colour)).to eq(colour.bold.magenta(" O "))
    end

    it "renders an empty cell as its dim 1-based number" do
      expect(described_class.glyph(nil, 8, colour)).to eq(colour.dim(" 9 "))
    end
  end
end
