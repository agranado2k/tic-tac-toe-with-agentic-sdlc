# frozen_string_literal: true

RSpec.describe TicTacToe::Board do
  subject(:board) { described_class.empty }

  describe ".empty" do
    it "has nine free cells" do
      expect(board.available_cells).to eq((0..8).to_a)
    end

    it "is frozen" do
      expect(board).to be_frozen
      expect(board.cells).to be_frozen
    end
  end

  describe "#place" do
    it "returns a new board with the mark, leaving the original untouched" do
      result = board.place(4, :x)

      expect(result).to be_success
      expect(result.value!.cells[4]).to eq(:x)
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

  describe "#winner" do
    it "is nil on an empty board" do
      expect(board.winner).to be_nil
    end

    it "detects a completed row" do
      won = [0, 1, 2].reduce(board) { |b, i| b.place(i, :o).value! }

      expect(won.winner).to eq(:o)
    end

    it "detects a completed diagonal" do
      won = [0, 4, 8].reduce(board) { |b, i| b.place(i, :x).value! }

      expect(won.winner).to eq(:x)
    end
  end

  describe "#full?" do
    it "is true once every cell holds a mark" do
      full = (0..8).reduce(board) { |b, i| b.place(i, i.even? ? :x : :o).value! }

      expect(full).to be_full
    end
  end
end
