#!/usr/bin/env elixir

# Change to pento directory first
File.cd!("/home/wangbo/document/pento")

# Load the application to get dependencies and modules
{:ok, _} = Application.ensure_all_started(:pento)

alias Pento.Game
alias Pento.Game.Piece

# Create new game
game_state = Game.new_game()

# Select F piece
{:ok, game_state} = Game.select_piece(game_state, "F")

IO.puts("F piece shape: #{inspect(game_state.current_piece.shape)}")

# Try placing at different positions
positions = [{0, 0}, {1, 0}, {2, 0}, {0, 1}, {1, 1}, {2, 1}]

Enum.each(positions, fn pos ->
  case Game.smart_place_piece(game_state, pos) do
    {:ok, _new_state} ->
      IO.puts("Position #{inspect(pos)}: SUCCESS")
    {:error, reason} ->
      IO.puts("Position #{inspect(pos)}: FAILED - #{reason}")
  end
end)