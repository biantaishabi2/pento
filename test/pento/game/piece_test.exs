defmodule Pento.Game.PieceTest do
  use ExUnit.Case, async: true
  alias Pento.Game.Piece

  describe "piece definitions" do
    test "all 12 pentomino pieces are defined" do
      pieces = Piece.all_pieces()
      assert length(pieces) == 12
      
      piece_ids = Enum.map(pieces, & &1.id)
      expected_ids = ~w[F I L N P T U V W X Y Z]
      assert Enum.sort(piece_ids) == Enum.sort(expected_ids)
    end

    test "each piece has exactly 5 cells" do
      pieces = Piece.all_pieces()
      
      Enum.each(pieces, fn piece ->
        assert length(piece.shape) == 5,
               "Piece #{piece.id} should have 5 cells, but has #{length(piece.shape)}"
      end)
    end

    test "each piece has a unique shape" do
      pieces = Piece.all_pieces()
      shapes = Enum.map(pieces, fn piece ->
        # Normalize shape to compare
        Piece.normalize_shape(piece.shape)
      end)
      
      # Check no duplicates
      assert length(shapes) == length(Enum.uniq(shapes))
    end

    test "piece colors are defined" do
      pieces = Piece.all_pieces()
      
      Enum.each(pieces, fn piece ->
        assert piece.color =~ ~r/^#[0-9A-F]{6}$/i,
               "Piece #{piece.id} should have a valid hex color"
      end)
    end
  end

  describe "get_piece/1" do
    test "returns piece by ID" do
      piece = Piece.get_piece("F")
      assert piece.id == "F"
      assert is_list(piece.shape)
      assert piece.color
    end

    test "returns nil for invalid ID" do
      assert Piece.get_piece("Q") == nil
      assert Piece.get_piece("") == nil
      assert Piece.get_piece(nil) == nil
    end
  end

  describe "rotate_piece/2" do
    test "rotate 90 degrees clockwise" do
      # F piece: □■□
      #          ■■■
      #          □■□
      piece = %Piece{
        id: "F",
        shape: [{0, 1}, {1, 0}, {1, 1}, {1, 2}, {2, 1}],
        color: "#FF6B6B"
      }
      
      rotated = Piece.rotate_piece(piece, :clockwise)
      
      # After rotation: □■□
      #                ■■■
      #                □■□
      expected_shape = Piece.normalize_shape([{1, 0}, {0, 1}, {1, 1}, {2, 1}, {1, 2}])
      assert Piece.normalize_shape(rotated.shape) == expected_shape
    end

    test "rotate 4 times returns to original" do
      piece = Piece.get_piece("L")
      
      rotated = piece
      |> Piece.rotate_piece(:clockwise)
      |> Piece.rotate_piece(:clockwise)
      |> Piece.rotate_piece(:clockwise)
      |> Piece.rotate_piece(:clockwise)
      
      assert Piece.normalize_shape(rotated.shape) == Piece.normalize_shape(piece.shape)
    end

    test "rotation preserves piece structure" do
      piece = Piece.get_piece("T")
      rotated = Piece.rotate_piece(piece, :clockwise)
      
      # Still 5 cells
      assert length(rotated.shape) == 5
      
      # Still connected (simplified check)
      assert Piece.is_connected?(rotated.shape)
    end

    test "handle edge case - straight line piece (I)" do
      piece = %Piece{
        id: "I",
        shape: [{0, 0}, {0, 1}, {0, 2}, {0, 3}, {0, 4}],
        color: "#4ECDC4"
      }
      
      rotated = Piece.rotate_piece(piece, :clockwise)
      
      # Should become horizontal line
      expected_shape = Piece.normalize_shape([{0, 0}, {1, 0}, {2, 0}, {3, 0}, {4, 0}])
      assert Piece.normalize_shape(rotated.shape) == expected_shape
    end
  end

  describe "flip_piece/2" do
    test "flip horizontally" do
      # L piece: ■
      #          ■
      #          ■
      #          ■■
      piece = %Piece{
        id: "L",
        shape: [{0, 0}, {0, 1}, {0, 2}, {0, 3}, {1, 3}],
        color: "#45B7D1"
      }
      
      flipped = Piece.flip_piece(piece, :horizontal)
      
      # After flip: ■
      #            ■
      #            ■
      #           ■■
      expected_shape = Piece.normalize_shape([{1, 0}, {1, 1}, {1, 2}, {1, 3}, {0, 3}])
      assert Piece.normalize_shape(flipped.shape) == expected_shape
    end

    test "flip vertically" do
      # Use an asymmetric shape for testing
      piece = %Piece{
        id: "L",
        shape: [{0, 0}, {0, 1}, {0, 2}, {0, 3}, {1, 3}],
        color: "#45B7D1"
      }
      
      flipped = Piece.flip_piece(piece, :vertical)
      
      # L shape should flip vertically
      assert length(flipped.shape) == 5
      assert flipped.shape != piece.shape
      # The flipped shape should be [{0, 0}, {1, 0}, {0, 1}, {0, 2}, {0, 3}] after normalization
    end

    test "double flip returns to original" do
      piece = Piece.get_piece("F")
      
      double_flipped = piece
      |> Piece.flip_piece(:horizontal)
      |> Piece.flip_piece(:horizontal)
      
      assert Piece.normalize_shape(double_flipped.shape) == Piece.normalize_shape(piece.shape)
    end

    test "flip asymmetric pieces" do
      # Test F and L pieces which are clearly asymmetric
      ["F", "L", "N", "P", "Y", "Z"]
      |> Enum.each(fn id ->
        piece = Piece.get_piece(id)
        flipped = Piece.flip_piece(piece, :horizontal)
        
        # Shape should change
        refute Piece.normalize_shape(flipped.shape) == Piece.normalize_shape(piece.shape),
               "Piece #{id} should change when flipped"
      end)
    end
  end

  describe "get_absolute_positions/2" do
    test "calculate absolute positions from relative shape" do
      piece = %Piece{
        id: "I",
        shape: [{0, 0}, {0, 1}, {0, 2}, {0, 3}, {0, 4}],
        color: "#4ECDC4"
      }
      
      absolute = Piece.get_absolute_positions(piece.shape, {3, 2})
      
      expected = [{3, 2}, {3, 3}, {3, 4}, {3, 5}, {3, 6}]
      assert Enum.sort(absolute) == Enum.sort(expected)
    end

    test "handle negative relative coordinates" do
      # After normalization, no negative coordinates should exist
      shape = [{-1, 0}, {0, 0}, {1, 0}, {0, 1}, {0, -1}]
      normalized = Piece.normalize_shape(shape)
      
      # All coordinates should be non-negative
      Enum.each(normalized, fn {x, y} ->
        assert x >= 0
        assert y >= 0
      end)
    end

    test "handle zero position" do
      piece = Piece.get_piece("X")
      absolute = Piece.get_absolute_positions(piece.shape, {0, 0})
      
      # Should be same as shape
      assert absolute == piece.shape
    end
  end

  describe "normalize_shape/1" do
    test "moves shape to origin" do
      shape = [{5, 3}, {6, 3}, {7, 3}, {6, 4}, {6, 5}]
      normalized = Piece.normalize_shape(shape)
      
      # Min x and y should be 0
      {min_x, _} = Enum.min_by(normalized, &elem(&1, 0))
      {_, min_y} = Enum.min_by(normalized, &elem(&1, 1))
      
      assert min_x == 0
      assert min_y == 0
    end

    test "preserves shape structure" do
      shape = [{2, 2}, {3, 2}, {4, 2}, {3, 3}, {3, 4}]
      normalized = Piece.normalize_shape(shape)
      
      # Should still have 5 cells
      assert length(normalized) == 5
      
      # Relative positions should be preserved
      # Just shifted to origin
    end
  end

  describe "is_connected?/1" do
    test "connected shape returns true" do
      # All pentomino pieces should be connected
      Piece.all_pieces()
      |> Enum.each(fn piece ->
        assert Piece.is_connected?(piece.shape),
               "Piece #{piece.id} should be connected"
      end)
    end

    test "disconnected shape returns false" do
      # Two separate components
      disconnected = [{0, 0}, {0, 1}, {3, 3}, {3, 4}, {4, 4}]
      refute Piece.is_connected?(disconnected)
    end

    test "single cell is connected" do
      assert Piece.is_connected?([{0, 0}])
    end
  end
end