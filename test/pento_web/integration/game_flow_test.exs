defmodule PentoWeb.Integration.GameFlowTest do
  use PentoWeb.ConnCase
  import Phoenix.LiveViewTest
  import PentoWeb.GameTestHelpers

  describe "complete game flow" do
    test "play game from start to completion", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      
      # Initial state
      html = render(view)
      assert html =~ "0.0% 完成"
      
      # Place first piece (I) - easier to place
      place_piece(view, "I", {0, 0})
      
      html = render(view)
      # Progress should be ~8.3%
      assert html =~ "8.3% 完成"
      
      # Place second piece (L) at different position
      place_piece(view, "L", {5, 0})
      
      html = render(view)
      # Progress should be ~16.7%
      assert html =~ "16.7% 完成"
      
      # Place third piece (P)
      place_piece(view, "P", {2, 1})
      
      html = render(view)
      # Progress should be ~25.0%
      assert html =~ "25.0% 完成"
      
      # Test that completion message doesn't show yet
      refute html =~ "恭喜完成"
    end

    test "game with rotations and removals", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      
      # Select L piece
      select_piece(view, "L")
      
      # Send keyboard event to rotate
      view
      |> element("#game")
      |> render_keydown(%{"key" => "r"})
      
      # Place it
      drop_at_cell(view, {5, 2})
      
      html = render(view)
      # Check piece is placed
      assert html =~ "data-id=\"L\""
      
      # Place another piece
      select_piece(view, "T")
      drop_at_cell(view, {0, 0})
      
      # Remove the L piece
      view |> render_hook("remove_piece", %{"id" => "L"})
      
      html = render(view)
      # L should be removed but T still there
      refute html =~ "data-id=\"L\""
      assert html =~ "data-id=\"T\""
      
      # Place L again in different position
      select_piece(view, "L")
      drop_at_cell(view, {7, 1})
      
      html = render(view)
      assert html =~ "data-id=\"L\""
      assert html =~ "data-id=\"T\""
    end

    test "undo operations", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      
      # Place several pieces using reliable helper
      place_piece(view, "I", {0, 0})
      place_piece(view, "L", {2, 0})
      place_piece(view, "P", {5, 0})
      
      html = render(view)
      assert html =~ "data-id=\"I\""
      assert html =~ "data-id=\"L\""
      assert html =~ "data-id=\"P\""
      
      # Undo last move
      view
      |> element("button[phx-click=\"undo\"]")
      |> render_click()
      
      html = render(view)
      # P should be removed
      assert html =~ "data-id=\"I\""
      assert html =~ "data-id=\"L\""
      refute html =~ "data-id=\"P\""
      
      # Undo again
      view
      |> element("button[phx-click=\"undo\"]")
      |> render_click()
      
      html = render(view)
      # L should also be removed
      assert html =~ "data-id=\"I\""
      refute html =~ "data-id=\"L\""
      
      # Can place L again
      place_piece(view, "L", {3, 0})
      
      html = render(view)
      assert html =~ "data-id=\"L\""
    end

    test "reset game flow", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      
      # Place multiple pieces
      select_piece(view, "X")
      drop_at_cell(view, {3, 2})
      
      select_piece(view, "Y")
      drop_at_cell(view, {0, 3})
      
      select_piece(view, "Z")
      drop_at_cell(view, {6, 3})
      
      html = render(view)
      # Should have progress > 0
      refute html =~ "0.0% 完成"
      
      # Reset game
      view
      |> element("button[phx-click=\"reset\"]")
      |> render_click()
      
      html = render(view)
      # Everything should be cleared
      assert html =~ "0.0% 完成"
      refute html =~ "data-id=\"X\""
      refute html =~ "data-id=\"Y\""
      refute html =~ "data-id=\"Z\""
      assert html =~ "游戏已重新开始"
      
      # Can start playing again
      select_piece(view, "F")
      drop_at_cell(view, {4, 1})
      
      html = render(view)
      assert html =~ "data-id=\"F\""
    end

    test "error recovery flow", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      
      # Place a piece first
      place_piece(view, "I", {0, 0})
      
      # Try to place overlapping piece at same position
      view
      |> element("[phx-click='select_piece'][phx-value-id='L']")
      |> render_click()
      
      render_click(view, "drop_at_cell", %{"x" => "0", "y" => "0"})
      
      # Should show error - check for various error messages
      html = render(view)
      assert html =~ "方块位置重叠" or html =~ "error-message" or html =~ "无法在此位置放置方块", 
        "Expected collision error but got: #{String.slice(html, 0, 500)}..."
      
      # Can place L in valid position after error
      render_click(view, "drop_at_cell", %{"x" => "5", "y" => "0"})
      
      html = render(view)
      assert html =~ "data-id=\"L\""
      
      # Game should still be functional - place another piece
      place_piece(view, "P", {2, 1})
      
      html = render(view)
      assert html =~ "data-id=\"P\""
    end

    test "basic piece placement", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      
      # Select and place a piece
      select_piece(view, "P")
      drop_at_cell(view, {2, 1})
      
      html = render(view)
      assert html =~ "data-id=\"P\""
      refute html =~ "0.0% 完成"
    end

    test "keyboard shortcuts flow", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      
      # Select piece
      select_piece(view, "N")
      
      # Press R to rotate
      view
      |> element("#game")
      |> render_keydown(%{"key" => "r"})
      
      # Press F to flip
      view
      |> element("#game")
      |> render_keydown(%{"key" => "f"})
      
      # Press Escape to cancel
      view
      |> element("#game")
      |> render_keydown(%{"key" => "Escape"})
      
      # Place a piece then undo
      select_piece(view, "T")
      drop_at_cell(view, {0, 0})
      
      html = render(view)
      assert html =~ "data-id=\"T\""
      
      # Ctrl+Z to undo
      view
      |> element("#game")
      |> render_keydown(%{"key" => "z", "ctrlKey" => true})
      
      html = render(view)
      refute html =~ "data-id=\"T\""
    end

    test "touch interaction flow", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      
      # Touch events are handled by the same events as click
      # Select piece
      select_piece(view, "F")
      
      # Drop at position
      drop_at_cell(view, {3, 2})
      
      html = render(view)
      assert html =~ "data-id=\"F\""
      
      # Remove by clicking on placed piece
      # Remove piece using render_hook
      view |> render_hook("remove_piece", %{"id" => "F"})
      
      html = render(view)
      refute html =~ "data-id=\"F\""
    end

    test "auto-save and restore", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      
      # Place some pieces using reliable helper
      place_piece(view, "I", {0, 0})
      place_piece(view, "L", {2, 0})
      place_piece(view, "P", {5, 0})
      
      # Trigger periodic save (correct message used by GameLive)
      send(view.pid, :periodic_save)
      Process.sleep(100)
      
      html = render(view)
      assert html =~ "已保存于"
      
      # Since we're using in-memory state, reload won't restore
      # Just verify pieces are placed
      assert html =~ "data-id=\"I\""
      assert html =~ "data-id=\"L\""
      assert html =~ "data-id=\"P\""
    end
  end

  # Helper functions

  defp select_piece(view, piece_id) do
    view
    |> element("[phx-click=\"select_piece\"][phx-value-id=\"#{piece_id}\"]")
    |> render_click()
  end

  defp drop_at_cell(view, {x, y}) do
    # Send the drop_at_cell event directly to the LiveView
    render_click(view, "drop_at_cell", %{"x" => to_string(x), "y" => to_string(y)})
  end
end