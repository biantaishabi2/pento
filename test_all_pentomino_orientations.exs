#!/usr/bin/env elixir

# 测试所有pentomino方块的所有可能方向
Mix.start()
Code.require_file("lib/pento/game/piece.ex")

alias Pento.Game.Piece

defmodule PentominoOrientationTester do
  def test_all_orientations() do
    pieces = Piece.all_pieces()
    
    IO.puts("测试所有Pentomino方块的所有可能方向...")
    IO.puts(String.duplicate("=", 80))
    
    total_errors = 0
    total_orientations = 0
    
    results = Enum.map(pieces, fn piece ->
      IO.puts("\n测试方块 #{piece.id} (#{piece.color}):")
      IO.puts(String.duplicate("-", 60))
      
      # 生成所有可能的变换组合
      all_orientations = generate_all_orientations(piece)
      
      # 去重，保留唯一的形态
      unique_orientations = get_unique_orientations(all_orientations)
      
      IO.puts("总共生成了 #{length(all_orientations)} 个变换")
      IO.puts("去重后有 #{length(unique_orientations)} 个独特的方向")
      
      # 测试每个独特的方向
      errors = Enum.reduce(unique_orientations, [], fn {orientation, index}, acc ->
        IO.write("\n方向 #{index + 1}:")
        
        # 检查格子数量
        cell_count = length(orientation.shape)
        errors = if cell_count != 5 do
          IO.write(" ❌ 格子数量错误(#{cell_count})")
          [{piece.id, index + 1, "格子数量错误: #{cell_count}个格子"} | acc]
        else
          acc
        end
        
        # 检查连通性
        errors = if not Piece.is_connected?(orientation.shape) do
          IO.write(" ❌ 不连通")
          [{piece.id, index + 1, "方块不连通"} | acc]
        else
          errors
        end
        
        # 检查重复格子
        errors = if length(orientation.shape) != length(Enum.uniq(orientation.shape)) do
          IO.write(" ❌ 有重复格子")
          [{piece.id, index + 1, "有重复格子"} | acc]
        else
          errors
        end
        
        if Enum.empty?(errors) do
          IO.write(" ✅")
        end
        
        # 可视化形状
        IO.puts("")
        visualize_shape(orientation.shape)
        
        errors
      end)
      
      {piece.id, length(unique_orientations), errors}
    end)
    
    # 汇总结果
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("测试总结:")
    IO.puts(String.duplicate("-", 40))
    
    for {piece_id, orientation_count, errors} <- results do
      status = if Enum.empty?(errors), do: "✅", else: "❌"
      IO.puts("#{status} #{piece_id}: #{orientation_count} 个独特方向")
      if not Enum.empty?(errors) do
        for {_pid, idx, msg} <- errors do
          IO.puts("   - 方向 #{idx}: #{msg}")
        end
      end
    end
    
    all_errors = results |> Enum.flat_map(fn {_, _, errors} -> errors end)
    total_unique = results |> Enum.map(fn {_, count, _} -> count end) |> Enum.sum()
    
    IO.puts("\n" <> String.duplicate("=", 80))
    if Enum.empty?(all_errors) do
      IO.puts("✅ 所有测试通过！")
      IO.puts("   总共测试了 #{length(pieces)} 个方块")
      IO.puts("   发现了 #{total_unique} 个独特的方向")
    else
      IO.puts("❌ 发现 #{length(all_errors)} 个错误")
    end
  end
  
  # 生成所有可能的变换组合
  defp generate_all_orientations(piece) do
    # 基础变换
    rotations = [
      piece,
      Piece.rotate_piece(piece, :clockwise),
      piece |> Piece.rotate_piece(:clockwise) |> Piece.rotate_piece(:clockwise),
      piece |> Piece.rotate_piece(:clockwise) |> Piece.rotate_piece(:clockwise) |> Piece.rotate_piece(:clockwise)
    ]
    
    # 对每个旋转，应用翻转
    all_transforms = Enum.flat_map(rotations, fn rotated ->
      [
        rotated,
        Piece.flip_piece(rotated, :horizontal),
        Piece.flip_piece(rotated, :vertical),
        rotated |> Piece.flip_piece(:horizontal) |> Piece.flip_piece(:vertical)
      ]
    end)
    
    # 还要考虑先翻转再旋转的情况
    flipped_first = [
      Piece.flip_piece(piece, :horizontal),
      Piece.flip_piece(piece, :vertical),
      piece |> Piece.flip_piece(:horizontal) |> Piece.flip_piece(:vertical)
    ]
    
    flipped_rotations = Enum.flat_map(flipped_first, fn flipped ->
      [
        flipped,
        Piece.rotate_piece(flipped, :clockwise),
        flipped |> Piece.rotate_piece(:clockwise) |> Piece.rotate_piece(:clockwise),
        flipped |> Piece.rotate_piece(:clockwise) |> Piece.rotate_piece(:clockwise) |> Piece.rotate_piece(:clockwise)
      ]
    end)
    
    all_transforms ++ flipped_rotations
  end
  
  # 获取唯一的方向
  defp get_unique_orientations(orientations) do
    orientations
    |> Enum.map(fn piece ->
      # 归一化形状用于比较
      normalized = Piece.normalize_shape(piece.shape)
      {normalized, piece}
    end)
    |> Enum.uniq_by(fn {normalized, _} -> normalized end)
    |> Enum.map(fn {_, piece} -> piece end)
    |> Enum.with_index()
  end
  
  defp visualize_shape(shape) do
    if Enum.empty?(shape) do
      IO.puts("   空形状!")
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

PentominoOrientationTester.test_all_orientations()