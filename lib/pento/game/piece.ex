defmodule Pento.Game.Piece do
  @moduledoc """
  Defines pentomino pieces and operations on them.
  Each pentomino is made of 5 connected squares.
  """

  defstruct [:id, :shape, :color]

  @type t :: %__MODULE__{
    id: String.t(),
    shape: list({integer(), integer()}),
    color: String.t()
  }

  @pieces %{
    "F" => %{shape: [{0, 1}, {0, 2}, {1, 0}, {1, 1}, {2, 1}], color: "#FF6B6B"},
    "I" => %{shape: [{0, 0}, {0, 1}, {0, 2}, {0, 3}, {0, 4}], color: "#4ECDC4"},
    "L" => %{shape: [{0, 0}, {0, 1}, {0, 2}, {0, 3}, {1, 3}], color: "#45B7D1"},
    "N" => %{shape: [{0, 1}, {0, 2}, {1, 0}, {1, 1}, {1, 2}], color: "#96CEB4"},
    "P" => %{shape: [{0, 0}, {0, 1}, {1, 0}, {1, 1}, {1, 2}], color: "#FFEAA7"},
    "T" => %{shape: [{0, 0}, {1, 0}, {2, 0}, {1, 1}, {1, 2}], color: "#DDA0DD"},
    "U" => %{shape: [{0, 0}, {0, 1}, {1, 1}, {2, 0}, {2, 1}], color: "#F8B500"},
    "V" => %{shape: [{0, 0}, {0, 1}, {0, 2}, {1, 2}, {2, 2}], color: "#6C5CE7"},
    "W" => %{shape: [{0, 0}, {0, 1}, {1, 1}, {1, 2}, {2, 2}], color: "#A8E6CF"},
    "X" => %{shape: [{1, 0}, {0, 1}, {1, 1}, {2, 1}, {1, 2}], color: "#FF8B94"},
    "Y" => %{shape: [{0, 1}, {1, 0}, {1, 1}, {1, 2}, {2, 0}], color: "#C7CEEA"},
    "Z" => %{shape: [{0, 0}, {1, 0}, {1, 1}, {1, 2}, {2, 2}], color: "#FFDAC1"}
  }

  @doc """
  Returns all pentomino pieces
  """
  def all_pieces do
    @pieces
    |> Enum.map(fn {id, data} ->
      %__MODULE__{
        id: id,
        shape: data.shape,
        color: data.color
      }
    end)
    |> Enum.sort_by(& &1.id)
  end

  @doc """
  Gets a specific piece by ID
  """
  def get_piece(id) when is_binary(id) do
    case Map.get(@pieces, id) do
      nil -> nil
      data ->
        %__MODULE__{
          id: id,
          shape: data.shape,
          color: data.color
        }
    end
  end
  def get_piece(_), do: nil

  @doc """
  Rotates a piece 90 degrees clockwise or counter-clockwise
  """
  def rotate_piece(%__MODULE__{shape: shape} = piece, :clockwise) do
    # 直接旋转每个格子，然后归一化
    rotated_shape = shape
    |> Enum.map(fn {x, y} ->
      # 90度顺时针旋转: (x,y) -> (y,-x)
      {y, -x}
    end)
    |> normalize_shape()
    
    %{piece | shape: rotated_shape}
  end

  def rotate_piece(piece, :counter_clockwise) do
    # Counter-clockwise is 3 clockwise rotations
    piece
    |> rotate_piece(:clockwise)
    |> rotate_piece(:clockwise)
    |> rotate_piece(:clockwise)
  end

  @doc """
  Flips a piece horizontally or vertically
  """
  def flip_piece(%__MODULE__{shape: shape} = piece, :horizontal) do
    max_x = shape |> Enum.map(&elem(&1, 0)) |> Enum.max()
    
    flipped_shape = shape
    |> Enum.map(fn {x, y} -> {max_x - x, y} end)
    |> normalize_shape()
    
    %{piece | shape: flipped_shape}
  end

  def flip_piece(%__MODULE__{shape: shape} = piece, :vertical) do
    max_y = shape |> Enum.map(&elem(&1, 1)) |> Enum.max()
    
    flipped_shape = shape
    |> Enum.map(fn {x, y} -> {x, max_y - y} end)
    |> normalize_shape()
    
    %{piece | shape: flipped_shape}
  end

  @doc """
  Normalizes a shape to have minimum x and y at 0
  """
  def normalize_shape(shape) do
    {min_x, _} = Enum.min_by(shape, &elem(&1, 0))
    {_, min_y} = Enum.min_by(shape, &elem(&1, 1))
    
    shape
    |> Enum.map(fn {x, y} -> 
      # Ensure integer coordinates after normalization
      {round(x - min_x), round(y - min_y)}
    end)
    |> Enum.sort()
  end

  @doc """
  Gets absolute positions for a piece at a given position
  """
  def get_absolute_positions(shape, {px, py}) do
    Enum.map(shape, fn {x, y} -> {x + px, y + py} end)
  end

  @doc """
  Checks if a shape is connected (all cells are reachable from any cell)
  """
  def is_connected?(shape) when length(shape) <= 1, do: true
  
  def is_connected?(shape) do
    # Use BFS to check connectivity
    [start | _] = shape
    shape_set = MapSet.new(shape)
    
    connected = bfs_connected([start], MapSet.new([start]), shape_set)
    
    MapSet.size(connected) == length(shape)
  end

  # Private functions


  defp bfs_connected([], visited, _shape_set), do: visited
  
  defp bfs_connected([current | queue], visited, shape_set) do
    neighbors = get_neighbors(current)
    |> Enum.filter(&MapSet.member?(shape_set, &1))
    |> Enum.reject(&MapSet.member?(visited, &1))
    
    new_visited = Enum.reduce(neighbors, visited, &MapSet.put(&2, &1))
    new_queue = queue ++ neighbors
    
    bfs_connected(new_queue, new_visited, shape_set)
  end

  defp get_neighbors({x, y}) do
    [{x - 1, y}, {x + 1, y}, {x, y - 1}, {x, y + 1}]
  end
end