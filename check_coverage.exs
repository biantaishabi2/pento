alias Pento.Game.{Board, Piece}

# Test 1: Half filled board
board_size = {10, 6}
placed_pieces_half = [
  %{id: "F", shape: [{0,1}, {1,0}, {1,1}, {1,2}, {2,1}], position: {0, 0}},
  %{id: "I", shape: [{0,0}, {0,1}, {0,2}, {0,3}, {0,4}], position: {3, 0}},
  %{id: "L", shape: [{0,0}, {0,1}, {0,2}, {0,3}, {1,3}], position: {4, 0}},
  %{id: "N", shape: [{0,1}, {0,2}, {1,0}, {1,1}, {1,2}], position: {6, 0}},
  %{id: "P", shape: [{0,0}, {0,1}, {1,0}, {1,1}, {1,2}], position: {0, 3}},
  %{id: "T", shape: [{0,0}, {1,0}, {2,0}, {1,1}, {1,2}], position: {3, 3}}
]

# Calculate actual positions for each piece
IO.puts "Half filled board positions:"
all_positions_half = placed_pieces_half
|> Enum.flat_map(fn piece ->
  positions = Piece.get_absolute_positions(piece.shape, piece.position)
  IO.puts "#{piece.id} at #{inspect piece.position}: #{inspect positions}"
  positions
end)

unique_positions_half = Enum.uniq(all_positions_half)
IO.puts "\nTotal positions: #{length(all_positions_half)}"
IO.puts "Unique positions: #{length(unique_positions_half)}"
IO.puts "Coverage: #{Float.round(length(unique_positions_half) / 60 * 100, 2)}%"

if length(all_positions_half) != length(unique_positions_half) do
  IO.puts "\nOverlapping positions found!"
  duplicates = all_positions_half -- unique_positions_half
  IO.inspect duplicates
end

# Test 2: Fully filled board
IO.puts "\n\n=== Fully filled board ==="
placed_pieces_full = [
  %{id: "F", shape: [{0,1}, {1,0}, {1,1}, {1,2}, {2,1}], position: {0, 0}},
  %{id: "I", shape: [{0,0}, {1,0}, {2,0}, {3,0}, {4,0}], position: {0, 3}},
  %{id: "L", shape: [{0,0}, {0,1}, {0,2}, {0,3}, {1,3}], position: {3, 0}},
  %{id: "N", shape: [{0,1}, {0,2}, {1,0}, {1,1}, {1,2}], position: {4, 0}},
  %{id: "P", shape: [{0,0}, {0,1}, {1,0}, {1,1}, {1,2}], position: {6, 0}},
  %{id: "T", shape: [{0,0}, {1,0}, {2,0}, {1,1}, {1,2}], position: {7, 0}},
  %{id: "U", shape: [{0,0}, {0,1}, {1,1}, {2,0}, {2,1}], position: {0, 4}},
  %{id: "V", shape: [{0,0}, {0,1}, {0,2}, {1,2}, {2,2}], position: {3, 3}},
  %{id: "W", shape: [{0,0}, {0,1}, {1,1}, {1,2}, {2,2}], position: {5, 3}},
  %{id: "X", shape: [{1,0}, {0,1}, {1,1}, {2,1}, {1,2}], position: {8, 3}},
  %{id: "Y", shape: [{0,1}, {1,0}, {1,1}, {1,2}, {2,0}], position: {6, 4}},
  %{id: "Z", shape: [{0,0}, {1,0}, {1,1}, {1,2}, {2,2}], position: {8, 0}}
]

all_positions_full = placed_pieces_full
|> Enum.flat_map(fn piece ->
  positions = Piece.get_absolute_positions(piece.shape, piece.position)
  positions
end)

unique_positions_full = Enum.uniq(all_positions_full)
IO.puts "Total positions: #{length(all_positions_full)}"
IO.puts "Unique positions: #{length(unique_positions_full)}"
IO.puts "Coverage: #{Float.round(length(unique_positions_full) / 60 * 100, 2)}%"

if length(all_positions_full) != length(unique_positions_full) do
  IO.puts "\nOverlapping positions found!"
end

# Visual representation of the board
IO.puts "\nVisual board (full placement):"
occupied = MapSet.new(all_positions_full)
for y <- 0..5 do
  row = for x <- 0..9 do
    if MapSet.member?(occupied, {x, y}), do: "X", else: "."
  end |> Enum.join(" ")
  IO.puts row
end