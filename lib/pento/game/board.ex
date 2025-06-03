defmodule Pento.Game.Board do
  @moduledoc """
  Board validation and calculation functions for the Pentomino game.
  """

  alias Pento.Game.Piece

  @doc """
  Checks if all positions are within board bounds
  """
  def within_bounds?(positions, {cols, rows}) do
    Enum.all?(positions, fn {x, y} ->
      x >= 0 and x < cols and y >= 0 and y < rows
    end)
  end

  @doc """
  Checks if positions collide with any placed pieces
  """
  def has_collision?(new_positions, placed_pieces) do
    occupied = get_occupied_cells(placed_pieces)
    
    Enum.any?(new_positions, fn pos ->
      MapSet.member?(occupied, pos)
    end)
  end

  @doc """
  Gets all cells occupied by placed pieces
  """
  def get_occupied_cells(placed_pieces) do
    placed_pieces
    |> Enum.flat_map(fn placed ->
      Piece.get_absolute_positions(placed.shape, placed.position)
    end)
    |> MapSet.new()
  end

  @doc """
  Finds all valid positions for a piece shape on the board
  """
  def valid_positions(piece_shape, placed_pieces, {cols, rows} = board_size) do
    occupied = get_occupied_cells(placed_pieces)
    
    # Try all possible positions
    for x <- 0..(cols - 1),
        y <- 0..(rows - 1) do
      {x, y}
    end
    |> Enum.filter(fn position ->
      absolute_positions = Piece.get_absolute_positions(piece_shape, position)
      
      within_bounds?(absolute_positions, board_size) and
        not has_collision_with_set?(absolute_positions, occupied)
    end)
  end

  @doc """
  Calculates the percentage of board covered by placed pieces
  """
  def calculate_coverage(placed_pieces, {cols, rows}) do
    total_cells = cols * rows
    
    if total_cells == 0 do
      0.0
    else
      occupied_count = placed_pieces
      |> get_occupied_cells()
      |> MapSet.size()
      
      Float.round(occupied_count / total_cells * 100, 2)
    end
  end

  @doc """
  Checks if the board is completely filled
  """
  def is_complete?(placed_pieces, board_size) do
    calculate_coverage(placed_pieces, board_size) == 100.0
  end

  @doc """
  Finds all valid placements when clicking on a specific position.
  Returns a list of possible placement positions (top-left corners) where the piece
  can be placed such that one of its cells occupies the clicked position.
  """
  def find_valid_placements_for_click(click_pos, piece_shape, placed_pieces, board_size) do
    occupied = get_occupied_cells(placed_pieces)
    
    # For each cell in the piece, calculate where the top-left would be
    # if that cell was at the click position
    piece_shape
    |> Enum.map(fn {dx, dy} ->
      # Calculate the top-left corner position
      {elem(click_pos, 0) - dx, elem(click_pos, 1) - dy}
    end)
    |> Enum.uniq()
    |> Enum.filter(fn placement_pos ->
      # Check if this placement is valid
      absolute_positions = Piece.get_absolute_positions(piece_shape, placement_pos)
      
      within_bounds?(absolute_positions, board_size) and
        not has_collision_with_set?(absolute_positions, occupied)
    end)
  end

  @doc """
  Gets all clickable positions for a piece shape.
  This includes all cells that would be occupied by the piece in any valid placement.
  """
  def get_clickable_positions(piece_shape, placed_pieces, board_size) do
    # Get all valid placement positions
    valid_placements = valid_positions(piece_shape, placed_pieces, board_size)
    
    # For each valid placement, get all cells the piece would occupy
    valid_placements
    |> Enum.flat_map(fn placement_pos ->
      Piece.get_absolute_positions(piece_shape, placement_pos)
    end)
    |> Enum.uniq()
    |> Enum.filter(fn {x, y} ->
      # Only return positions within board bounds
      x >= 0 and x < elem(board_size, 0) and
      y >= 0 and y < elem(board_size, 1)
    end)
  end

  # Private functions

  defp has_collision_with_set?(positions, occupied_set) do
    Enum.any?(positions, &MapSet.member?(occupied_set, &1))
  end
end