defmodule Pento.Game.BoundaryTest do
  use ExUnit.Case, async: true
  
  alias Pento.Game.{Board, Piece, State}
  import Pento.Factory

  describe "board boundary validation" do
    setup do
      {:ok, board_size: {10, 6}}
    end

    test "accepts pieces fully within bounds", %{board_size: board_size} do
      # Test various pieces at valid positions
      test_cases = [
        # I piece vertical at left edge
        {[{0, 0}, {0, 1}, {0, 2}, {0, 3}, {0, 4}], board_size},
        # I piece horizontal at top edge
        {[{0, 0}, {1, 0}, {2, 0}, {3, 0}, {4, 0}], board_size},
        # T piece at bottom-right corner
        {[{7, 5}, {8, 5}, {9, 5}, {8, 4}, {8, 3}], board_size},
        # Single cell at each corner
        {[{0, 0}], board_size},
        {[{9, 0}], board_size},
        {[{0, 5}], board_size},
        {[{9, 5}], board_size}
      ]
      
      for {positions, size} <- test_cases do
        assert Board.within_bounds?(positions, size) == true
      end
    end

    test "rejects pieces extending beyond right edge", %{board_size: board_size} do
      test_cases = [
        # I piece horizontal starting at x=6 (extends to x=10)
        [{6, 0}, {7, 0}, {8, 0}, {9, 0}, {10, 0}],
        # Single cell beyond boundary
        [{10, 3}],
        # F piece partially out
        [{8, 1}, {8, 2}, {9, 0}, {9, 1}, {10, 1}]
      ]
      
      for positions <- test_cases do
        assert Board.within_bounds?(positions, board_size) == false
      end
    end

    test "rejects pieces extending beyond bottom edge", %{board_size: board_size} do
      test_cases = [
        # I piece vertical starting at y=2 (extends to y=6)
        [{0, 2}, {0, 3}, {0, 4}, {0, 5}, {0, 6}],
        # Single cell beyond boundary
        [{5, 6}],
        # L piece partially out
        [{3, 3}, {3, 4}, {3, 5}, {3, 6}, {4, 6}]
      ]
      
      for positions <- test_cases do
        assert Board.within_bounds?(positions, board_size) == false
      end
    end

    test "rejects pieces with negative coordinates", %{board_size: board_size} do
      test_cases = [
        # Negative x
        [{-1, 0}, {0, 0}, {1, 0}],
        # Negative y
        [{0, -1}, {0, 0}, {0, 1}],
        # Both negative
        [{-1, -1}, {0, 0}],
        # Piece translated to negative position
        [{-2, 2}, {-1, 2}, {0, 2}, {1, 2}, {2, 2}]
      ]
      
      for positions <- test_cases do
        assert Board.within_bounds?(positions, board_size) == false
      end
    end

    test "handles edge case board sizes" do
      # Minimum viable board
      assert Board.within_bounds?([{0, 0}], {1, 1}) == true
      assert Board.within_bounds?([{1, 0}], {1, 1}) == false
      
      # Empty board (should reject everything)
      assert Board.within_bounds?([{0, 0}], {0, 0}) == false
      
      # Very large board
      large_size = {100, 100}
      assert Board.within_bounds?([{50, 50}], large_size) == true
      assert Board.within_bounds?([{99, 99}], large_size) == true
      assert Board.within_bounds?([{100, 100}], large_size) == false
    end
  end

  describe "piece placement boundary validation" do
    test "validates placement near edges" do
      state = build_game_state(%{board_size: {10, 6}})
      
      # Valid placements near edges
      valid_cases = [
        {"I", {5, 0}},  # Horizontal I at top
        {"I", {0, 1}},  # Vertical I at left (rotated)
        {"F", {7, 3}},  # F piece near bottom-right
        {"L", {6, 2}}   # L piece in middle-right
      ]
      
      for {piece_id, position} <- valid_cases do
        {:ok, state_with_piece} = State.select_piece(state, piece_id)
        {:ok, _new_state} = State.place_piece(state_with_piece, position)
      end
    end

    test "rejects placement outside bounds" do
      state = build_game_state(%{board_size: {10, 6}})
      
      # Invalid placements
      invalid_cases = [
        {"I", {10, 0}},  # I shape 1x5, position (10,0) goes out of bounds (x >= 10)
        {"I", {0, 2}},   # I shape 1x5, position (0,2) -> max_y = 2+4 = 6 (out of bounds)  
        {"X", {9, 4}},   # X shape max_x=2, position (9,4) -> max_x = 9+2 = 11 (out of bounds)
        {"T", {-1, 2}},  # T piece starts at negative x
        {"W", {8, 4}}    # W shape max_x=2, position (8,4) -> max_x = 8+2 = 10 (out of bounds)
      ]
      
      for {piece_id, position} <- invalid_cases do
        {:ok, state_with_piece} = State.select_piece(state, piece_id)
        assert {:error, :out_of_bounds} = State.place_piece(state_with_piece, position)
      end
    end

    test "complex shapes near boundaries" do
      state = build_game_state(%{board_size: {10, 6}})
      
      # Test each pentomino at its maximum valid position  
      # Board size is {10, 6}, so valid coords are (0,0) to (9,5)
      max_positions = [
        {"F", {7, 3}},  # F shape: max offset (2,2), so max pos (7,3) -> (9,5) ✓
        {"I", {9, 1}},  # I shape: max offset (0,4), so max pos (9,1) -> (9,5) ✓
        {"L", {8, 2}},  # L shape: max offset (1,3), so max pos (8,2) -> (9,5) ✓
        {"N", {8, 3}},  # N shape: max offset (1,2), so max pos (8,3) -> (9,5) ✓
        {"P", {8, 3}},  # P shape: max offset (1,2), so max pos (8,3) -> (9,5) ✓
        {"T", {7, 3}},  # T shape: max offset (2,2), so max pos (7,3) -> (9,5) ✓
        {"U", {7, 4}},  # U shape: max offset (2,1), so max pos (7,4) -> (9,5) ✓
        {"V", {7, 3}},  # V shape: max offset (2,2), so max pos (7,3) -> (9,5) ✓
        {"W", {7, 3}},  # W shape: max offset (2,2), so max pos (7,3) -> (9,5) ✓
        {"X", {7, 3}},  # X shape: max offset (2,2), so max pos (7,3) -> (9,5) ✓
        {"Y", {7, 3}},  # Y shape: max offset (2,2), so max pos (7,3) -> (9,5) ✓
        {"Z", {7, 3}}   # Z shape: max offset (2,2), so max pos (7,3) -> (9,5) ✓
      ]
      
      for {piece_id, position} <- max_positions do
        piece = Piece.get_piece(piece_id)
        abs_positions = Piece.get_absolute_positions(piece.shape, position)
        
        # Verify all positions are within bounds
        assert Board.within_bounds?(abs_positions, state.board_size),
               "#{piece_id} at #{inspect(position)} goes out of bounds"
        
        # Verify moving one more step would be out of bounds
        {x, y} = position
        next_positions = [
          Piece.get_absolute_positions(piece.shape, {x + 1, y}),
          Piece.get_absolute_positions(piece.shape, {x, y + 1})
        ]
        
        assert Enum.any?(next_positions, fn pos -> 
          not Board.within_bounds?(pos, state.board_size)
        end), "#{piece_id} should be at maximum valid position"
      end
    end
  end

  describe "collision detection near boundaries" do
    test "detects collisions at board edges" do
      state = build_game_state(%{board_size: {10, 6}})
      
      # Place pieces at edges
      {:ok, state} = State.select_piece(state, "I")
      {:ok, state} = State.place_piece(state, {0, 0})  # Vertical I at left edge
      
      {:ok, state} = State.select_piece(state, "L")
      {:ok, state} = State.place_piece(state, {8, 2})  # L at right edge (max valid position)
      
      # Try to place overlapping pieces
      {:ok, state} = State.select_piece(state, "F")
      assert {:error, :collision} = State.place_piece(state, {0, 0})  # Overlaps with I
      
      {:ok, state} = State.select_piece(state, "T")
      assert {:error, :collision} = State.place_piece(state, {7, 2})  # Overlaps with L
    end

    test "allows adjacent placement at boundaries" do
      state = build_game_state(%{board_size: {10, 6}})
      
      # Place I at top-left edge
      {:ok, state} = State.select_piece(state, "I")
      {:ok, state} = State.place_piece(state, {0, 0})  # I at left edge: occupies (0,0) to (0,4)
      
      # Should allow F right next to it (no overlap)
      {:ok, state} = State.select_piece(state, "F")
      {:ok, state} = State.place_piece(state, {3, 0})  # F at safe position
      
      # Should allow another piece below
      {:ok, state} = State.select_piece(state, "T")
      {:ok, _state} = State.place_piece(state, {7, 0})  # T at top
    end
  end

  describe "valid positions calculation with boundaries" do
    test "excludes out-of-bounds positions" do
      # Empty board
      placed_pieces = []
      board_size = {10, 6}
      
      # Test I piece (5 cells in a row)
      i_shape = [{0, 0}, {0, 1}, {0, 2}, {0, 3}, {0, 4}]
      valid = Board.valid_positions(i_shape, placed_pieces, board_size)
      
      # Should have positions where piece fits entirely on board
      # Vertical I: x can be 0-9, y can be 0-1 (since piece extends 4 cells down)
      assert length(valid) == 10 * 2  # 20 valid positions
      
      # Verify no position would place piece out of bounds
      for pos <- valid do
        abs_positions = Piece.get_absolute_positions(i_shape, pos)
        assert Board.within_bounds?(abs_positions, board_size)
      end
    end

    test "handles complex board states" do
      # Board with pieces near edges
      placed_pieces = [
        build_placed_piece("I", {0, 0}),   # Left edge
        build_placed_piece("L", {9, 2}),   # Right edge
        build_placed_piece("T", {4, 5})    # Bottom edge
      ]
      board_size = {10, 6}
      
      # Test placing F piece
      f_shape = [{0, 1}, {0, 2}, {1, 0}, {1, 1}, {2, 1}]
      valid = Board.valid_positions(f_shape, placed_pieces, board_size)
      
      # Should exclude positions that would:
      # 1. Go out of bounds
      # 2. Overlap with existing pieces
      
      for pos <- valid do
        abs_positions = Piece.get_absolute_positions(f_shape, pos)
        
        # Must be within bounds
        assert Board.within_bounds?(abs_positions, board_size)
        
        # Must not collide
        refute Board.has_collision?(abs_positions, placed_pieces)
      end
    end

    test "no valid positions when board is too full" do
      # Nearly full board
      placed_pieces = [
        build_placed_piece("I", {0, 0}),
        build_placed_piece("F", {1, 0}),
        build_placed_piece("L", {4, 0}),
        build_placed_piece("N", {5, 0}),
        build_placed_piece("P", {7, 0}),
        build_placed_piece("T", {9, 0}),
        build_placed_piece("U", {0, 3}),
        build_placed_piece("V", {3, 3}),
        build_placed_piece("W", {6, 3}),
        build_placed_piece("X", {8, 2})
      ]
      board_size = {10, 6}
      
      # Try to place Y piece - might have very few or no valid positions
      y_shape = [{0, 1}, {1, 0}, {1, 1}, {1, 2}, {2, 0}]
      valid = Board.valid_positions(y_shape, placed_pieces, board_size)
      
      # Should have limited valid positions
      assert length(valid) <= 5  # Very few positions left
    end
  end

  describe "board size validation" do
    test "new game validates board size" do
      # Valid sizes
      assert {:ok, _} = State.new({10, 6})
      assert {:ok, _} = State.new({8, 8})
      assert {:ok, _} = State.new({12, 5})
      assert {:ok, _} = State.new({20, 20})
      
      # Invalid sizes - too small
      assert {:error, _} = State.new({4, 4})
      assert {:error, _} = State.new({10, 5})  # Only 50 cells
      assert {:error, _} = State.new({3, 20})  # Narrow
      
      # Invalid sizes - too large
      assert {:error, _} = State.new({21, 21})
      assert {:error, _} = State.new({100, 100})
    end

    test "board must accommodate all 12 pentominoes" do
      # 12 pentominoes * 5 cells = 60 cells minimum
      
      # Exactly 60 cells
      assert {:ok, _} = State.new({10, 6})
      assert {:ok, _} = State.new({12, 5})
      assert {:ok, _} = State.new({15, 4})
      
      # Less than 60 cells
      assert {:error, _} = State.new({7, 8})   # 56 cells
      assert {:error, _} = State.new({11, 5})  # 55 cells
    end
  end
end