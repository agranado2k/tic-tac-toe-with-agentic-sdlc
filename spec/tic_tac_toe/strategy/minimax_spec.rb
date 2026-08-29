# frozen_string_literal: true

RSpec.describe TicTacToe::Strategy::Minimax do
  subject(:minimax) { described_class.new }

  describe "#call" do
    it "prefers a corner to an edge among Cells the search scores equal" do
      # O to move with only Cell 5 (an edge) and Cell 8 (a corner) free, and
      # both a draw under perfect play: the preference order decides.
      game = game_after(0, 1, 2, 4, 3, 6, 7)

      expect(minimax.call(game.board, :o)).to eq(8)
    end

    it "puts off a forced loss as long as it can" do
      # X holds 0 and 3 against O's 1: every O Move loses, but Cell 6 blocks
      # the column and makes X earn it two Moves later than any other Cell.
      game = game_after(0, 1, 3)

      expect(minimax.call(game.board, :o)).to eq(6)
    end

    it "takes an immediate win when one exists" do
      # O holds 1 and 4 and completes that Line on 7; X holds 0, 2 and 8 and
      # threatens nothing.
      game = game_after(0, 4, 2, 1, 8)

      expect(minimax.call(game.board, :o)).to eq(7)
    end

    it "prefers the win it can have now to the same win two Moves later" do
      # O holds 3 and 4 and wins on 5 now. Playing 2 instead blocks X and
      # leaves O two threats, so it wins too — one Move later. A Strategy that
      # scores a win without counting the Moves to it takes 2 here.
      game = game_after(0, 3, 1, 4, 8)

      expect(minimax.call(game.board, :o)).to eq(5)
    end

    it "blocks the opponent's immediate win when it cannot win itself" do
      # X holds 0 and 1 and wins on 2 next Move; O holds only the centre.
      game = game_after(0, 4, 1)

      expect(minimax.call(game.board, :o)).to eq(2)
    end

    it "opens on the centre Cell of an empty Board" do
      # Every opening draws under perfect play, so the centre here is the
      # preference order's doing, not the search's (ADR-0003 §4).
      expect(minimax.call(TicTacToe::Board.empty, :x)).to eq(4)
    end

    it "takes the one Cell left when the Board is nearly full" do
      board = game_after(0, 1, 2, 4, 3, 5, 7, 6).board

      expect(minimax.call(board, :x)).to eq(8)
    end

    # The property the whole decision rests on: not the examples above, but
    # every line of play the human can choose (ADR-0003 §5). It sits inside
    # this group so that mutant selects it against every mutation of #call —
    # an enforcement clause the mutation run does not reach enforces less.
    describe "playing O against every reachable sequence of X Moves" do
      # One Outcome per complete line of play: X branches over every available
      # Cell, Minimax answers each branch, until the Game is over.
      def outcomes_below(game)
        return [game.outcome] if game.outcome.terminal?

        game.board.available_cells.flat_map { |cell| outcomes_below(answered(game.play(cell).value!)) }
      end

      # The Game after Minimax has taken O's go, or the Game as it stands if X
      # just ended it.
      def answered(game)
        return game if game.outcome.terminal?

        game.play(minimax.call(game.board, :o)).value!
      end

      it "never loses" do
        outcomes = outcomes_below(TicTacToe::Game.new_game)

        expect(outcomes).not_to include(TicTacToe::Outcome.won(:x))
        # The walk itself is worth pinning: an empty one proves nothing.
        expect(outcomes.size).to eq(521)
      end
    end
  end

  it "is a frozen value" do
    expect(minimax).to be_frozen
  end
end
