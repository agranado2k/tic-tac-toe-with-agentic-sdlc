# frozen_string_literal: true

require "stringio"

RSpec.describe TicTacToe::CLI do
  describe ".run" do
    let(:prompt) { instance_double(TTY::Prompt) }
    let(:out) { StringIO.new }
    # Records what the Shell asked to wait for, without waiting.
    let(:pause) { ->(seconds) { paused << seconds } }
    let(:paused) { [] }

    before { allow(prompt).to receive(:yes?).and_return(false) }

    def script(*keys)
      allow(prompt).to receive(:keypress).and_return(*keys)
    end

    # The keys of one scripted X win, and the frames it draws: one per Move,
    # then the announcement.
    def x_win_keys
      %w[1 4 2 5 3]
    end

    def x_win_games
      (0..x_win_keys.size).map { |n| game_after(*x_win_keys.first(n).map { |k| k.to_i - 1 }) }
    end

    def x_win_frames
      renderer = TicTacToe::UI::Renderer
      games = x_win_games
      asking = games[0...-1].map { |g| renderer.render(g.board, status: renderer.to_move(g.current_mark)) }
      asking + [renderer.render(games.last.board, status: "X wins")]
    end

    # The literal bytes that put the cursor back at the top-left of the
    # nine-line frame just written and clear from there down: up 9, column 1,
    # clear to the end of the screen.
    def rewind
      "\e[9A\e[1G\e[J"
    end

    # The byte stream of a sequence of frames all drawn in one place: the first
    # printed, every one after it preceded by the rewind.
    def in_place(frames)
      frames.join(rewind)
    end

    it "rewinds over a nine-line frame with exactly: up 9, column 1, clear down" do
      script("5", nil)

      described_class.run(prompt: prompt, out: out)

      first = TicTacToe::UI::Renderer.render(TicTacToe::Board.empty, status: "X to move")
      expect(first.lines.count).to eq(9)
      expect(out.string).to start_with(first + rewind)
    end

    it "repaints in place: the frame after the first lands where it was" do
      script("5", nil)

      described_class.run(prompt: prompt, out: out)

      first = TicTacToe::UI::Renderer.render(TicTacToe::Board.empty, status: "X to move")
      second = TicTacToe::UI::Renderer.render(game_after(4).board, status: "O to move")
      expect(out.string).to eq(in_place([first, second]))
    end

    it "places the current Mark in the Cell the pressed number names" do
      script("5", "2", "1", "3", "9")

      game = described_class.run(prompt: prompt, out: out)

      expect(game.board.cells).to eq([:x, :o, :o, nil, :x, nil, nil, nil, :x])
    end

    it "repaints a re-ask in place, over the frame that asked for the key" do
      script("q", "5", nil)

      described_class.run(prompt: prompt, out: out)

      renderer = TicTacToe::UI::Renderer
      asking = renderer.render(TicTacToe::Board.empty, status: renderer.to_move(:x))
      refused = renderer.render(TicTacToe::Board.empty, status: renderer::NOT_A_CELL)
      played = renderer.render(game_after(4).board, status: renderer.to_move(:o))
      expect(out.string).to eq(in_place([asking, refused, played]))
    end

    it "re-asks with a status when the key is not a Cell, leaving the Board alone" do
      script("q", "5", "2", "1", "3", "9")

      described_class.run(prompt: prompt, out: out)

      expect(prompt).to have_received(:keypress).exactly(6).times
      expect(out.string).to include(
        TicTacToe::UI::Renderer.render(TicTacToe::Board.empty, status: TicTacToe::UI::Renderer::NOT_A_CELL)
      )
    end

    it "re-asks with a status naming the taken Cell, leaving the Board alone" do
      script("5", "5", "2", "1", "3", "9")

      described_class.run(prompt: prompt, out: out)

      expect(prompt).to have_received(:keypress).exactly(6).times
      expect(out.string).to include(
        TicTacToe::UI::Renderer.render(game_after(4).board, status: TicTacToe::UI::Renderer.occupied(4))
      )
    end

    it "says which Mark is to move before each Move" do
      script("5", "2", "1", "3", "9")

      described_class.run(prompt: prompt, out: out)

      expect(out.string.scan(/[XO] to move/)).to eq(["X to move", "O to move", "X to move",
                                                     "O to move", "X to move"])
    end

    it "ends a scripted O win with the announcement in the status line" do
      script(*%w[1 4 2 5 9 6])

      game = described_class.run(prompt: prompt, out: out)

      expect(prompt).to have_received(:keypress).exactly(6).times
      expect(out.string).to end_with(
        TicTacToe::UI::Renderer.render(game.board, status: "O wins")
      )
    end

    it "ends a scripted draw with the announcement in the status line" do
      script(*%w[1 2 3 5 4 6 8 7 9])

      game = described_class.run(prompt: prompt, out: out)

      expect(prompt).to have_received(:keypress).exactly(9).times
      expect(out.string).to end_with(
        TicTacToe::UI::Renderer.render(game.board, status: "Draw")
      )
    end

    it "plays a scripted X win in five keypresses, one frame each plus the announcement" do
      script(*x_win_keys)

      game = described_class.run(prompt: prompt, out: out)

      expect(prompt).to have_received(:keypress).exactly(5).times
      expect(game.outcome).to eq(TicTacToe::Outcome.won(:x))
      expect(out.string).to eq(in_place(x_win_frames))
    end

    it "offers Play again? after a finished Game, and returns when the answer is no" do
      script(*x_win_keys)

      game = described_class.run(prompt: prompt, out: out)

      expect(prompt).to have_received(:yes?).with(described_class::PLAY_AGAIN).once
      expect(game.outcome).to eq(TicTacToe::Outcome.won(:x))
    end

    it "starts a Replay as a fresh Game below the finished frame when the answer is yes" do
      script(*(x_win_keys * 2))
      allow(prompt).to receive(:yes?).with(described_class::PLAY_AGAIN).and_return(true, false)

      game = described_class.run(prompt: prompt, out: out)

      expect(game).to eq(game_after(0, 3, 1, 4, 2))
      expect(out.string).to eq(in_place(x_win_frames) * 2)
    end

    it "asks Play again? once per finished Game" do
      script(*(x_win_keys * 2))
      allow(prompt).to receive(:yes?).with(described_class::PLAY_AGAIN).and_return(true, false)

      described_class.run(prompt: prompt, out: out)

      expect(prompt).to have_received(:keypress).exactly(10).times
      expect(prompt).to have_received(:yes?).with(described_class::PLAY_AGAIN).twice
    end

    it "does not offer Play again? for a Game abandoned when the input stream closed" do
      script("5", nil)

      described_class.run(prompt: prompt, out: out)

      expect(prompt).not_to have_received(:yes?).with(described_class::PLAY_AGAIN)
    end

    it "leaves when the input stream is closed instead of re-asking forever" do
      script("5", nil)

      game = described_class.run(prompt: prompt, out: out)

      expect(prompt).to have_received(:keypress).exactly(2).times
      expect(game).to eq(game_after(4))
      expect(game.outcome).not_to be_terminal
    end

    # Versus the computer the human is X and opens; O is the Strategy's. The
    # random source is injected, so "the first available Cell" is what the
    # computer plays in every example below and the frames are exact.
    context "in versus-computer Mode" do
      let(:lowest_cell) { instance_double(Random, rand: 0) }

      before { allow(prompt).to receive(:yes?).with(described_class::MODE_QUESTION).and_return(true) }

      def play(*keys)
        script(*keys)
        described_class.run(prompt: prompt, out: out, pause: pause, random: lowest_cell)
      end

      it "plays O from the Strategy, announcing the Cell it took" do
        play("5", nil)

        renderer = TicTacToe::UI::Renderer
        asking = renderer.render(TicTacToe::Board.empty, status: renderer.to_move(:x))
        placed = renderer.render(game_after(4).board, status: renderer.to_move(:o))
        answered = renderer.render(game_after(4, 0).board, status: "Computer plays 1")
        expect(out.string).to eq(in_place([asking, placed, answered]))
      end

      it "never asks the Prompt for O's Move" do
        play("5", "2", "8")

        expect(prompt).to have_received(:keypress).exactly(3).times
      end

      it "pauses once per computer Move, for the default seconds" do
        play("5", "2", "8")

        expect(paused).to eq([0.5, 0.5])
      end

      it "announces X wins when the human completes a Line" do
        game = play("5", "2", "8")

        expect(game.outcome).to eq(TicTacToe::Outcome.won(:x))
        expect(out.string).to end_with(TicTacToe::UI::Renderer.render(game.board, status: "X wins"))
      end

      it "announces O wins when the computer completes a Line" do
        game = play("5", "6", "8")

        expect(game.board.cells).to eq([:o, :o, :o, nil, :x, :x, nil, :x, nil])
        expect(game.outcome).to eq(TicTacToe::Outcome.won(:o))
        expect(out.string).to end_with(TicTacToe::UI::Renderer.render(game.board, status: "O wins"))
      end

      it "announces a Draw when the Board fills with no Winner" do
        game = play("2", "4", "5", "7", "9")

        expect(game.outcome).to eq(TicTacToe::Outcome.draw)
        expect(out.string).to end_with(TicTacToe::UI::Renderer.render(game.board, status: "Draw"))
      end

      it "keeps the Mode over a Replay without asking for it again" do
        allow(prompt).to receive(:yes?).with(described_class::PLAY_AGAIN).and_return(true, false)

        play(*(%w[5 2 8] * 2))

        expect(prompt).to have_received(:yes?).with(described_class::MODE_QUESTION).once
        expect(paused).to eq([0.5] * 4)
      end

      it "asks the Difficulty once, after the Mode question" do
        play("5", nil)

        expect(prompt).to have_received(:yes?).with(described_class::DIFFICULTY_QUESTION).once
      end

      it "keeps the Difficulty over a Replay without asking for it again" do
        allow(prompt).to receive(:yes?).with(described_class::PLAY_AGAIN).and_return(true, false)

        play(*(%w[5 2 8] * 2))

        expect(prompt).to have_received(:yes?).with(described_class::DIFFICULTY_QUESTION).once
      end

      # On hard the Cell O takes is Minimax's, and the injected random source
      # is never drawn from — the two Strategies disagree from the first Move.
      context "on the hard Difficulty" do
        before { allow(prompt).to receive(:yes?).with(described_class::DIFFICULTY_QUESTION).and_return(true) }

        it "answers a corner opening with the centre, where Random would take the first free Cell" do
          play("1", nil)

          expect(out.string).to include("Computer plays 5")
          expect(lowest_cell).not_to have_received(:rand)
        end

        it "blocks the Line the human is one Cell from completing" do
          play("1", "2", nil)

          expect(out.string).to include("Computer plays 3")
        end

        it "punishes the corner fork a careless O loses to" do
          game = play(*%w[1 9 3 7 8])

          expect(game.outcome).to eq(TicTacToe::Outcome.won(:o))
        end

        it "concedes the draw a human who plays perfectly earns, and no more" do
          game = play(*%w[5 3 4 9 8])

          expect(game.outcome).to eq(TicTacToe::Outcome.draw)
        end
      end

      it "refuses a Cell the computer took, naming it, and asks the human again" do
        play("5", "1", "2", nil)

        expect(out.string).to include(
          TicTacToe::UI::Renderer.render(game_after(4, 0).board, status: "Cell 1 is taken")
        )
      end

      it "builds its own random source and pause when given neither" do
        allow(TTY::Prompt).to receive(:new).and_return(prompt)
        allow(described_class).to receive(:sleep)
        script("5", nil)

        expect { described_class.run }.to output(/Computer plays [1-9]/).to_stdout
        expect(described_class).to have_received(:sleep).with(0.5)
      end
    end

    it "asks which Mode to play before drawing the first frame" do
      script("5", nil)

      described_class.run(prompt: prompt, out: out)

      expect(prompt).to have_received(:yes?).with(described_class::MODE_QUESTION).once
    end

    it "never asks the Difficulty in hot seat, where no Strategy plays" do
      script("5", nil)

      described_class.run(prompt: prompt, out: out)

      expect(prompt).not_to have_received(:yes?).with(described_class::DIFFICULTY_QUESTION)
    end

    it "never pauses in hot seat, where every Move is a keypress" do
      script(*%w[1 4 2 5 3])

      described_class.run(prompt: prompt, out: out, pause: pause)

      expect(paused).to be_empty
    end

    it "builds its own prompt and writes to $stdout when given neither" do
      allow(TTY::Prompt).to receive(:new).and_return(prompt)
      script(*%w[1 4 2 5 3])

      expect { described_class.run }.to output(/X wins/).to_stdout
    end

    # Ctrl-C reaches the Shell as an Interrupt either way: tty-prompt's reader
    # raises its own InputInterrupt when the key lands inside a raw read
    # (`interrupt: :error`, its default), and the terminal driver turns it into
    # a SIGINT — a bare Interrupt — when it lands anywhere else.
    context "when Ctrl-C interrupts a Prompt" do
      def script_then_interrupt(*keys)
        interrupt = -> { raise TTY::Reader::InputInterrupt }
        allow(prompt).to receive(:keypress).and_invoke(*keys.map { |key| -> { key } }, interrupt)
      end

      it "ends with exit status 130 when the interrupt lands on the Mode question" do
        allow(prompt).to receive(:yes?).with(described_class::MODE_QUESTION).and_raise(Interrupt)

        expect { described_class.run(prompt: prompt, out: out) }
          .to raise_error(SystemExit) { |quit| expect(quit.status).to eq(130) }
        expect(out.string).to eq("\n")
      end

      it "ends with exit status 130 when the interrupt lands on a Cell keypress" do
        script_then_interrupt("5")

        expect { described_class.run(prompt: prompt, out: out) }
          .to raise_error(SystemExit) { |quit| expect(quit.status).to eq(130) }
      end

      it "leaves the Frame it last drew on screen, followed by one blank line" do
        script_then_interrupt("5")

        expect { described_class.run(prompt: prompt, out: out) }.to raise_error(SystemExit)

        renderer = TicTacToe::UI::Renderer
        asking = renderer.render(TicTacToe::Board.empty, status: renderer.to_move(:x))
        played = renderer.render(game_after(4).board, status: renderer.to_move(:o))
        expect(out.string).to eq("#{in_place([asking, played])}\n")
      end

      it "ends with exit status 130 when a SIGINT lands on Play again?" do
        script(*x_win_keys)
        allow(prompt).to receive(:yes?).with(described_class::PLAY_AGAIN).and_raise(Interrupt)

        expect { described_class.run(prompt: prompt, out: out) }
          .to raise_error(SystemExit) { |quit| expect(quit.status).to eq(130) }

        expect(out.string).to eq("#{in_place(x_win_frames)}\n")
      end
    end
  end

  describe ".ask_mode" do
    let(:prompt) { instance_double(TTY::Prompt) }

    it "names the versus-computer Mode when the answer is yes" do
      allow(prompt).to receive(:yes?).with(described_class::MODE_QUESTION).and_return(true)

      expect(described_class.ask_mode(prompt)).to eq(described_class::VERSUS_COMPUTER)
    end

    it "names the hot-seat Mode when the answer is no" do
      allow(prompt).to receive(:yes?).with(described_class::MODE_QUESTION).and_return(false)

      expect(described_class.ask_mode(prompt)).to eq(described_class::HOT_SEAT)
    end
  end

  describe ".ask_difficulty" do
    let(:prompt) { instance_double(TTY::Prompt) }

    it "names the hard Difficulty when the answer is yes" do
      allow(prompt).to receive(:yes?).with(described_class::DIFFICULTY_QUESTION).and_return(true)

      expect(described_class.ask_difficulty(prompt, described_class::VERSUS_COMPUTER))
        .to eq(described_class::HARD)
    end

    it "names the easy Difficulty when the answer is no" do
      allow(prompt).to receive(:yes?).with(described_class::DIFFICULTY_QUESTION).and_return(false)

      expect(described_class.ask_difficulty(prompt, described_class::VERSUS_COMPUTER))
        .to eq(described_class::EASY)
    end

    it "names no Difficulty in hot seat, and does not ask" do
      allow(prompt).to receive(:yes?)

      expect(described_class.ask_difficulty(prompt, described_class::HOT_SEAT)).to be_nil
      expect(prompt).not_to have_received(:yes?)
    end
  end

  describe ".computer_strategy" do
    let(:random) { instance_double(Random) }

    it "plays the hard Difficulty with Minimax" do
      expect(described_class.computer_strategy(described_class::HARD, random))
        .to eq(TicTacToe::Strategy::Minimax.new)
    end

    it "plays the easy Difficulty with Random over the injected source" do
      expect(described_class.computer_strategy(described_class::EASY, random))
        .to eq(TicTacToe::Strategy::Random.new(source: random))
    end

    it "has no Strategy where no Difficulty was chosen" do
      expect(described_class.computer_strategy(nil, random)).to be_nil
    end
  end

  # A Strategy is any callable of a Board and the Mark to move, so a lambda
  # stands in for one here — that is the seam the Minimax ticket plugs into.
  describe ".computer_move" do
    let(:no_pause) { ->(_seconds) {} }

    it "hands the Strategy the Board and the Mark whose go it is" do
      seen = nil
      strategy = lambda do |board, mark|
        seen = [board, mark]
        board.available_cells.first
      end

      described_class.computer_move(game_after(4), strategy, no_pause)

      expect(seen).to eq([game_after(4).board, :o])
    end

    it "answers with the Game after the Strategy's Move and a status naming the Cell" do
      game, status = described_class.computer_move(game_after(4), ->(*) { 0 }, no_pause)

      expect(game).to eq(game_after(4, 0))
      expect(status).to eq("Computer plays 1")
    end

    it "waits the default seconds before the Move" do
      waited = []

      described_class.computer_move(game_after(4), ->(*) { 0 }, ->(seconds) { waited << seconds })

      expect(waited).to eq([0.5])
    end
  end

  describe ".advance" do
    let(:won) { game_after(0, 3, 1, 4, 2) }

    it "plays the Cell the key names and says who is to move next" do
      game, status = described_class.advance(TicTacToe::Game.new_game, "5")

      expect(game).to eq(game_after(4))
      expect(status).to eq("O to move")
    end

    it "refuses a key that is not a Cell, leaving the Game untouched" do
      game, status = described_class.advance(TicTacToe::Game.new_game, "q")

      expect(game).to eq(TicTacToe::Game.new_game)
      expect(status).to eq(TicTacToe::UI::Renderer::NOT_A_CELL)
    end

    it "refuses a taken Cell, naming it" do
      game, status = described_class.advance(game_after(4), "5")

      expect(game).to eq(game_after(4))
      expect(status).to eq("Cell 5 is taken")
    end

    it "refuses a Move on a finished Game with the announcement, not a taken-Cell message" do
      game, status = described_class.advance(won, "9")

      expect(game).to eq(won)
      expect(status).to eq("X wins")
    end
  end
end
