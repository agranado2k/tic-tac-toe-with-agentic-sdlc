# frozen_string_literal: true

require "tic_tac_toe"

# A Game after the given Moves, each a 0-based Cell index, X first.
module GameHelpers
  def game_after(*cells)
    cells.reduce(TicTacToe::Game.new_game) { |game, cell| game.play(cell).value! }
  end
end

RSpec.configure do |config|
  config.include GameHelpers
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed
end
