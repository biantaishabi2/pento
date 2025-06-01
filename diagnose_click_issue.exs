# Diagnostic script to understand the click issue
require Logger

# Test the complete flow
game = Pento.Game.new_game()
IO.puts("\n=== Initial State ===")
IO.inspect(game.placed_pieces, label: "Placed pieces")

# Select and place a piece
{:ok, game} = Pento.Game.select_piece(game, "T")
{:ok, game} = Pento.Game.place_piece(game, {0, 0})
IO.puts("\n=== After Placing Piece ===")
IO.inspect(game.placed_pieces, label: "Placed pieces")

# Try to remove it
IO.puts("\n=== Attempting to Remove Piece ===")
case Pento.Game.remove_piece(game, "T") do
  {:ok, new_game} ->
    IO.puts("SUCCESS: Piece removed")
    IO.inspect(new_game.placed_pieces, label: "Placed pieces after removal")
  {:error, reason} ->
    IO.puts("ERROR: #{inspect(reason)}")
end

# Test with a piece that doesn't exist
IO.puts("\n=== Testing Non-existent Piece Removal ===")
case Pento.Game.remove_piece(game, "Z") do
  {:ok, _} ->
    IO.puts("Unexpected success")
  {:error, reason} ->
    IO.puts("Expected error: #{inspect(reason)}")
end