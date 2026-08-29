# frozen_string_literal: true

RSpec.describe TicTacToe::Board do
  subject(:board) { described_class.empty }

  def play(board, moves)
    moves.reduce(board) { |b, (index, mark)| b.place(index, mark).value! }
  end

  describe ".empty" do
    it "has nine empty cells" do
      expect(board.cells).to eq(Array.new(9, nil))
      expect(board.available_cells).to eq((0..8).to_a)
    end

    it "is frozen" do
      expect(board).to be_frozen
      expect(board.cells).to be_frozen
    end
  end

  describe ".new" do
    it "copies the cells it is given rather than freezing the caller's array" do
      cells = Array.new(9, nil)
      described_class.new(cells: cells)

      expect(cells).not_to be_frozen
    end
  end

  describe "#place" do
    it "returns a new board with the mark, leaving the original untouched" do
      result = board.place(4, :x)

      expect(result).to be_success
      expect(result.value!.cells).to eq([nil, nil, nil, nil, :x, nil, nil, nil, nil])
      expect(board.cells[4]).to be_nil
    end

    it "fails on an occupied cell" do
      taken = board.place(0, :x).value!

      expect(taken.place(0, :o)).to eq(Dry::Monads::Result::Failure.new(:occupied))
    end

    it "fails out of bounds" do
      expect(board.place(9, :x).failure).to eq(:out_of_bounds)
      expect(board.place(-1, :x).failure).to eq(:out_of_bounds)
    end

    it "fails on an unknown mark" do
      expect(board.place(0, :z).failure).to eq(:invalid_mark)
    end
  end

  describe "#available_cells" do
    it "lists exactly the empty cells, in order" do
      played = play(board, [[8, :x], [0, :o], [4, :x]])

      expect(played.available_cells).to eq([1, 2, 3, 5, 6, 7])
    end
  end

  describe "#rows" do
    it "slices the cells into three rows of three" do
      played = play(board, [[0, :x], [4, :o], [8, :x]])

      expect(played.rows).to eq([[:x, nil, nil], [nil, :o, nil], [nil, nil, :x]])
    end
  end

  describe "#winner" do
    it "is nil on an empty board" do
      expect(board.winner).to be_nil
    end

    it "is nil when a line holds mixed marks" do
      played = play(board, [[0, :x], [1, :x], [2, :o]])

      expect(played.winner).to be_nil
    end

    it "detects a completed row" do
      expect(play(board, [[0, :o], [1, :o], [2, :o]]).winner).to eq(:o)
    end

    it "detects a completed column" do
      expect(play(board, [[2, :x], [5, :x], [8, :x]]).winner).to eq(:x)
    end

    it "detects a completed diagonal" do
      expect(play(board, [[0, :x], [4, :x], [8, :x]]).winner).to eq(:x)
      expect(play(board, [[2, :o], [4, :o], [6, :o]]).winner).to eq(:o)
    end
  end

  describe "#full?" do
    it "is false while any cell is empty" do
      expect(board.full?).to be(false)
      expect(play(board, [[0, :x]]).full?).to be(false)
    end

    it "is true once every cell holds a mark" do
      full = play(board, (0..8).map { |i| [i, i.even? ? :x : :o] })

      expect(full.full?).to be(true)
    end
  end
end
