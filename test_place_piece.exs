# Test script to verify piece placement
require Logger

# Create a new game
game = Pento.Game.new_game()
IO.inspect(game, label: "Initial game state")

# Select a piece
{:ok, game_with_selected} = Pento.Game.select_piece(game, "L")
IO.inspect(game_with_selected.current_piece, label: "Selected piece")

# Try to place it at position (0, 0)
{:ok, game_with_placed} = Pento.Game.place_piece(game_with_selected, {0, 0})
IO.inspect(game_with_placed.placed_pieces, label: "Placed pieces after placement")

# Try to remove it
{:ok, game_after_removal} = Pento.Game.remove_piece(game_with_placed, "L")
IO.inspect(game_after_removal.placed_pieces, label: "Placed pieces after removal")