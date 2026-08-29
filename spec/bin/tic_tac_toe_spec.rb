# frozen_string_literal: true

require "pty"
require "timeout"

# The entry point, driven through a real pseudo-terminal — the only tier that
# can observe what a player's Ctrl-C does to the process itself. Ctrl-C reaches
# the Shell as a SIGINT or as the reader's own interrupt depending on whether
# the terminal was in raw mode when the key landed; the Shell answers to both,
# so the race between them is not a flake.
RSpec.describe "bin/tic-tac-toe" do
  # The byte a terminal sends for Ctrl-C.
  def ctrl_c
    "\u0003"
  end

  # Generous: this tier pays for a process start, and a hang has to fail rather
  # than wedge the suite.
  def pty_timeout
    20
  end

  # Everything the binary wrote, and how it ended, when Ctrl-C is pressed at the
  # first Cell keypress.
  def ctrl_c_at_the_first_prompt
    Timeout.timeout(pty_timeout) { spawn_and_interrupt }
  end

  def spawn_and_interrupt
    output = +""
    status = nil

    PTY.spawn(RbConfig.ruby, "bin/tic-tac-toe") do |reader, writer, pid|
      output << read_until(reader, "to move")
      writer.write(ctrl_c)
      output << read_to_eof(reader)
      _, status = Process.waitpid2(pid)
    end

    [output, status]
  end

  def read_until(reader, marker)
    seen = +""

    until seen.include?(marker)
      begin
        seen << reader.read_nonblock(4096)
      rescue IO::WaitReadable
        reader.wait_readable(0.1)
      end
    end

    seen
  end

  def read_to_eof(reader)
    rest = +""
    loop { rest << reader.readpartial(4096) }
  rescue EOFError, Errno::EIO
    rest # the child closed its side of the pty
  end

  it "exits with status 130 when the player presses Ctrl-C at a Prompt" do
    _, status = ctrl_c_at_the_first_prompt

    expect(status.exitstatus).to eq(130)
  end

  it "prints no backtrace on the way out" do
    output, = ctrl_c_at_the_first_prompt

    expect(output).to include("X to move")
    expect(output).not_to match(/:\d+:in /)
  end
end
