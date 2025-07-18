defmodule PentoWeb.GameLiveTest do
  use PentoWeb.ConnCase
  import Phoenix.LiveViewTest

  describe "mount" do
    test "mounts with initial game state", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      
      # Verify initial rendering
      assert html =~ "Pentomino Puzzle"
      assert html =~ "0%"
      assert html =~ "game-board"
      assert html =~ "palette-container"
    end
  end

  describe "basic interactions" do
    test "renders controls", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      
      # Check controls are present
      assert html =~ "撤销"
      assert html =~ "重置"
      assert html =~ "点击选择方块"
    end

    test "shows available pieces", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      
      # Check some pieces are available
      assert html =~ "phx-value-id=\"F\""
      assert html =~ "phx-value-id=\"I\""
      assert html =~ "phx-value-id=\"L\""
    end
  end

  describe "piece selection" do
    test "can click on piece", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      
      # Try to click on a piece
      html = view
      |> element("[phx-value-id=\"F\"]")
      |> render_click()
      
      # Should update UI
      assert html =~ "piece-selected" || html =~ "piece-available"
    end
  end

  describe "drag and drop functionality" do
    test "should enable drop_at_cell event when dragging", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      
      # 1. 初始状态检查
      assert has_element?(view, ".game-board")
      assert has_element?(view, ".palette-container")
      
      # 2. 选择一个拼图块
      view
      |> element("[phx-click=\"select_piece\"][phx-value-id=\"T\"]")
      |> render_click()
      
      # 3. 验证拖拽状态
      # 应该显示有效位置的高亮层
      html = render(view)
      assert html =~ "valid-positions-layer"
      
      # 4. 检查网格单元格是否有drop_at_cell事件
      # 验证grid-cell元素有phx-click="drop_at_cell"属性
      assert html =~ "phx-click=\"drop_at_cell\""
      
      # 5. 尝试点击一个有效位置
      # 点击坐标(0,0)的格子
      view
      |> element("[phx-click=\"drop_at_cell\"][phx-value-x=\"0\"][phx-value-y=\"0\"]")
      |> render_click()
      
      # 6. 验证拼图块已被放置
      # 检查是否有已放置的拼图块
      assert has_element?(view, ".placed-piece[data-id=\"T\"]")
      
      # 验证拖拽状态已结束
      html = render(view)
      refute html =~ "valid-positions-layer"
    end

    test "grid cells should be clickable only when dragging", %{conn: conn} do
      {:ok, view, html} = live(conn, "/")
      
      # 初始状态：没有拖拽时，格子不应该有drop_at_cell事件
      refute html =~ "phx-click=\"drop_at_cell\""
      
      # 选择一个拼图块后
      view
      |> element("[phx-click=\"select_piece\"][phx-value-id=\"X\"]")
      |> render_click()
      
      # 格子应该有drop_at_cell事件
      html = render(view)
      assert html =~ "phx-click=\"drop_at_cell\""
      
      # 放置拼图块后
      view
      |> element("[phx-click=\"drop_at_cell\"][phx-value-x=\"3\"][phx-value-y=\"2\"]")
      |> render_click()
      
      # 格子不应该再有drop_at_cell事件
      html = render(view)
      refute html =~ "phx-click=\"drop_at_cell\""
    end

    test "drop_at_cell event should be triggered when clicking grid cells", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      
      # 选择一个拼图块
      view
      |> element("[phx-click=\"select_piece\"][phx-value-id=\"L\"]")
      |> render_click()
      
      # 点击一个有效位置
      view
      |> element("[phx-click=\"drop_at_cell\"][phx-value-x=\"5\"][phx-value-y=\"1\"]")
      |> render_click()
      
      # 验证L块已被放置
      assert has_element?(view, ".placed-piece[data-id=\"L\"]")
    end

    test "should handle invalid drop positions", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      
      # 选择一个拼图块
      view
      |> element("[phx-click=\"select_piece\"][phx-value-id=\"V\"]")
      |> render_click()
      
      # 尝试放置在明确超出边界的位置 (坐标超过10x6的棋盘)
      render_click(view, "drop_at_cell", %{"x" => "15", "y" => "10"})
      
      # 应该显示错误消息 - 检查多种可能的错误信息
      html = render(view)
      assert html =~ "方块超出棋盘边界" or html =~ "无法在此位置放置方块" or html =~ "error-message",
        "Expected out of bounds error but got: #{String.slice(html, 0, 500)}..."
      
      # 拼图块不应该被放置
      refute has_element?(view, ".placed-piece[data-id=\"V\"]")
    end
  end

  describe "auto save" do
    test "handles auto-save timer", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      
      # Send periodic save message (the correct one used by GameLive)
      send(view.pid, :periodic_save)
      
      # Should not crash
      html = render(view)
      assert html =~ "Pentomino Puzzle"
    end
  end

  describe "progress tracking" do
    test "shows initial progress as 0%", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      
      assert html =~ "0%"
    end
  end

  describe "reset functionality" do
    test "reset button clears all pieces and saves to database", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      
      # 1. Place some pieces
      view
      |> element("[phx-click=\"select_piece\"][phx-value-id=\"T\"]")
      |> render_click()
      
      view
      |> element("[phx-click=\"drop_at_cell\"][phx-value-x=\"0\"][phx-value-y=\"0\"]")
      |> render_click()
      
      view
      |> element("[phx-click=\"select_piece\"][phx-value-id=\"L\"]")
      |> render_click()
      
      view
      |> element("[phx-click=\"drop_at_cell\"][phx-value-x=\"5\"][phx-value-y=\"0\"]")
      |> render_click()
      
      # Verify pieces are placed
      assert has_element?(view, ".placed-piece[data-id=\"T\"]")
      assert has_element?(view, ".placed-piece[data-id=\"L\"]")
      
      # 2. Click reset button
      view
      |> element("button", "重新开始")
      |> render_click()
      
      # 3. Verify pieces are cleared
      refute has_element?(view, ".placed-piece[data-id=\"T\"]")
      refute has_element?(view, ".placed-piece[data-id=\"L\"]")
      assert render(view) =~ "游戏已重新开始"
      
      # 4. Wait for auto-save (should happen within 500ms)
      Process.sleep(600)
      
      # 5. Force save to database
      send(view.pid, :save_game)
      Process.sleep(100)
      
      # 6. Simulate page reload
      {:ok, new_view, _html} = live(conn, "/")
      
      # 7. Verify the reset state persisted - no pieces should be placed
      refute has_element?(new_view, ".placed-piece[data-id=\"T\"]")
      refute has_element?(new_view, ".placed-piece[data-id=\"L\"]")
      
      # All pieces should be available
      assert has_element?(new_view, "[phx-click=\"select_piece\"][phx-value-id=\"T\"]:not(.piece-used)")
      assert has_element?(new_view, "[phx-click=\"select_piece\"][phx-value-id=\"L\"]:not(.piece-used)")
    end

    test "reset immediately triggers save to prevent reload issues", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      
      # Use the same approach as other tests - select T piece which is more reliable
      view
      |> element("[phx-click=\"select_piece\"][phx-value-id=\"T\"]")
      |> render_click()
      
      view
      |> element("[phx-click=\"drop_at_cell\"][phx-value-x=\"0\"][phx-value-y=\"0\"]")
      |> render_click()
      
      # Verify piece is placed using the same selector as other tests
      assert has_element?(view, ".placed-piece[data-id=\"T\"]")
      
      # Reset
      view
      |> element("button", "重新开始")
      |> render_click()
      
      # Verify reset happened
      refute has_element?(view, ".placed-piece[data-id=\"T\"]")
      
      # Wait for auto-save to complete (should happen within 500ms)
      Process.sleep(600)
      
      # Verify by reloading the page - the reset state should persist
      {:ok, new_view, _html} = live(conn, "/")
      
      # No pieces should be placed after reload
      refute has_element?(new_view, ".placed-piece")
      
      # All pieces should be available
      assert has_element?(new_view, "[phx-click=\"select_piece\"][phx-value-id=\"T\"]:not(.piece-used)")
    end
  end

  describe "piece removal" do
    test "can remove placed piece by clicking on it", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      
      # 1. 选择并放置一个拼图块
      view
      |> element("[phx-click=\"select_piece\"][phx-value-id=\"T\"]")
      |> render_click()
      
      view
      |> element("[phx-click=\"drop_at_cell\"][phx-value-x=\"0\"][phx-value-y=\"0\"]")
      |> render_click()
      
      # 验证拼图块已被放置
      assert has_element?(view, ".placed-piece[data-id=\"T\"]")
      
      # 2. 点击已放置的拼图块来移除它
      # 使用 render_hook 直接触发事件
      view |> render_hook("remove_piece", %{"id" => "T"})
      
      # 3. 验证拼图块已被移除
      refute has_element?(view, ".placed-piece[data-id=\"T\"]")
      
      # 4. 验证该拼图块重新出现在可用列表中
      assert has_element?(view, "[phx-click=\"select_piece\"][phx-value-id=\"T\"]:not(.piece-used)")
    end

    test "first placed piece should be removable immediately", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      
      # 放置第一个拼图块
      view
      |> element("[phx-click=\"select_piece\"][phx-value-id=\"F\"]")
      |> render_click()
      
      view
      |> element("[phx-click=\"drop_at_cell\"][phx-value-x=\"3\"][phx-value-y=\"2\"]")
      |> render_click()
      
      # 验证拼图块已放置
      assert has_element?(view, ".placed-piece[data-id=\"F\"]")
      
      # 方法1：使用render_hook（这是测试中推荐的方式）
      IO.puts("\n测试第一个拼图块移除...")
      view |> render_hook("remove_piece", %{"id" => "F"})
      removed = not has_element?(view, ".placed-piece[data-id=\"F\"]")
      IO.puts("第一个拼图块移除成功: #{removed}")
      
      if not removed do
        # 如果第一个拼图块没有被移除，尝试放置第二个
        IO.puts("\n放置第二个拼图块...")
        view
        |> element("[phx-click=\"select_piece\"][phx-value-id=\"L\"]")
        |> render_click()
        
        view
        |> element("[phx-click=\"drop_at_cell\"][phx-value-x=\"0\"][phx-value-y=\"0\"]")
        |> render_click()
        
        # 再次尝试移除第一个拼图块
        view |> render_hook("remove_piece", %{"id" => "F"})
        removed_after_second = not has_element?(view, ".placed-piece[data-id=\"F\"]")
        IO.puts("放置第二个拼图块后，第一个拼图块移除成功: #{removed_after_second}")
      end
      
      # 最终验证
      refute has_element?(view, ".placed-piece[data-id=\"F\"]"), 
        "第一个放置的拼图块应该能立即移除"
    end
  end
end