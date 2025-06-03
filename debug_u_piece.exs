#!/usr/bin/env elixir

# 启动应用依赖
Mix.start()
Code.require_file("lib/pento/game/piece.ex")

alias Pento.Game.Piece

defmodule UPieceDebugger do
  def debug() do
    # 获取U形方块
    u_piece = Piece.get_piece("U")
    IO.puts("原始U形方块定义:")
    IO.inspect(u_piece, label: "Original U")
    
    # 可视化原始形状
    IO.puts("\n原始形状:")
    visualize_shape(u_piece.shape)
    
    # 测试所有旋转
    IO.puts("\n旋转90度 (顺时针):")
    rotated_90 = Piece.rotate_piece(u_piece, :clockwise)
    IO.inspect(rotated_90.shape, label: "Rotated 90°")
    visualize_shape(rotated_90.shape)
    
    IO.puts("\n旋转180度:")
    rotated_180 = u_piece |> Piece.rotate_piece(:clockwise) |> Piece.rotate_piece(:clockwise)
    IO.inspect(rotated_180.shape, label: "Rotated 180°")
    visualize_shape(rotated_180.shape)
    
    IO.puts("\n旋转270度:")
    rotated_270 = u_piece |> Piece.rotate_piece(:clockwise) |> Piece.rotate_piece(:clockwise) |> Piece.rotate_piece(:clockwise)
    IO.inspect(rotated_270.shape, label: "Rotated 270°")
    visualize_shape(rotated_270.shape)
    
    # 测试翻转
    IO.puts("\n水平翻转:")
    flipped_h = Piece.flip_piece(u_piece, :horizontal)
    IO.inspect(flipped_h.shape, label: "Flipped Horizontal")
    visualize_shape(flipped_h.shape)
    
    IO.puts("\n垂直翻转:")
    flipped_v = Piece.flip_piece(u_piece, :vertical)
    IO.inspect(flipped_v.shape, label: "Flipped Vertical")
    visualize_shape(flipped_v.shape)
    
    # 检查连通性
    IO.puts("\n连通性检查:")
    IO.puts("原始形状连通: #{Piece.is_connected?(u_piece.shape)}")
    IO.puts("90度旋转连通: #{Piece.is_connected?(rotated_90.shape)}")
    IO.puts("180度旋转连通: #{Piece.is_connected?(rotated_180.shape)}")
    IO.puts("270度旋转连通: #{Piece.is_connected?(rotated_270.shape)}")
    
    # 检查格子数量
    IO.puts("\n格子数量检查:")
    IO.puts("原始形状格子数: #{length(u_piece.shape)}")
    IO.puts("90度旋转格子数: #{length(rotated_90.shape)}")
    IO.puts("180度旋转格子数: #{length(rotated_180.shape)}")
    IO.puts("270度旋转格子数: #{length(rotated_270.shape)}")
  end
  
  defp visualize_shape(shape) do
    if Enum.empty?(shape) do
      IO.puts("空形状!")
    else
      {min_x, max_x} = shape |> Enum.map(&elem(&1, 0)) |> Enum.min_max()
      {min_y, max_y} = shape |> Enum.map(&elem(&1, 1)) |> Enum.min_max()
      
      shape_set = MapSet.new(shape)
      
      for y <- min_y..max_y do
        for x <- min_x..max_x do
          if MapSet.member?(shape_set, {x, y}) do
            IO.write(" ■ ")
          else
            IO.write(" . ")
          end
        end
        IO.puts("")
      end
      IO.puts("")
    end
  end
end

UPieceDebugger.debug()