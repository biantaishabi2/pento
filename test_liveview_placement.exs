# Test LiveView piece placement
require Logger

# Simulate what happens in LiveView
# 1. Create initial game state
initial_state = Pento.Game.new_game()
Logger.info("Initial state placed pieces: #{inspect(initial_state.placed_pieces)}")

# 2. Select a piece (this is what happens when user clicks on a piece)
{:ok, state_with_selected} = Pento.Game.select_piece(initial_state, "T")
Logger.info("Selected piece: #{inspect(state_with_selected.current_piece)}")

# 3. Place the piece (this is what happens when user clicks on board)
{:ok, state_with_placed} = Pento.Game.place_piece(state_with_selected, {0, 0})
Logger.info("Placed pieces after placement: #{inspect(state_with_placed.placed_pieces)}")

# 4. Save the game state (this is what's logged)
saved_state = Pento.Game.save_game(state_with_placed)
IO.inspect(saved_state, label: "Saved game state")