# frozen_string_literal: true

require "stringio"

RSpec.describe TicTacToe::CLI do
  it "renders, takes one move for X, and renders again" do
    prompt = instance_double(TTY::Prompt)
    out = StringIO.new
    allow(prompt).to receive(:select).and_return(4)

    board = described_class.run(prompt: prompt, out: out)

    expect(board.cells[4]).to eq(:x)
    expect(out.string.scan("Tic Tac Toe").size).to eq(2)
    expect(prompt).to have_received(:select).with("Where does X go?", hash_including("Cell 1" => 0), anything)
  end
end
