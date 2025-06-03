#!/usr/bin/env elixir

# 测试点击检测问题的修复
# 运行: mix run test_click_fix.exs

# 加载项目环境
Code.require_file("lib/pento/game/piece.ex")
Code.require_file("lib/pento/game/board.ex")
Code.require_file("lib/pento/game/state.ex")
Code.require_file("lib/pento/game.ex")

alias Pento.Game
alias Pento.Game.{State, Board, Piece}

defmodule ClickFixTester do
  def test_fix do
    IO.puts("\n=== 测试点击检测修复 ===\n")
    
    # 创建游戏状态
    {:ok, game_state} = State.new({10, 6})
    
    # 放置I型方块在(0,0)
    i_piece = Piece.get_piece("I")
    placed_i = %{
      id: "I",
      shape: i_piece.shape,
      position: {0, 0},
      color: i_piece.color
    }
    
    game_with_i = %{game_state | placed_pieces: [placed_i]}
    
    # 选择U型方块
    {:ok, game_with_u} = Game.select_piece(game_with_i, "U")
    u_piece = game_with_u.current_piece
    
    IO.puts("测试场景：")
    IO.puts("- I型方块占用位置: #{inspect(Piece.get_absolute_positions(i_piece.shape, {0, 0}))}")
    IO.puts("- U型方块形状: #{inspect(u_piece.shape)}")
    
    # 测试原始的valid_positions
    original_valid = Game.valid_positions(game_with_u)
    IO.puts("\n原始valid_positions数量: #{length(original_valid)}")
    IO.puts("位置{0,0}是否有效? #{Enum.member?(original_valid, {0, 0})}")
    
    # 测试新的clickable_positions
    clickable = Game.clickable_positions(game_with_u)
    IO.puts("\n新的clickable_positions数量: #{length(clickable)}")
    IO.puts("位置{0,0}是否可点击? #{Enum.member?(clickable, {0, 0})}")
    
    # 测试点击被占用的位置
    IO.puts("\n--- 测试点击被占用的位置{0,0} ---")
    test_smart_placement(game_with_u, {0, 0})
    
    # 测试点击其他位置
    IO.puts("\n--- 测试点击未占用的位置{2,2} ---")
    test_smart_placement(game_with_u, {2, 2})
    
    # 测试点击可以放置方块的其他格子
    IO.puts("\n--- 测试点击位置{3,0}（U型方块的右侧格子） ---")
    test_smart_placement(game_with_u, {3, 0})
    
    # 显示改进效果
    IO.puts("\n=== 改进效果总结 ===")
    new_clickable = MapSet.difference(
      MapSet.new(clickable),
      MapSet.new(original_valid)
    )
    IO.puts("新增可点击位置数量: #{MapSet.size(new_clickable)}")
    IO.puts("部分新增位置示例: #{inspect(Enum.take(new_clickable, 5))}")
  end
  
  defp test_smart_placement(game_state, click_pos) do
    case Game.smart_place_piece(game_state, click_pos) do
      {:ok, new_state} ->
        placed = List.first(new_state.placed_pieces)
        IO.puts("✓ 成功！方块放置在位置: #{inspect(placed.position)}")
        IO.puts("  方块占用的位置: #{inspect(Piece.get_absolute_positions(placed.shape, placed.position))}")
        
      {:error, reason} ->
        IO.puts("✗ 失败: #{reason}")
        
        # 显示可能的放置位置
        possible = Board.find_valid_placements_for_click(
          click_pos,
          game_state.current_piece.shape,
          game_state.placed_pieces,
          game_state.board_size
        )
        
        if length(possible) > 0 do
          IO.puts("  可能的放置位置: #{inspect(possible)}")
        end
    end
  end
end

# 运行测试
ClickFixTester.test_fix()