# frozen_string_literal: true

RSpec.describe TicTacToe::Strategy::Random do
  # `Random` below is Ruby's own — the random source being injected — not the
  # Strategy under test.
  def seeded(seed)
    described_class.new(source: Random.new(seed))
  end

  # Every Board reachable by playing the given Cells in order, X first.
  def boards_after(*cells)
    (0..cells.size).map { |n| game_after(*cells.first(n)).board }
  end

  describe "#call" do
    it "picks a Cell that is available on the Board" do
      board = TicTacToe::Board.empty

      expect(board.available_cells).to include(seeded(1).call(board, :o))
    end

    it "picks the same Cell twice from equal seeds" do
      board = TicTacToe::Board.empty

      expect(seeded(7).call(board, :o)).to eq(seeded(7).call(board, :o))
    end

    it "never picks an occupied Cell, on any Board along a played-out Game" do
      boards_after(4, 0, 8, 2, 1, 7, 3).each do |board|
        next if board.full?

        20.times do |seed|
          expect(board.available_cells).to include(seeded(seed).call(board, :o))
        end
      end
    end

    it "picks the one empty Cell when only one is left" do
      board = game_after(0, 1, 2, 4, 3, 5, 7, 6).board

      expect(seeded(3).call(board, :x)).to eq(8)
    end

    it "spreads its draws across the available Cells" do
      board = TicTacToe::Board.empty
      picks = (0...200).map { |seed| seeded(seed).call(board, :o) }

      expect(picks.uniq.sort).to eq(board.available_cells)
    end
  end

  it "is a frozen value" do
    expect(seeded(1)).to be_frozen
  end
end
