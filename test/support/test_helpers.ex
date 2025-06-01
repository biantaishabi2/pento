defmodule Pento.TestHelpers do
  @moduledoc """
  Helper functions for tests
  """
  
  import ExUnit.Assertions

  @doc """
  Creates a game state with specific pieces placed for testing
  """
  def create_game_with_pieces(piece_placements) do
    game = Pento.Game.new_game()
    
    Enum.reduce(piece_placements, game, fn {piece_id, position}, acc ->
      {:ok, acc} = Pento.Game.select_piece(acc, piece_id)
      {:ok, acc} = Pento.Game.place_piece(acc, position)
      acc
    end)
  end

  @doc """
  Creates a nearly complete game (missing one piece)
  """
  def create_almost_complete_game do
    # This is a valid solution missing the last piece
    placements = [
      {"F", {0, 0}},
      {"I", {0, 3}},
      {"L", {3, 0}},
      {"N", {4, 0}},
      {"P", {6, 0}},
      {"T", {7, 0}},
      {"U", {0, 4}},
      {"V", {3, 3}},
      {"W", {5, 3}},
      {"X", {8, 3}},
      {"Y", {6, 4}}
      # Missing Z piece
    ]
    
    create_game_with_pieces(placements)
  end

  @doc """
  Asserts that a piece is at a specific position
  """
  def assert_piece_at_position(game, piece_id, position) do
    piece = Enum.find(game.placed_pieces, & &1.id == piece_id)
    assert piece != nil, "Piece #{piece_id} not found in placed pieces"
    assert piece.position == position, 
           "Piece #{piece_id} is at #{inspect(piece.position)}, expected #{inspect(position)}"
  end

  @doc """
  Gets all positions occupied by placed pieces
  """
  def get_all_occupied_positions(game) do
    game.placed_pieces
    |> Enum.flat_map(fn placed ->
      Pento.Game.Piece.get_absolute_positions(placed.shape, placed.position)
    end)
    |> MapSet.new()
  end

  @doc """
  Checks if a position is occupied
  """
  def position_occupied?(game, position) do
    occupied = get_all_occupied_positions(game)
    MapSet.member?(occupied, position)
  end

  @doc """
  Creates a custom piece for testing
  """
  def create_test_piece(id, shape, color \\ "#000000") do
    %Pento.Game.Piece{
      id: id,
      shape: shape,
      color: color
    }
  end

  @doc """
  Generates a random valid position on the board
  """
  def random_board_position(board_size \\ {10, 6}) do
    {cols, rows} = board_size
    {Enum.random(0..(cols-1)), Enum.random(0..(rows-1))}
  end

  @doc """
  Validates that all pieces in a game are properly connected
  """
  def validate_all_pieces_connected(game) do
    Enum.all?(game.placed_pieces, fn placed ->
      Pento.Game.Piece.is_connected?(placed.shape)
    end)
  end

  @doc """
  Creates test scenarios for different board states
  """
  def board_scenarios do
    %{
      empty: Pento.Game.new_game(),
      one_piece: create_game_with_pieces([{"F", {3, 2}}]),
      two_pieces: create_game_with_pieces([{"F", {0, 0}}, {"I", {3, 0}}]),
      half_filled: create_game_with_pieces([
        {"F", {0, 0}}, {"I", {3, 0}}, {"L", {4, 0}},
        {"N", {6, 0}}, {"P", {0, 3}}, {"T", {3, 3}}
      ]),
      almost_complete: create_almost_complete_game()
    }
  end
end