#!/usr/bin/env elixir

# 生成所有pentomino方块所有方向的HTML目录
Mix.start()
Code.require_file("lib/pento/game/piece.ex")

alias Pento.Game.Piece

defmodule PieceCatalogGenerator do
  def generate_html() do
    pieces = Piece.all_pieces()
    
    html_content = """
    <!DOCTYPE html>
    <html>
    <head>
      <title>Pentomino方块目录</title>
      <style>
        body {
          font-family: Arial, sans-serif;
          margin: 20px;
          background-color: #f5f5f5;
        }
        .piece-section {
          margin-bottom: 40px;
          background: white;
          padding: 20px;
          border-radius: 8px;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .piece-title {
          font-size: 24px;
          font-weight: bold;
          margin-bottom: 15px;
          padding: 10px;
          border-radius: 4px;
        }
        .orientations {
          display: flex;
          flex-wrap: wrap;
          gap: 15px;
        }
        .orientation {
          border: 1px solid #ddd;
          padding: 10px;
          border-radius: 4px;
          text-align: center;
          background: #fafafa;
        }
        .orientation-label {
          font-size: 12px;
          color: #666;
          margin-bottom: 5px;
        }
        svg {
          background: white;
          border: 1px solid #eee;
        }
        .stats {
          margin-top: 20px;
          padding: 15px;
          background: #f0f0f0;
          border-radius: 4px;
          font-size: 14px;
        }
      </style>
    </head>
    <body>
      <h1>Pentomino方块完整目录</h1>
      <p>展示所有12个pentomino方块的所有独特方向</p>
    """
    
    {final_html, total_orientations} = Enum.reduce(pieces, {html_content, 0}, fn piece, {html_acc, count_acc} ->
      all_orientations = generate_all_orientations(piece)
      unique_orientations = get_unique_orientations(all_orientations)
      new_count = count_acc + length(unique_orientations)
      
      piece_html = """
      <div class="piece-section">
        <div class="piece-title" style="background-color: #{piece.color}20; color: #{piece.color};">
          方块 #{piece.id} - #{length(unique_orientations)} 个独特方向
        </div>
        <div class="orientations">
      """
      
      orientation_html = Enum.map(unique_orientations, fn {{shape, _piece}, index} ->
        svg = generate_svg(shape, piece.color)
        """
          <div class="orientation">
            <div class="orientation-label">方向 #{index + 1}</div>
            #{svg}
          </div>
        """
      end) |> Enum.join("\n")
      
      piece_html = piece_html <> orientation_html <> """
        </div>
      </div>
      """
      
      {html_acc <> piece_html, new_count}
    end)
    
    final_html = final_html <> """
      <div class="stats">
        <h3>统计信息</h3>
        <p>总方块数: #{length(pieces)}</p>
        <p>总独特方向数: #{total_orientations}</p>
        <p>平均每个方块: #{Float.round(total_orientations / length(pieces), 1)} 个方向</p>
      </div>
    </body>
    </html>
    """
    
    File.write!("pentomino_catalog.html", final_html)
    IO.puts("HTML目录已生成: pentomino_catalog.html")
    IO.puts("总共生成了 #{total_orientations} 个独特的方向")
  end
  
  defp generate_svg(shape, color) do
    {min_x, max_x} = shape |> Enum.map(&elem(&1, 0)) |> Enum.min_max()
    {min_y, max_y} = shape |> Enum.map(&elem(&1, 1)) |> Enum.min_max()
    
    width = (max_x - min_x + 1) * 20 + 10
    height = (max_y - min_y + 1) * 20 + 10
    
    cells = Enum.map(shape, fn {x, y} ->
      """
      <rect 
        x="#{(x - min_x) * 20 + 5}" 
        y="#{(y - min_y) * 20 + 5}" 
        width="20" 
        height="20" 
        fill="#{color}" 
        stroke="#333" 
        stroke-width="1" 
        rx="2"
      />
      """
    end) |> Enum.join("\n")
    
    """
    <svg width="#{width}" height="#{height}" viewBox="0 0 #{width} #{height}">
      #{cells}
    </svg>
    """
  end
  
  defp generate_all_orientations(piece) do
    rotations = [
      piece,
      Piece.rotate_piece(piece, :clockwise),
      piece |> Piece.rotate_piece(:clockwise) |> Piece.rotate_piece(:clockwise),
      piece |> Piece.rotate_piece(:clockwise) |> Piece.rotate_piece(:clockwise) |> Piece.rotate_piece(:clockwise)
    ]
    
    all_transforms = Enum.flat_map(rotations, fn rotated ->
      [
        rotated,
        Piece.flip_piece(rotated, :horizontal),
        Piece.flip_piece(rotated, :vertical),
        rotated |> Piece.flip_piece(:horizontal) |> Piece.flip_piece(:vertical)
      ]
    end)
    
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
  
  defp get_unique_orientations(orientations) do
    orientations
    |> Enum.map(fn piece ->
      normalized = Piece.normalize_shape(piece.shape)
      {normalized, piece}
    end)
    |> Enum.uniq_by(fn {normalized, _} -> normalized end)
    |> Enum.with_index()
  end
end

PieceCatalogGenerator.generate_html()