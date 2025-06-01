defmodule Pento.Factory do
  @moduledoc """
  Test factory for creating test data
  """

  alias Pento.Game.{Piece, State}

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
  Creates a piece struct
  """
  def build_piece(id) when is_binary(id) do
    piece_data = Map.get(@pieces, id)
    
    %Piece{
      id: id,
      shape: piece_data.shape,
      color: piece_data.color
    }
  end

  @doc """
  Creates all pieces
  """
  def all_pieces do
    @pieces
    |> Map.keys()
    |> Enum.map(&build_piece/1)
  end

  @doc """
  Creates a placed piece with position
  """
  def build_placed_piece(id, position) do
    piece = build_piece(id)
    Map.put(piece, :position, position)
  end

  @doc """
  Creates a game state
  """
  def build_game_state(attrs \\ %{}) do
    defaults = %{
      board_size: {10, 6},
      placed_pieces: [],
      available_pieces: all_pieces(),
      current_piece: nil,
      history: []
    }
    
    struct(State, Map.merge(defaults, attrs))
  end

  @doc """
  Creates a partially completed game state
  """
  def build_partial_game_state do
    placed = [
      build_placed_piece("F", {0, 0}),
      build_placed_piece("I", {3, 0}),
      build_placed_piece("L", {4, 0})
    ]
    
    available = all_pieces()
    |> Enum.reject(fn p -> p.id in ["F", "I", "L"] end)
    
    build_game_state(%{
      placed_pieces: placed,
      available_pieces: available
    })
  end

  @doc """
  Creates a winning game state
  """
  def build_winning_game_state do
    # Known solution for 10x6 board
    placed = [
      build_placed_piece("I", {0, 0}),
      build_placed_piece("F", {1, 0}),
      build_placed_piece("P", {4, 0}),
      build_placed_piece("T", {6, 0}),
      build_placed_piece("V", {9, 0}),
      build_placed_piece("W", {1, 2}),
      build_placed_piece("Z", {4, 2}),
      build_placed_piece("X", {7, 2}),
      build_placed_piece("L", {0, 3}),
      build_placed_piece("Y", {3, 3}),
      build_placed_piece("U", {6, 4}),
      build_placed_piece("N", {2, 4})
    ]
    
    build_game_state(%{
      placed_pieces: placed,
      available_pieces: []
    })
  end

  @doc """
  Placement test scenarios
  """
  def valid_placement_scenarios do
    [
      %{
        name: "Empty board placement",
        board_size: {10, 6},
        placed_pieces: [],
        piece: build_piece("I"),
        position: {0, 0},
        expected: :ok
      },
      %{
        name: "Non-overlapping placement",
        board_size: {10, 6},
        placed_pieces: [build_placed_piece("I", {0, 0})],
        piece: build_piece("L"),
        position: {5, 0},
        expected: :ok
      },
      %{
        name: "Adjacent placement",
        board_size: {10, 6},
        placed_pieces: [build_placed_piece("F", {2, 2})],
        piece: build_piece("T"),
        position: {5, 2},
        expected: :ok
      }
    ]
  end

  def invalid_placement_scenarios do
    [
      %{
        name: "Out of bounds - right edge",
        board_size: {10, 6},
        placed_pieces: [],
        piece: build_piece("I"),
        position: {10, 0},
        expected: {:error, :out_of_bounds}
      },
      %{
        name: "Out of bounds - bottom edge",
        board_size: {10, 6},
        placed_pieces: [],
        piece: build_piece("I"),
        position: {0, 6},
        expected: {:error, :out_of_bounds}
      },
      %{
        name: "Overlapping placement",
        board_size: {10, 6},
        placed_pieces: [build_placed_piece("X", {3, 3})],
        piece: build_piece("X"),
        position: {3, 3},
        expected: {:error, :collision}
      },
      %{
        name: "Partial overlap",
        board_size: {10, 6},
        placed_pieces: [build_placed_piece("T", {2, 2})],
        piece: build_piece("F"),
        position: {3, 2},
        expected: {:error, :collision}
      }
    ]
  end

  @doc """
  Creates random board configurations for property testing
  """
  def random_board_state(piece_count \\ 3) do
    pieces = all_pieces() |> Enum.shuffle() |> Enum.take(piece_count)
    
    # Simple placement strategy - place pieces in a row
    placed = pieces
    |> Enum.with_index()
    |> Enum.map(fn {piece, idx} ->
      Map.put(piece, :position, {idx * 3, 0})
    end)
    
    available = all_pieces()
    |> Enum.reject(fn p -> p.id in Enum.map(placed, & &1.id) end)
    
    build_game_state(%{
      placed_pieces: placed,
      available_pieces: available
    })
  end
end