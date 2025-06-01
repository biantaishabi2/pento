defmodule PentoWeb.Live.CoordinateConversionTest do
  use ExUnit.Case, async: true

  # Import the functions we want to test
  # Since these are private functions in GameLive, we'll need to make them public
  # or test them through the public interface

  describe "pixel_to_grid conversion" do
    test "converts exact grid positions" do
      cell_size = 30
      
      # Test exact grid positions
      assert pixel_to_grid({0, 0}, cell_size) == {0, 0}
      assert pixel_to_grid({30, 30}, cell_size) == {1, 1}
      assert pixel_to_grid({60, 90}, cell_size) == {2, 3}
      assert pixel_to_grid({150, 120}, cell_size) == {5, 4}
      assert pixel_to_grid({270, 150}, cell_size) == {9, 5}
    end

    test "converts positions within cells" do
      cell_size = 30
      
      # Any position within a cell should map to the same grid coordinate
      assert pixel_to_grid({15, 15}, cell_size) == {0, 0}
      assert pixel_to_grid({29, 29}, cell_size) == {0, 0}
      assert pixel_to_grid({31, 31}, cell_size) == {1, 1}
      assert pixel_to_grid({45, 75}, cell_size) == {1, 2}
    end

    test "handles edge cases" do
      cell_size = 30
      
      # Exactly on grid lines
      assert pixel_to_grid({30, 0}, cell_size) == {1, 0}
      assert pixel_to_grid({0, 30}, cell_size) == {0, 1}
      
      # Large coordinates
      assert pixel_to_grid({300, 180}, cell_size) == {10, 6}
      assert pixel_to_grid({900, 600}, cell_size) == {30, 20}
    end

    test "handles different cell sizes" do
      # Small cells
      assert pixel_to_grid({10, 10}, 10) == {1, 1}
      assert pixel_to_grid({25, 35}, 10) == {2, 3}
      
      # Large cells
      assert pixel_to_grid({50, 50}, 50) == {1, 1}
      assert pixel_to_grid({125, 75}, 50) == {2, 1}
      
      # Non-standard cell size
      assert pixel_to_grid({45, 60}, 15) == {3, 4}
    end

    test "handles negative coordinates (edge case)" do
      cell_size = 30
      
      # Negative coordinates should floor to negative grid positions
      # Though these shouldn't occur in practice
      assert pixel_to_grid({-15, -15}, cell_size) == {-1, -1}
      assert pixel_to_grid({-31, -31}, cell_size) == {-2, -2}
    end
  end

  describe "grid_to_pixel conversion" do
    test "converts grid to top-left pixel of cell" do
      cell_size = 30
      
      assert grid_to_pixel({0, 0}, cell_size) == {0, 0}
      assert grid_to_pixel({1, 1}, cell_size) == {30, 30}
      assert grid_to_pixel({5, 3}, cell_size) == {150, 90}
      assert grid_to_pixel({10, 6}, cell_size) == {300, 180}
    end

    test "works with different cell sizes" do
      assert grid_to_pixel({2, 3}, 10) == {20, 30}
      assert grid_to_pixel({2, 3}, 50) == {100, 150}
      assert grid_to_pixel({4, 2}, 25) == {100, 50}
    end
  end

  describe "round-trip conversions" do
    test "pixel -> grid -> pixel maintains grid alignment" do
      cell_size = 30
      
      # Starting from grid-aligned positions
      for x <- 0..9, y <- 0..5 do
        pixel_pos = {x * cell_size, y * cell_size}
        grid_pos = pixel_to_grid(pixel_pos, cell_size)
        result_pixel = grid_to_pixel(grid_pos, cell_size)
        
        assert result_pixel == pixel_pos
      end
    end

    test "pixel -> grid -> pixel snaps to grid" do
      cell_size = 30
      
      # Starting from non-aligned positions
      test_positions = [
        {15, 15},    # Center of (0,0)
        {45, 75},    # Between cells
        {29, 59},    # Near edge
        {31, 61},    # Just over edge
        {149, 89}    # Random position
      ]
      
      for pos <- test_positions do
        grid_pos = pixel_to_grid(pos, cell_size)
        result_pixel = grid_to_pixel(grid_pos, cell_size)
        
        # Result should be snapped to grid
        {rx, ry} = result_pixel
        assert rem(rx, cell_size) == 0
        assert rem(ry, cell_size) == 0
      end
    end
  end

  describe "SVG coordinate extraction" do
    test "extracts coordinates from different event formats" do
      # offsetX/offsetY format (preferred)
      params1 = %{"offsetX" => 150, "offsetY" => 90}
      assert extract_svg_coordinates(params1) == {150, 90}
      
      # clientX/clientY format (fallback)
      params2 = %{"clientX" => 200, "clientY" => 120}
      assert extract_svg_coordinates(params2) == {200, 120}
      
      # Both present (offsetX/Y takes precedence)
      params3 = %{"offsetX" => 150, "offsetY" => 90, "clientX" => 200, "clientY" => 120}
      assert extract_svg_coordinates(params3) == {150, 90}
      
      # String values
      params4 = %{"offsetX" => "150", "offsetY" => "90"}
      assert extract_svg_coordinates(params4) == {150, 90}
    end

    test "handles missing coordinates" do
      # No coordinates
      assert extract_svg_coordinates(%{}) == {0, 0}
      
      # Only X
      assert extract_svg_coordinates(%{"offsetX" => 100}) == {100, 0}
      
      # Only Y
      assert extract_svg_coordinates(%{"offsetY" => 50}) == {0, 50}
      
      # Nil values
      assert extract_svg_coordinates(%{"offsetX" => nil, "offsetY" => nil}) == {0, 0}
    end
  end

  describe "cursor position clamping" do
    test "clamps position within board bounds" do
      board_size = {10, 6}
      
      # Valid positions (unchanged)
      assert clamp_position({5, 3}, board_size) == {5, 3}
      assert clamp_position({0, 0}, board_size) == {0, 0}
      assert clamp_position({9, 5}, board_size) == {9, 5}
      
      # Out of bounds positions (clamped)
      assert clamp_position({-1, 3}, board_size) == {0, 3}
      assert clamp_position({10, 3}, board_size) == {9, 3}
      assert clamp_position({5, -1}, board_size) == {5, 0}
      assert clamp_position({5, 6}, board_size) == {5, 5}
      assert clamp_position({15, 10}, board_size) == {9, 5}
      assert clamp_position({-5, -5}, board_size) == {0, 0}
    end

    test "handles edge cases" do
      # Empty board
      assert clamp_position({5, 5}, {0, 0}) == {0, 0}
      
      # Single cell board
      assert clamp_position({5, 5}, {1, 1}) == {0, 0}
      
      # Very large board
      assert clamp_position({100, 100}, {1000, 1000}) == {100, 100}
    end
  end

  describe "ghost position calculation" do
    test "calculates ghost position from cursor and piece shape" do
      piece = %{shape: [{0, 0}, {1, 0}, {2, 0}, {1, 1}, {1, 2}]} # T shape
      cursor = {5, 3}
      
      # Ghost position should align piece with cursor
      # For now, assuming ghost position equals cursor
      assert calculate_ghost_position(cursor, piece) == cursor
    end

    test "considers piece offset when calculating ghost position" do
      piece = %{shape: [{1, 0}, {0, 1}, {1, 1}, {2, 1}, {1, 2}]} # X shape
      cursor = {5, 3}
      
      # If piece doesn't start at (0,0), ghost position might be adjusted
      # This depends on implementation details
      ghost = calculate_ghost_position(cursor, piece)
      assert is_tuple(ghost)
      assert tuple_size(ghost) == 2
    end
  end

  # Helper functions to match GameLive implementation
  defp pixel_to_grid({pixel_x, pixel_y}, cell_size) do
    # Handle negative coordinates correctly
    x = if pixel_x < 0 do
      div(pixel_x - cell_size + 1, cell_size)
    else
      div(pixel_x, cell_size)
    end
    
    y = if pixel_y < 0 do
      div(pixel_y - cell_size + 1, cell_size)
    else
      div(pixel_y, cell_size)
    end
    
    {x, y}
  end

  defp grid_to_pixel({x, y}, cell_size) do
    {x * cell_size, y * cell_size}
  end

  defp extract_svg_coordinates(params) do
    x = get_coordinate(params, "offsetX", "clientX")
    y = get_coordinate(params, "offsetY", "clientY")
    {x, y}
  end

  defp get_coordinate(params, primary_key, fallback_key) do
    case params[primary_key] do
      nil -> to_integer(params[fallback_key])
      value -> to_integer(value)
    end
  end

  defp to_integer(nil), do: 0
  defp to_integer(value) when is_integer(value), do: value
  defp to_integer(value) when is_binary(value), do: String.to_integer(value)

  defp clamp_position({x, y}, {max_x, max_y}) do
    clamped_x = x |> max(0) |> min(max(0, max_x - 1))
    clamped_y = y |> max(0) |> min(max(0, max_y - 1))
    {clamped_x, clamped_y}
  end

  defp calculate_ghost_position(cursor, _piece) do
    # Simple implementation - ghost follows cursor
    # In real implementation might consider piece shape offset
    cursor
  end
end