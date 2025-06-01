defmodule PentoWeb.GameLiveIntegrationTest do
  use PentoWeb.ConnCase
  import Phoenix.LiveViewTest

  test "placing a piece works correctly", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    
    # Select a piece
    assert view |> element("[phx-click='select_piece'][phx-value-id='T']") |> render_click()
    
    # The piece should be selected (dragging = true)
    assert view |> has_element?("[phx-click='drop_at_cell']")
    
    # Click on a cell to place the piece
    assert view |> element("[phx-click='drop_at_cell'][phx-value-x='0'][phx-value-y='0']") |> render_click()
    
    # Check if piece was placed
    html = render(view)
    assert html =~ "移除 T" # The debug button should show
    
    # Try to remove the piece using the debug button
    assert view |> element("button[phx-click='remove_piece'][phx-value-id='T']") |> render_click()
    
    # The piece should be removed
    html = render(view)
    refute html =~ "移除 T"
  end
end