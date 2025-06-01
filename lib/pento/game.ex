defmodule Pento.Game do
  @moduledoc """
  The main game context for Pentomino.
  Provides the public API for game operations.
  """

  alias Pento.Game.{State, Board}

  def new_game() do
    case State.new() do
      {:ok, state} -> state
      {:error, _} -> raise "Failed to create new game"
    end
  end
  
  @doc """
  Creates a new game with specified board size
  """
  def new_game({cols, rows} = board_size) when is_integer(cols) and is_integer(rows) do
    validate_board_size!(cols, rows)
    case State.new(board_size) do
      {:ok, state} -> state
      {:error, _} -> raise ArgumentError, "Invalid board size"
    end
  end

  @doc """
  Creates a new game with custom board size
  Validates board size constraints
  """
  def new_game(cols, rows) when is_integer(cols) and is_integer(rows) do
    validate_board_size!(cols, rows)
    case State.new({cols, rows}) do
      {:ok, state} -> state
      {:error, _} -> raise ArgumentError, "Invalid board size"
    end
  end
  
  defp validate_board_size!(cols, rows) do
    cond do
      cols < 5 or rows < 5 ->
        raise ArgumentError, "Board must be at least 5x5"
      
      cols > 20 or rows > 20 ->
        raise ArgumentError, "Board cannot exceed 20x20"
      
      cols * rows < 60 ->
        raise ArgumentError, "Board must have at least 60 cells for all 12 pentominoes"
      
      true ->
        :ok
    end
  end

  @doc """
  Selects a piece for placement
  """
  defdelegate select_piece(game, piece_id), to: State

  @doc """
  Places the current piece at the given position
  """
  defdelegate place_piece(game, position), to: State

  @doc """
  Rotates the current piece
  """
  defdelegate rotate_piece(game, direction), to: State, as: :rotate_current_piece

  @doc """
  Flips the current piece
  """
  defdelegate flip_piece(game, direction), to: State, as: :flip_current_piece

  @doc """
  Removes a placed piece from the board
  """
  defdelegate remove_piece(game, piece_id), to: State

  @doc """
  Undoes the last action
  """
  defdelegate undo(game), to: State

  @doc """
  Resets the game to initial state
  """
  def reset_game(game) do
    case State.new(game.board_size) do
      {:ok, state} -> state
      {:error, _} -> raise ArgumentError, "Invalid board size"
    end
  end

  @doc """
  Gets the game progress as a percentage
  """
  defdelegate get_progress(game), to: State

  @doc """
  Checks if the game is complete
  """
  defdelegate is_complete?(game), to: State

  @doc """
  Gets all valid positions for the current piece
  """
  def valid_positions(%{current_piece: nil}), do: []
  
  def valid_positions(game) do
    Board.valid_positions(
      game.current_piece.shape,
      game.placed_pieces,
      game.board_size
    )
  end

  @doc """
  Saves the game state for persistence
  """
  defdelegate save_game(game), to: State, as: :to_map

  @doc """
  Loads a game from saved state
  """
  def load_game(save_data) when is_map(save_data) do
    case State.from_map(save_data) do
      {:ok, _state} = result -> result
      {:error, _} -> {:error, :invalid_save_data}
    end
  end
  
  def load_game(_), do: {:error, :invalid_save_data}
end