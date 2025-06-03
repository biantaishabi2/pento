defmodule PentoWeb.ClickDetectionTest do
  use PentoWeb.ConnCase
  import Phoenix.LiveViewTest
  
  alias Pento.Game
  alias Pento.Game.{Board, Piece}

  describe "click detection improvements" do
    test "can click on any cell of a valid piece placement", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      
      # Select U piece
      view |> element("[phx-click=\"select_piece\"][phx-value-id=\"U\"]") |> render_click()
      
      # Get game state
      game_state = :sys.get_state(view.pid).socket.assigns.game_state
      assert game_state.current_piece.id == "U"
      
      # Verify clickable positions include more than just top-left corners
      clickable = Game.clickable_positions(game_state)
      valid = Game.valid_positions(game_state)
      
      assert length(clickable) > length(valid)
    end
    
    test "smart placement finds best position when clicking", %{conn: conn} do
      # Create a game with I piece already placed
      game = Game.new_game()
      {:ok, game} = Game.select_piece(game, "I")
      {:ok, game} = Game.place_piece(game, {0, 0})
      
      # Select U piece
      {:ok, game} = Game.select_piece(game, "U")
      
      # Test clicking on different positions
      test_cases = [
        {{2, 0}, :success},  # Empty position
        {{3, 0}, :success},  # Part of valid U placement
        {{0, 0}, :error},    # Occupied by I, no valid placement
        {{1, 0}, :success}   # Adjacent to I, valid placement exists
      ]
      
      for {click_pos, expected} <- test_cases do
        result = Game.smart_place_piece(game, click_pos)
        
        case expected do
          :success ->
            assert {:ok, _} = result
          :error ->
            assert {:error, _} = result
        end
      end
    end
    
    test "visual feedback shows all clickable positions", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      
      # Place I piece
      view |> element("[phx-click=\"select_piece\"][phx-value-id=\"I\"]") |> render_click()
      view |> element("[phx-click=\"drop_at_cell\"][phx-value-x=\"0\"][phx-value-y=\"0\"]") |> render_click()
      
      # Select U piece
      view |> element("[phx-click=\"select_piece\"][phx-value-id=\"U\"]") |> render_click()
      
      # Check that valid positions are highlighted
      html = render(view)
      
      # Should see valid position indicators
      assert html =~ "valid-position"
      
      # Count valid position indicators
      valid_count = html
      |> String.split("valid-position")
      |> length()
      |> Kernel.-(1)
      
      # Should have more valid positions than just corner positions
      assert valid_count > 30
    end
  end
  
  describe "edge cases" do
    test "clicking occupied cell triggers placement if valid", %{conn: conn} do
      # Create specific scenario
      game = Game.new_game()
      
      # Place L piece to create interesting occupied positions
      {:ok, game} = Game.select_piece(game, "L")
      {:ok, game} = Game.place_piece(game, {2, 1})
      
      # Select T piece
      {:ok, game} = Game.select_piece(game, "T")
      
      # Click on position that's part of valid T placement
      result = Game.smart_place_piece(game, {4, 2})
      
      assert {:ok, new_game} = result
      assert length(new_game.placed_pieces) == 2
    end
    
    test "find_valid_placements_for_click returns all possibilities" do
      # Simple test case
      u_shape = [{0, 0}, {0, 1}, {1, 1}, {2, 0}, {2, 1}]
      
      # Click in middle of empty board
      placements = Board.find_valid_placements_for_click(
        {5, 3},
        u_shape,
        [],
        {10, 6}
      )
      
      # Should find multiple valid placements
      assert length(placements) > 0
      
      # Verify each placement would include the clicked cell
      for placement <- placements do
        absolute = Piece.get_absolute_positions(u_shape, placement)
        assert {5, 3} in absolute
      end
    end
  end
end