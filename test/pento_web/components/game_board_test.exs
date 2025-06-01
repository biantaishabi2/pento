defmodule PentoWeb.Components.GameBoardTest do
  use PentoWeb.ComponentCase, async: true
  alias PentoWeb.Components.GameBoard

  describe "board/1" do
    test "renders board with correct dimensions" do
      assigns = %{
        board_size: {8, 6},
        placed_pieces: [],
        dragging: false,
        cursor: {0, 0},
        ghost_position: nil,
        valid_positions: [],
        cell_size: 30
      }
      
      html = render_test_component(&GameBoard.board/1, assigns)
      
      # Check SVG dimensions in viewBox instead of width/height
      assert html =~ ~s(viewBox="0 0 240 180")  # 8 * 30 x 6 * 30
      assert html =~ "game-board"
      assert html =~ "w-full h-auto"  # Responsive sizing
    end

    test "renders placed pieces" do
      placed_pieces = [
        %{
          id: "F",
          shape: [{0, 1}, {1, 0}, {1, 1}, {1, 2}, {2, 1}],
          position: {2, 1},
          color: "#FF6B6B"
        }
      ]
      
      assigns = %{
        board_size: {10, 6},
        placed_pieces: placed_pieces,
        dragging: false,
        cursor: {0, 0},
        ghost_position: nil,
        valid_positions: [],
        cell_size: 30
      }
      
      html = render_test_component(&GameBoard.board/1, assigns)
      
      # Check piece is rendered
      assert html =~ ~s(data-id="F")
      assert html =~ "#FF6B6B"
      assert html =~ "placed-piece"
    end

    test "shows ghost piece when dragging" do
      assigns = %{
        board_size: {10, 6},
        placed_pieces: [],
        dragging: true,
        cursor: {3, 2},
        ghost_position: {3, 2},
        ghost_piece: %{
          shape: [{0,0}, {1,0}, {2,0}, {1,1}, {1,2}],
          color: "#DDA0DD"
        },
        valid_positions: [{3, 2}],
        cell_size: 30
      }
      
      html = render_test_component(&GameBoard.board/1, assigns)
      
      # Ghost piece should be visible
      assert html =~ "ghost-piece-layer"
      assert html =~ "opacity=\"0.5\""
    end

    test "highlights valid positions when dragging" do
      assigns = %{
        board_size: {10, 6},
        placed_pieces: [],
        dragging: true,
        cursor: {0, 0},
        ghost_position: nil,
        valid_positions: [{2, 1}, {5, 3}],
        cell_size: 30
      }
      
      html = render_test_component(&GameBoard.board/1, assigns)
      
      # Check highlights
      assert html =~ "valid-position"
    end

    test "shows cursor indicator when dragging" do
      assigns = %{
        board_size: {10, 6},
        placed_pieces: [],
        dragging: true,
        cursor: {4, 3},
        ghost_position: nil,
        valid_positions: [],
        cell_size: 30
      }
      
      html = render_test_component(&GameBoard.board/1, assigns)
      
      # Cursor indicator
      assert html =~ "cursor-indicator"
    end
  end
end