#!/usr/bin/env elixir

# 调试脚本：测试拖放功能
# 运行: elixir test_drag_drop.exs

Mix.install([
  {:phoenix_live_view, "~> 0.20.0"},
  {:floki, "~> 0.35.0"}
])

defmodule DragDropTest do
  def run do
    IO.puts("\n=== 测试拖放功能 ===\n")
    
    # 启动应用
    Application.ensure_all_started(:logger)
    
    # 模拟游戏状态
    game_state = %{
      board_size: {10, 6},
      placed_pieces: [],
      current_piece: %{
        id: "T",
        color: "#DDA0DD",
        shape: [{0, 0}, {1, 0}, {2, 0}, {1, 1}, {1, 2}]
      },
      available_pieces: []
    }
    
    # 测试不同的拖拽状态
    test_dragging_false(game_state)
    test_dragging_true(game_state)
  end
  
  defp test_dragging_false(game_state) do
    IO.puts("1. 测试 dragging=false 时的渲染：")
    
    assigns = %{
      board_size: game_state.board_size,
      placed_pieces: game_state.placed_pieces,
      dragging: false,
      cursor: {0, 0},
      ghost_position: nil,
      ghost_piece: nil,
      valid_positions: [],
      cell_size: 30
    }
    
    html = render_board(assigns)
    
    # 检查是否有 drop_at_cell
    if String.contains?(html, "phx-click=\"drop_at_cell\"") do
      IO.puts("  ❌ 错误：dragging=false 时仍然有 drop_at_cell 事件")
    else
      IO.puts("  ✅ 正确：dragging=false 时没有 drop_at_cell 事件")
    end
    
    # 计算有多少个 grid-cell
    grid_cells = Floki.find(html, ".grid-cell")
    IO.puts("  格子总数：#{length(grid_cells)}")
    
    # 检查第一个格子的属性
    if length(grid_cells) > 0 do
      first_cell = hd(grid_cells)
      phx_click = Floki.attribute(first_cell, "phx-click")
      IO.puts("  第一个格子的 phx-click 属性：#{inspect(phx_click)}")
    end
  end
  
  defp test_dragging_true(game_state) do
    IO.puts("\n2. 测试 dragging=true 时的渲染：")
    
    assigns = %{
      board_size: game_state.board_size,
      placed_pieces: game_state.placed_pieces,
      dragging: true,
      cursor: {0, 0},
      ghost_position: {0, 0},
      ghost_piece: game_state.current_piece,
      valid_positions: [{0, 0}, {1, 0}, {2, 0}, {3, 0}],
      cell_size: 30
    }
    
    html = render_board(assigns)
    
    # 检查是否有 drop_at_cell
    if String.contains?(html, "phx-click=\"drop_at_cell\"") do
      IO.puts("  ✅ 正确：dragging=true 时有 drop_at_cell 事件")
    else
      IO.puts("  ❌ 错误：dragging=true 时没有 drop_at_cell 事件")
    end
    
    # 计算有多少个带 phx-click 的格子
    clickable_cells = Floki.find(html, "[phx-click=\"drop_at_cell\"]")
    IO.puts("  可点击的格子数：#{length(clickable_cells)}")
    
    # 检查有效位置层
    if String.contains?(html, "valid-positions-layer") do
      IO.puts("  ✅ 有效位置层已显示")
    else
      IO.puts("  ❌ 有效位置层未显示")
    end
    
    # 检查第一个格子的属性
    grid_cells = Floki.find(html, ".grid-cell")
    if length(grid_cells) > 0 do
      first_cell = hd(grid_cells)
      attrs = Floki.raw_html(first_cell, encode: false)
      IO.puts("  第一个格子的HTML：")
      IO.puts("  #{attrs}")
    end
  end
  
  defp render_board(assigns) do
    # 模拟组件渲染
    {cols, rows} = assigns.board_size
    svg_width = cols * assigns.cell_size
    svg_height = rows * assigns.cell_size
    
    grid_cells = for x <- 0..(cols - 1), y <- 0..(rows - 1) do
      phx_click = if assigns.dragging, do: ~s(phx-click="drop_at_cell"), else: ""
      """
      <rect
        x="#{x * assigns.cell_size}"
        y="#{y * assigns.cell_size}"
        width="#{assigns.cell_size}"
        height="#{assigns.cell_size}"
        fill="transparent"
        stroke="#e5e7eb"
        stroke-width="1"
        class="grid-cell hover:fill-gray-100"
        #{phx_click}
        phx-value-x="#{x}"
        phx-value-y="#{y}"
      />
      """
    end
    
    valid_positions_layer = if assigns.dragging do
      """
      <g class="valid-positions-layer">
        #{Enum.map(assigns.valid_positions, fn {x, y} ->
          """
          <rect
            x="#{x * assigns.cell_size}"
            y="#{y * assigns.cell_size}"
            width="#{assigns.cell_size}"
            height="#{assigns.cell_size}"
            fill="#10b981"
            fill-opacity="0.2"
            class="valid-position animate-pulse"
          />
          """
        end) |> Enum.join("\n")}
      </g>
      """
    else
      ""
    end
    
    """
    <svg width="#{svg_width}" height="#{svg_height}">
      <g class="grid-layer">
        #{Enum.join(grid_cells, "\n")}
      </g>
      #{valid_positions_layer}
    </svg>
    """
  end
end

DragDropTest.run()