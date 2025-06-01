#!/usr/bin/env elixir

# 测试拖放问题
# 运行: cd /home/wangbo/document/pento && mix run test_drop_issue.exs

# 确保应用启动
Application.ensure_all_started(:pento)

defmodule TestDropIssue do
  def run do
    IO.puts("\n=== 测试拖放问题 ===\n")
    
    # 模拟组件assigns
    assigns = %{
      board_size: {10, 6},
      placed_pieces: [],
      dragging: true,  # 关键：这里应该是true
      cursor: {0, 0},
      ghost_position: {0, 0},
      ghost_piece: %{
        id: "X",
        color: "#FF8B94",
        shape: [{1, 0}, {0, 1}, {1, 1}, {2, 1}, {1, 2}]
      },
      valid_positions: [{0, 0}, {1, 0}, {2, 0}],
      cell_size: 30,
      svg_width: 300,
      svg_height: 180,
      cols: 10,
      rows: 6
    }
    
    # 直接测试组件渲染
    html = PentoWeb.Components.GameBoard.board(assigns)
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
    
    # 检查结果
    IO.puts("1. 检查HTML中是否包含drop_at_cell:")
    if String.contains?(html, "drop_at_cell") do
      IO.puts("   ✅ 找到drop_at_cell")
      
      # 计算出现次数
      count = html
      |> String.split("drop_at_cell")
      |> length()
      |> Kernel.-(1)
      
      IO.puts("   出现次数: #{count}")
    else
      IO.puts("   ❌ 没有找到drop_at_cell")
    end
    
    IO.puts("\n2. 检查valid-positions-layer:")
    if String.contains?(html, "valid-positions-layer") do
      IO.puts("   ✅ 找到valid-positions-layer")
    else
      IO.puts("   ❌ 没有找到valid-positions-layer")
    end
    
    # 输出前1000个字符看看
    IO.puts("\n3. HTML前1000个字符:")
    IO.puts(String.slice(html, 0, 1000))
    
    # 查找第一个rect的phx-click属性
    IO.puts("\n4. 查找rect元素的phx-click属性:")
    case Regex.run(~r/<rect[^>]*phx-click="([^"]*)"/, html) do
      [_, value] -> IO.puts("   找到: phx-click=\"#{value}\"")
      nil -> IO.puts("   ❌ 没有找到带phx-click的rect元素")
    end
  end
end

TestDropIssue.run()