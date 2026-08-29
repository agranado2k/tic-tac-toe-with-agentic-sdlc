# frozen_string_literal: true

RSpec.describe TicTacToe::Game do
  subject(:game) { described_class.new_game }

  def play_all(*cells)
    cells.reduce(game) { |g, cell| g.play(cell).value! }
  end

  it "passes the go through every Mark the Board knows, in order" do
    expect(TicTacToe::Game::NEXT_MARK).to eq(x: :o, o: :x)
  end

  describe ".new_game" do
    it "starts on an empty Board with X as the current Mark" do
      expect(game.board).to eq(TicTacToe::Board.empty)
      expect(game.current_mark).to eq(:x)
    end

    it "is in progress" do
      expect(game.outcome).to eq(TicTacToe::Outcome.in_progress)
    end
  end

  describe "#outcome" do
    it "is won by X after X completes a Line" do
      expect(play_all(0, 3, 1, 4, 2).outcome).to eq(TicTacToe::Outcome.won(:x))
    end

    it "is won by O after O completes a Line" do
      expect(play_all(0, 3, 1, 4, 8, 5).outcome).to eq(TicTacToe::Outcome.won(:o))
    end

    it "is a draw when the Board fills with no Line" do
      expect(play_all(0, 1, 2, 4, 3, 5, 7, 6, 8).outcome).to eq(TicTacToe::Outcome.draw)
    end
  end

  describe "#play" do
    it "places the current Mark and makes the other Mark current" do
      result = game.play(4)

      expect(result).to be_success
      expect(result.value!.board.cells[4]).to eq(:x)
      expect(result.value!.current_mark).to eq(:o)
    end

    it "alternates X, O, X" do
      played = game.play(0).value!.play(1).value!.play(2).value!

      expect(played.board.cells.first(3)).to eq(%i[x o x])
      expect(played.current_mark).to eq(:o)
    end

    it "fails on an occupied Cell" do
      taken = game.play(4).value!

      expect(taken.play(4)).to eq(Dry::Monads::Result::Failure.new(:occupied))
    end

    it "fails above the last Cell" do
      expect(game.play(9).failure).to eq(:out_of_bounds)
    end

    it "fails below the first Cell" do
      expect(game.play(-1).failure).to eq(:out_of_bounds)
    end

    it "fails once the Game is finished" do
      won = play_all(0, 3, 1, 4, 2)

      expect(won.play(5)).to eq(Dry::Monads::Result::Failure.new(:game_over))
    end

    it "leaves the original Game unchanged" do
      game.play(4)
      game.play(9)

      expect(game).to eq(described_class.new_game)
    end
  end

  it "is frozen" do
    expect(game).to be_frozen
    expect(game.play(4).value!).to be_frozen
  end
end
