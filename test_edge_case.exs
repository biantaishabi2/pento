#!/usr/bin/env elixir

# 测试边缘情况
# 运行: mix run test_edge_case.exs

Code.require_file("lib/pento/game/piece.ex")
Code.require_file("lib/pento/game/board.ex")
Code.require_file("lib/pento/game/state.ex")
Code.require_file("lib/pento/game.ex")

alias Pento.Game.{Board, Piece}

defmodule EdgeCaseTester do
  def test_occupied_click do
    IO.puts("\n=== 测试点击被占用位置的边缘情况 ===\n")
    
    # 创建测试场景
    i_piece = Piece.get_piece("I")
    placed_i = %{
      id: "I",
      shape: i_piece.shape,
      position: {0, 0},
      color: i_piece.color
    }
    
    u_piece = Piece.get_piece("U")
    
    IO.puts("场景设置：")
    IO.puts("- I型方块在{0,0}，占用: #{inspect(Piece.get_absolute_positions(i_piece.shape, {0, 0}))}")
    IO.puts("- 尝试放置U型方块: #{inspect(u_piece.shape)}")
    
    # 测试点击{0,0}时能找到的有效放置
    click_pos = {0, 0}
    IO.puts("\n点击位置 #{inspect(click_pos)} 时：")
    
    valid_placements = Board.find_valid_placements_for_click(
      click_pos,
      u_piece.shape,
      [placed_i],
      {10, 6}
    )
    
    IO.puts("找到的有效放置位置: #{inspect(valid_placements)}")
    
    # 对于U型方块，如果{0,0}是它的某个格子位置，反推方块左上角
    IO.puts("\n分析：")
    u_piece.shape
    |> Enum.with_index()
    |> Enum.each(fn {{dx, dy}, idx} ->
      top_left = {elem(click_pos, 0) - dx, elem(click_pos, 1) - dy}
      IO.puts("- 如果点击的是U型方块的第#{idx+1}个格子#{inspect({dx, dy})}，则左上角应在: #{inspect(top_left)}")
    end)
    
    # 测试一个更复杂的场景
    test_complex_scenario()
  end
  
  def test_complex_scenario do
    IO.puts("\n\n=== 复杂场景测试 ===")
    
    # 放置多个方块
    placed_pieces = [
      %{id: "I", shape: [{0, 0}, {0, 1}, {0, 2}, {0, 3}, {0, 4}], position: {0, 0}, color: "#4ECDC4"},
      %{id: "L", shape: [{0, 0}, {0, 1}, {0, 2}, {0, 3}, {1, 3}], position: {1, 0}, color: "#45B7D1"}
    ]
    
    IO.puts("已放置的方块：")
    occupied = Board.get_occupied_cells(placed_pieces)
    IO.puts("占用的位置: #{inspect(Enum.sort(occupied))}")
    
    # 尝试放置T型方块
    t_piece = Piece.get_piece("T")
    IO.puts("\nT型方块形状: #{inspect(t_piece.shape)}")
    
    # 测试点击各个位置
    test_positions = [{0, 0}, {1, 1}, {2, 0}, {3, 3}]
    
    Enum.each(test_positions, fn click_pos ->
      IO.puts("\n点击位置 #{inspect(click_pos)}:")
      
      valid_placements = Board.find_valid_placements_for_click(
        click_pos,
        t_piece.shape,
        placed_pieces,
        {10, 6}
      )
      
      case valid_placements do
        [] -> 
          IO.puts("  ✗ 无法在此位置放置方块")
        placements ->
          IO.puts("  ✓ 可以放置在: #{inspect(placements)}")
          # 显示第一个放置选项
          if placement = List.first(placements) do
            occupied_cells = Piece.get_absolute_positions(t_piece.shape, placement)
            IO.puts("    占用格子: #{inspect(occupied_cells)}")
          end
      end
    end)
  end
end

# 运行测试
EdgeCaseTester.test_occupied_click()