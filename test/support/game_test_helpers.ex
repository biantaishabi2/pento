defmodule PentoWeb.GameTestHelpers do
  @moduledoc """
  Helper functions for game-related tests
  """

  import Phoenix.LiveViewTest

  @piece_shapes %{
    "F" => [[0, 0], [1, 0], [1, 1], [1, 2], [2, 1]],
    "I" => [[0, 0], [0, 1], [0, 2], [0, 3], [0, 4]],
    "L" => [[0, 0], [0, 1], [0, 2], [0, 3], [1, 3]],
    "N" => [[0, 0], [0, 1], [1, 1], [1, 2], [1, 3]],
    "P" => [[0, 0], [0, 1], [1, 0], [1, 1], [1, 2]],
    "T" => [[0, 0], [1, 0], [2, 0], [1, 1], [1, 2]],
    "U" => [[0, 0], [0, 1], [1, 1], [2, 1], [2, 0]],
    "V" => [[0, 0], [0, 1], [0, 2], [1, 2], [2, 2]],
    "W" => [[0, 0], [0, 1], [1, 1], [1, 2], [2, 2]],
    "X" => [[1, 0], [0, 1], [1, 1], [2, 1], [1, 2]],
    "Y" => [[0, 0], [0, 1], [1, 1], [0, 2], [0, 3]],
    "Z" => [[0, 0], [1, 0], [1, 1], [1, 2], [2, 2]]
  }

  @piece_colors %{
    "F" => "#ef4444",
    "I" => "#3b82f6", 
    "L" => "#f97316",
    "N" => "#a855f7",
    "P" => "#ec4899",
    "T" => "#14b8a6",
    "U" => "#f59e0b",
    "V" => "#10b981",
    "W" => "#8b5cf6",
    "X" => "#06b6d4",
    "Y" => "#6366f1",
    "Z" => "#84cc16"
  }

  def place_piece(view, piece_id, {x, y}) do
    view 
    |> element("[phx-click=\"select_piece\"][phx-value-id=\"#{piece_id}\"]") 
    |> render_click()
    
    # Use direct event instead of element selector for more reliable placement
    render_click(view, "drop_at_cell", %{"x" => to_string(x), "y" => to_string(y)})
  end

  def place_piece_at_valid_position(view, piece_id) do
    # Select piece
    view 
    |> element("[phx-click=\"select_piece\"][phx-value-id=\"#{piece_id}\"]") 
    |> render_click()
    
    # Find first valid position
    valid_positions = view.assigns.valid_positions
    {x, y} = List.first(valid_positions) || {0, 0}
    
    view 
    |> element("[phx-click=\"drop_at_cell\"][phx-value-x=\"#{x}\"][phx-value-y=\"#{y}\"]") 
    |> render_click()
  end

  def place_test_pieces(view, pieces) do
    Enum.each(pieces, fn {piece_id, {x, y}} ->
      place_piece(view, piece_id, {x, y})
      Process.sleep(50) # Small delay to ensure proper state updates
    end)
  end

  def test_placed_piece(id, {x, y}) do
    %{
      id: id,
      position: %{x: x, y: y},
      shape: get_piece_shape(id),
      color: get_piece_color(id)
    }
  end
  
  # Database-compatible version for direct DB operations
  def test_placed_piece_db(id, {x, y}) do
    %{
      "id" => id,
      "position" => %{"x" => x, "y" => y},
      "shape" => get_piece_shape(id),
      "color" => get_piece_color(id)
    }
  end

  def get_piece_shape(id), do: Map.get(@piece_shapes, id, [])
  def get_piece_color(id), do: Map.get(@piece_colors, id, "#000000")

  def random_position(max_x \\ 9, max_y \\ 5) do
    {:rand.uniform(max_x + 1) - 1, :rand.uniform(max_y + 1) - 1}
  end

  # Removed - use Plug.Test.init_test_session directly to avoid conflicts

  def create_test_game_state(placed_pieces \\ []) do
    all_pieces = ["F", "I", "L", "N", "P", "T", "U", "V", "W", "X", "Y", "Z"]
    placed_ids = Enum.map(placed_pieces, & &1.id)
    available = Enum.reject(all_pieces, &(&1 in placed_ids))
    
    %{
      board_size: %{cols: 10, rows: 6},
      placed_pieces: placed_pieces,
      available_pieces: available,
      current_piece: nil,
      history: []
    }
  end

  def calculate_progress(placed_count, total_count \\ 12) do
    Float.round(placed_count / total_count * 100, 1)
  end
end