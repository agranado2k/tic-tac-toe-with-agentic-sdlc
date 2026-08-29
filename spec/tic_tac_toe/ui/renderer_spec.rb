# frozen_string_literal: true

RSpec.describe TicTacToe::UI::Renderer do
  let(:pastel) { Pastel.new(enabled: false) }

  it "numbers empty cells 1..9" do
    output = described_class.render(TicTacToe::Board.empty, pastel: pastel)

    expect(output).to include(" 1 ").and include(" 9 ")
  end

  it "draws placed marks in the right cell" do
    board = TicTacToe::Board.empty.place(4, :x).value!.place(0, :o).value!

    output = described_class.render(board, pastel: pastel)

    expect(output).to include(" O ").and include(" X ")
    expect(output).not_to include(" 5 ")
  end
end
