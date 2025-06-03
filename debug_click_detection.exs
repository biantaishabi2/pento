#!/usr/bin/env elixir

# 调试Pentomino拼图游戏的点击检测问题
# 在项目环境中运行: mix run debug_click_detection.exs

# 加载项目环境
Code.require_file("lib/pento/game/piece.ex")
Code.require_file("lib/pento/game/board.ex")
Code.require_file("lib/pento/game/state.ex")
Code.require_file("lib/pento/game.ex")

# 定义必要的模块别名
alias Pento.Game
alias Pento.Game.{State, Board, Piece}

defmodule ClickDetectionDebugger do
  @moduledoc """
  调试点击检测问题的工具
  """
  
  def debug_placement_logic do
    IO.puts("\n=== Pentomino点击检测调试 ===\n")
    
    # 创建一个10x6的游戏板
    {:ok, game_state} = State.new({10, 6})
    
    # 选择一个U型方块
    u_piece = Piece.get_piece("U")
    IO.puts("U型方块形状: #{inspect(u_piece.shape)}")
    IO.puts("方块占用的相对位置: #{inspect(u_piece.shape)}")
    
    # 测试场景1: 空板上的有效位置
    IO.puts("\n--- 场景1: 空板上的有效位置 ---")
    valid_positions = Board.valid_positions(u_piece.shape, [], {10, 6})
    IO.puts("空板上的有效位置数量: #{length(valid_positions)}")
    IO.puts("前10个有效位置: #{inspect(Enum.take(valid_positions, 10))}")
    
    # 分析点击位置和方块放置的关系
    IO.puts("\n--- 点击位置与方块放置的关系 ---")
    test_position = {2, 2}
    absolute_positions = Piece.get_absolute_positions(u_piece.shape, test_position)
    IO.puts("如果点击位置是 #{inspect(test_position)}:")
    IO.puts("方块将占用的绝对位置: #{inspect(absolute_positions)}")
    IO.puts("这意味着点击位置 #{inspect(test_position)} 是方块的左上角（第一个格子）")
    
    # 测试场景2: 部分占用时的有效位置
    IO.puts("\n--- 场景2: 部分占用时的有效位置 ---")
    
    # 在板上放置一个I型方块
    i_piece = Piece.get_piece("I")
    placed_i = %{
      id: "I",
      shape: i_piece.shape,
      position: {0, 0},
      color: i_piece.color
    }
    
    IO.puts("已放置I型方块在位置 {0, 0}")
    i_absolute = Piece.get_absolute_positions(i_piece.shape, {0, 0})
    IO.puts("I型方块占用的位置: #{inspect(i_absolute)}")
    
    # 检查U型方块的有效位置
    valid_positions_with_i = Board.valid_positions(u_piece.shape, [placed_i], {10, 6})
    IO.puts("放置I型方块后，U型方块的有效位置数量: #{length(valid_positions_with_i)}")
    
    # 特别测试：点击位置被占用但方块整体可以放置的情况
    IO.puts("\n--- 特殊情况测试 ---")
    
    # U型方块形状: [{0, 0}, {0, 1}, {1, 1}, {2, 0}, {2, 1}]
    # 如果点击位置是{0, 0}（被I占用），但U型方块可以放在{1, 0}
    test_problematic_position = {0, 0}
    IO.puts("\n测试点击位置 #{inspect(test_problematic_position)} (被I占用):")
    IO.puts("这个位置是否在有效位置列表中? #{test_problematic_position in valid_positions_with_i}")
    
    # 检查附近的有效位置
    nearby_valid = valid_positions_with_i
    |> Enum.filter(fn {x, y} -> 
      abs(x - elem(test_problematic_position, 0)) <= 2 and 
      abs(y - elem(test_problematic_position, 1)) <= 2 
    end)
    |> Enum.sort()
    
    IO.puts("附近的有效位置: #{inspect(nearby_valid)}")
    
    # 分析为什么某些位置无法点击
    IO.puts("\n--- 点击检测问题分析 ---")
    IO.puts("1. valid_positions 函数计算的是方块左上角（第一个格子）可以放置的位置")
    IO.puts("2. 如果点击位置已被占用，即使整个方块可以合法放置，该位置也不在valid_positions中")
    IO.puts("3. 这导致用户无法通过点击被占用的位置来放置方块")
    
    # 测试具体案例
    IO.puts("\n--- 具体案例测试 ---")
    
    # 在{1, 0}位置尝试放置U型方块
    test_placement = {1, 0}
    u_at_1_0 = Piece.get_absolute_positions(u_piece.shape, test_placement)
    IO.puts("\nU型方块在位置 #{inspect(test_placement)} 时占用: #{inspect(u_at_1_0)}")
    
    # 检查是否有碰撞
    occupied = Board.get_occupied_cells([placed_i])
    has_collision = Enum.any?(u_at_1_0, fn pos -> MapSet.member?(occupied, pos) end)
    IO.puts("是否有碰撞? #{has_collision}")
    IO.puts("是否在有效位置列表中? #{test_placement in valid_positions_with_i}")
    
    # 建议的解决方案
    IO.puts("\n=== 问题总结与解决方案 ===")
    IO.puts("问题：valid_positions只返回方块左上角可以放置的位置，")
    IO.puts("     如果该位置被占用，即使方块整体可以放置，用户也无法点击。")
    IO.puts("\n可能的解决方案：")
    IO.puts("1. 修改valid_positions逻辑，考虑方块的所有格子作为可能的点击位置")
    IO.puts("2. 在点击处理时，不仅检查点击位置，还检查附近位置是否可以放置方块")
    IO.puts("3. 提供视觉反馈，显示所有可以触发放置的点击区域")
  end
  
  def test_enhanced_valid_positions do
    IO.puts("\n\n=== 测试增强的有效位置检测 ===")
    
    # 创建测试场景
    {:ok, _game_state} = State.new({10, 6})
    u_piece = Piece.get_piece("U")
    
    # 放置一个I型方块
    i_piece = Piece.get_piece("I")
    placed_i = %{
      id: "I",
      shape: i_piece.shape,
      position: {0, 0},
      color: i_piece.color
    }
    
    # 原始的valid_positions
    original_valid = Board.valid_positions(u_piece.shape, [placed_i], {10, 6})
    
    # 增强版：找出所有可以触发放置的点击位置
    all_clickable_positions = find_all_clickable_positions(u_piece.shape, [placed_i], {10, 6})
    
    IO.puts("原始有效位置数量: #{length(original_valid)}")
    IO.puts("增强版可点击位置数量: #{length(all_clickable_positions)}")
    
    # 找出新增的可点击位置
    new_positions = MapSet.difference(
      MapSet.new(all_clickable_positions),
      MapSet.new(original_valid)
    )
    
    IO.puts("\n新增的可点击位置（原本无法点击的）:")
    new_positions
    |> Enum.sort()
    |> Enum.take(20)
    |> Enum.each(fn pos ->
      IO.puts("  #{inspect(pos)} - 点击此处可以放置方块")
    end)
  end
  
  # 增强版：找出所有可以触发放置的点击位置
  defp find_all_clickable_positions(piece_shape, placed_pieces, board_size) do
    # 获取所有可能的放置位置（方块左上角）
    valid_placements = Board.valid_positions(piece_shape, placed_pieces, board_size)
    
    # 对于每个有效的放置位置，计算方块的所有格子位置
    # 这些格子位置都可以作为触发放置的点击位置
    valid_placements
    |> Enum.flat_map(fn placement_pos ->
      # 获取方块在该位置时占用的所有格子
      absolute_positions = Piece.get_absolute_positions(piece_shape, placement_pos)
      
      # 每个格子位置都可以触发放置到placement_pos
      Enum.map(absolute_positions, fn click_pos ->
        click_pos
      end)
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end
end

# 运行调试
ClickDetectionDebugger.debug_placement_logic()
ClickDetectionDebugger.test_enhanced_valid_positions()