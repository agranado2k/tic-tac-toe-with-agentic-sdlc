# frozen_string_literal: true

RSpec.describe TicTacToe::Outcome do
  def board_of(*moves)
    moves.reduce(TicTacToe::Board.empty) { |b, (index, mark)| b.place(index, mark).value! }
  end

  describe ".of" do
    it "is in_progress on an empty Board" do
      expect(described_class.of(TicTacToe::Board.empty)).to eq(described_class.in_progress)
    end

    it "is won by the Mark holding a complete Line" do
      board = board_of([0, :x], [3, :o], [1, :x], [4, :o], [2, :x])

      expect(described_class.of(board)).to eq(described_class.won(:x))
    end

    it "is a draw on a full Board with no Line" do
      board = board_of([0, :x], [1, :o], [2, :x], [4, :o], [3, :x], [5, :o], [7, :x], [6, :o], [8, :x])

      expect(described_class.of(board)).to eq(described_class.draw)
    end

    it "is won, not a draw, when the ninth Move completes a Line" do
      board = board_of([0, :x], [1, :o], [2, :x], [3, :o], [4, :x], [5, :o], [7, :x], [8, :o], [6, :x])

      expect(board).to be_full
      expect(described_class.of(board)).to eq(described_class.won(:x))
    end
  end

  describe "#terminal?" do
    it "is true for a win and a draw, false in progress" do
      expect(described_class.won(:o)).to be_terminal
      expect(described_class.draw).to be_terminal
      expect(described_class.in_progress).not_to be_terminal
    end
  end

  it "is frozen" do
    expect(described_class.won(:x)).to be_frozen
    expect(described_class.draw).to be_frozen
    expect(described_class.in_progress).to be_frozen
  end
end
