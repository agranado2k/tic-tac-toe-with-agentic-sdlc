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

    it "draws the win frame exactly" do
      board = game_after(0, 3, 1, 4, 2).board
      status = described_class.announcement(TicTacToe::Outcome.of(board))

      expect(described_class.render(board, status: status, pastel: plain)).to eq(<<~BOARD)
        ╔ Tic Tac Toe ═════════════╗
        ║        X │ X │ X         ║
        ║       ───┼───┼───        ║
        ║        O │ O │ 6         ║
        ║       ───┼───┼───        ║
        ║        7 │ 8 │ 9         ║
        ║                          ║
        ║          X wins          ║
        ╚══════════════════════════╝
      BOARD
    end

    it "draws the draw frame exactly" do
      board = game_after(0, 1, 2, 4, 3, 5, 7, 6, 8).board
      status = described_class.announcement(TicTacToe::Outcome.of(board))

      expect(described_class.render(board, status: status, pastel: plain)).to eq(<<~BOARD)
        ╔ Tic Tac Toe ═════════════╗
        ║        X │ O │ X         ║
        ║       ───┼───┼───        ║
        ║        X │ O │ O         ║
        ║       ───┼───┼───        ║
        ║        O │ X │ X         ║
        ║                          ║
        ║           Draw           ║
        ╚══════════════════════════╝
      BOARD
    end

    it "renders the status line bold, padded to one width" do
      output = described_class.render(TicTacToe::Board.empty, status: "X wins", pastel: colour)

      expect(output).to include(colour.bold("X wins".center(described_class::STATUS_WIDTH)))
    end

    it "dims the cell separators and the row dividers" do
      output = described_class.render(TicTacToe::Board.empty, pastel: colour)

      expect(output).to include(colour.dim("│"))
      expect(output).to include(colour.dim("───┼───┼───"))
    end

    it "draws the status line inside the frame, under the grid" do
      expect(described_class.render(TicTacToe::Board.empty, status: "X to move", pastel: plain)).to eq(<<~BOARD)
        ╔ Tic Tac Toe ═════════════╗
        ║        1 │ 2 │ 3         ║
        ║       ───┼───┼───        ║
        ║        4 │ 5 │ 6         ║
        ║       ───┼───┼───        ║
        ║        7 │ 8 │ 9         ║
        ║                          ║
        ║        X to move         ║
        ╚══════════════════════════╝
      BOARD
    end

    it "renders without an injected Pastel" do
      output = described_class.render(TicTacToe::Board.empty.place(0, :x).value!)

      expect(output).to include(" X ").and include(" 2 ")
    end
  end

  describe ".to_move" do
    it "names the Mark whose go it is" do
      expect(described_class.to_move(:x)).to eq("X to move")
      expect(described_class.to_move(:o)).to eq("O to move")
    end
  end

  describe ".occupied" do
    it "names the Cell as the player sees it, 1-based" do
      expect(described_class.occupied(0)).to eq("Cell 1 is taken")
      expect(described_class.occupied(4)).to eq("Cell 5 is taken")
    end
  end

  describe "NOT_A_CELL" do
    it "tells the player which keys are Cells" do
      expect(described_class::NOT_A_CELL).to eq("Not a Cell — press 1–9")
    end
  end

  describe "STATUS_WIDTH" do
    it "is the length of the longest status the Renderer produces" do
      statuses = [
        described_class.to_move(:x), described_class.to_move(:o), described_class::NOT_A_CELL,
        *(0...TicTacToe::Board::CELL_COUNT).map { |cell| described_class.occupied(cell) },
        described_class.announcement(TicTacToe::Outcome.won(:x)),
        described_class.announcement(TicTacToe::Outcome.draw)
      ]

      expect(statuses.map(&:length).max).to eq(described_class::STATUS_WIDTH)
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
