defmodule PentoWeb.GameLiveDebugTest do
  use PentoWeb.ConnCase
  import Phoenix.LiveViewTest

  describe "debug drag and drop" do
    test "debug HTML output when dragging", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      
      # 选择一个拼图块
      view
      |> element("[phx-click=\"select_piece\"][phx-value-id=\"T\"]")
      |> render_click()
      
      # 获取完整的HTML
      html = render(view)
      
      # 保存到文件以便检查
      File.write!("debug_output.html", html)
      
      # 检查关键元素
      IO.puts("\n=== HTML调试输出 ===")
      
      # 1. 检查是否有drop_at_cell
      if String.contains?(html, "drop_at_cell") do
        IO.puts("✅ 找到 drop_at_cell")
        
        # 提取包含drop_at_cell的行
        html
        |> String.split("\n")
        |> Enum.filter(&String.contains?(&1, "drop_at_cell"))
        |> Enum.take(3)
        |> Enum.each(fn line ->
          IO.puts("   " <> String.trim(line))
        end)
      else
        IO.puts("❌ 没有找到 drop_at_cell")
      end
      
      # 2. 检查valid-positions-layer
      if String.contains?(html, "valid-positions-layer") do
        IO.puts("✅ 找到 valid-positions-layer")
      else
        IO.puts("❌ 没有找到 valid-positions-layer")
      end
      
      # 3. 查找第一个grid-cell
      case Regex.run(~r/<rect[^>]*class="grid-cell[^"]*"[^>]*>/, html) do
        [match] -> 
          IO.puts("\n第一个grid-cell元素:")
          IO.puts(match)
        nil ->
          IO.puts("\n❌ 没有找到grid-cell元素")
      end
      
      # 4. 检查@dragging的值
      # 通过检查是否有valid-positions-layer来间接判断
      dragging_state = String.contains?(html, "valid-positions-layer")
      IO.puts("\n推断的dragging状态: #{dragging_state}")
    end
  end
end