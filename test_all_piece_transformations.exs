#!/usr/bin/env elixir

# 启动应用依赖
Mix.start()
Code.require_file("lib/pento/game/piece.ex")

alias Pento.Game.Piece

defmodule PieceTransformationTester do
  def test_all_pieces() do
    pieces = Piece.all_pieces()
    
    IO.puts("测试所有Pentomino方块的变换...")
    IO.puts(String.duplicate("=", 60))
    
    all_errors = Enum.reduce(pieces, [], fn piece, acc_errors ->
      IO.puts("\n测试方块 #{piece.id} (#{piece.color}):")
      IO.puts(String.duplicate("-", 40))
      
      # 原始形状
      IO.puts("原始形状:")
      visualize_shape(piece.shape)
      
      # 测试所有8种变换（4个旋转 + 4个旋转后翻转）
      transformations = [
        {"原始", piece},
        {"旋转90度", Piece.rotate_piece(piece, :clockwise)},
        {"旋转180度", piece |> Piece.rotate_piece(:clockwise) |> Piece.rotate_piece(:clockwise)},
        {"旋转270度", piece |> Piece.rotate_piece(:clockwise) |> Piece.rotate_piece(:clockwise) |> Piece.rotate_piece(:clockwise)},
        {"水平翻转", Piece.flip_piece(piece, :horizontal)},
        {"垂直翻转", Piece.flip_piece(piece, :vertical)},
        {"水平翻转+旋转90度", piece |> Piece.flip_piece(:horizontal) |> Piece.rotate_piece(:clockwise)},
        {"垂直翻转+旋转90度", piece |> Piece.flip_piece(:vertical) |> Piece.rotate_piece(:clockwise)}
      ]
      
      piece_errors = Enum.reduce(transformations, acc_errors, fn {name, transformed}, errors ->
        new_errors = []
        
        # 检查格子数量
        cell_count = length(transformed.shape)
        new_errors = if cell_count != 5 do
          error = "#{piece.id} - #{name}: 格子数量错误 (#{cell_count} != 5)"
          IO.puts("❌ #{error}")
          [error | new_errors]
        else
          new_errors
        end
        
        # 检查连通性
        new_errors = if not Piece.is_connected?(transformed.shape) do
          error = "#{piece.id} - #{name}: 方块不连通!"
          IO.puts("❌ #{error}")
          IO.puts("   形状: #{inspect(transformed.shape)}")
          visualize_shape(transformed.shape)
          [error | new_errors]
        else
          new_errors
        end
        
        # 检查是否有重复的格子
        new_errors = if length(transformed.shape) != length(Enum.uniq(transformed.shape)) do
          error = "#{piece.id} - #{name}: 有重复的格子!"
          IO.puts("❌ #{error}")
          [error | new_errors]
        else
          new_errors
        end
        
        errors ++ new_errors
      end)
      
      piece_errors
    end)
    
    IO.puts("\n" <> String.duplicate("=", 60))
    IO.puts("测试总结:")
    if Enum.empty?(all_errors) do
      IO.puts("✅ 所有测试通过！")
    else
      IO.puts("❌ 发现 #{length(all_errors)} 个错误:")
      for error <- all_errors do
        IO.puts("   - #{error}")
      end
    end
  end
  
  defp visualize_shape(shape) do
    if Enum.empty?(shape) do
      IO.puts("空形状!")
    else
      {min_x, max_x} = shape |> Enum.map(&elem(&1, 0)) |> Enum.min_max()
      {min_y, max_y} = shape |> Enum.map(&elem(&1, 1)) |> Enum.min_max()
      
      shape_set = MapSet.new(shape)
      
      for y <- min_y..max_y do
        IO.write("   ")
        for x <- min_x..max_x do
          if MapSet.member?(shape_set, {x, y}) do
            IO.write("■ ")
          else
            IO.write(". ")
          end
        end
        IO.puts("")
      end
    end
  end
end

PieceTransformationTester.test_all_pieces()