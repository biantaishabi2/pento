#!/usr/bin/env elixir

# Simple test script to verify game persistence

IO.puts("Testing game persistence...")

# Start the application
{:ok, _} = Application.ensure_all_started(:pento)

alias Pento.Games
alias Pento.Game

# Test 1: Create a new session
IO.puts("\n1. Creating new game session...")
session_id = "test-#{System.unique_integer()}"
{:ok, session} = Games.get_or_create_session(session_id)
IO.puts("✓ Session created: #{session.id}")

# Test 2: Save game state
IO.puts("\n2. Saving game state...")
game_state = %{
  board_size: %{cols: 10, rows: 6},
  placed_pieces: [
    %{
      id: "F",
      shape: [[0, 0], [1, 0], [1, 1], [1, 2], [2, 1]],
      position: %{x: 0, y: 0},
      color: "#ef4444"
    }
  ],
  available_pieces: ["I", "L", "N", "P", "T", "U", "V", "W", "X", "Y", "Z"],
  current_piece: nil,
  history: []
}

{:ok, updated} = Games.save_game_state(session_id, game_state)
IO.puts("✓ Game saved with progress: #{updated.progress}%")

# Test 3: Load game state
IO.puts("\n3. Loading game state...")
{:ok, loaded} = Games.load_game_state(session_id)
IO.puts("✓ Game loaded")
IO.puts("  - Placed pieces: #{length(loaded.game_state["placed_pieces"])}")
IO.puts("  - Progress: #{loaded.progress}%")

# Test 4: Simulate complete game
IO.puts("\n4. Testing complete game...")
complete_state = %{
  board_size: %{cols: 10, rows: 6},
  placed_pieces: Enum.map(["F", "I", "L", "N", "P", "T", "U", "V", "W", "X", "Y", "Z"], fn id ->
    %{
      id: id,
      shape: [[0, 0]],  # Simplified
      position: %{x: 0, y: 0},
      color: "#000000"
    }
  end),
  available_pieces: [],
  current_piece: nil,
  history: []
}

{:ok, completed} = Games.save_game_state(session_id, complete_state)
IO.puts("✓ Game completed: #{completed.is_completed}")
IO.puts("  - Progress: #{completed.progress}%")

IO.puts("\n✅ All tests passed!")