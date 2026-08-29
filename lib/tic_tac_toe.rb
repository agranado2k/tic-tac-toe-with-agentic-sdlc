# frozen_string_literal: true

require "dry/monads"

require_relative "tic_tac_toe/board"
require_relative "tic_tac_toe/outcome"
require_relative "tic_tac_toe/game"
require_relative "tic_tac_toe/ui/renderer"
require_relative "tic_tac_toe/cli"

module TicTacToe
  VERSION = "0.1.0"
end
