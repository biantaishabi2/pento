alias Pento.Game.Piece

pieces = Piece.all_pieces()
shapes = Enum.map(pieces, fn p -> 
  Piece.normalize_shape(p.shape)
end)

IO.puts "Total pieces: #{length(pieces)}"
IO.puts "Unique shapes: #{length(Enum.uniq(shapes))}"

# Find duplicates
Enum.with_index(pieces)
|> Enum.map(fn {p, i} -> 
  {p.id, Piece.normalize_shape(p.shape), i} 
end)
|> Enum.group_by(fn {_id, shape, _i} -> shape end)
|> Enum.filter(fn {_shape, items} -> length(items) > 1 end)
|> Enum.each(fn {shape, items} ->
  ids = Enum.map(items, fn {id, _, _} -> id end) |> Enum.join(", ")
  IO.puts "\nDuplicate shape found for: #{ids}"
  IO.inspect shape
end)

# Also check individual pieces
IO.puts "\nAll pieces and their shapes:"
Enum.each(pieces, fn p ->
  IO.puts "\n#{p.id}:"
  IO.inspect Piece.normalize_shape(p.shape)
end)