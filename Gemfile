# frozen_string_literal: true

source "https://rubygems.org"

ruby file: ".ruby-version"

# Functional core: Result/Maybe values instead of nil and exceptions (ADR-0001).
gem "dry-monads", "~> 1.10"

# Imperative shell: the TTY toolkit for terminal rendering and input (ADR-0002).
gem "pastel", "~> 0.8"
gem "tty-box", "~> 0.7"
gem "tty-cursor", "~> 0.7"
gem "tty-prompt", "~> 0.23"
gem "tty-screen", "~> 0.8"

group :development, :test do
  # Mutation testing, run on demand (never a gate): `bundle exec mutant run`.
  gem "mutant-rspec", "~> 0.16", require: false
  gem "rspec", "~> 3.13"
  gem "rubocop", "~> 1.90", require: false
end
