defmodule Pento.Game.State do
  @moduledoc """
  Game state management for Pentomino.
  """

  alias Pento.Game.{Piece, Board}

  defstruct [
    :board_size,
    :available_pieces,
    :placed_pieces,
    :current_piece,
    :history
  ]

  @type t :: %__MODULE__{
    board_size: {integer(), integer()},
    available_pieces: list(Piece.t()),
    placed_pieces: list(placed_piece()),
    current_piece: Piece.t() | nil,
    history: list(t())
  }

  @type placed_piece :: %{
    id: String.t(),
    shape: list({integer(), integer()}),
    position: {integer(), integer()},
    color: String.t()
  }

  @history_limit 10

  @doc """
  Creates a new game state with board size validation
  """
  def new(board_size \\ {10, 6}) do
    case validate_board_size(board_size) do
      :ok -> 
        {:ok, %__MODULE__{
          board_size: board_size,
          available_pieces: Piece.all_pieces(),
          placed_pieces: [],
          current_piece: nil,
          history: []
        }}
      {:error, reason} -> {:error, reason}
    end
  end
  
  @doc """
  Creates a new game state without validation (for internal use)
  """
  def new!(board_size \\ {10, 6}) do
    %__MODULE__{
      board_size: board_size,
      available_pieces: Piece.all_pieces(),
      placed_pieces: [],
      current_piece: nil,
      history: []
    }
  end
  
  defp validate_board_size({width, height}) when width > 0 and height > 0 do
    total_cells = width * height
    min_cells = 60  # 12 pentominoes * 5 cells each
    max_cells = 400 # reasonable upper limit
    
    cond do
      total_cells < min_cells -> {:error, :board_too_small}
      total_cells > max_cells -> {:error, :board_too_large}
      width < 4 or height < 4 -> {:error, :board_too_narrow}
      :else -> :ok
    end
  end
  defp validate_board_size(_), do: {:error, :invalid_board_size}
  
  # Validation for saved board sizes (less strict)
  defp validate_saved_board_size({width, height}) when is_integer(width) and is_integer(height) and width > 0 and height > 0 do
    {:ok, {width, height}}
  end
  defp validate_saved_board_size(_), do: {:error, :invalid_board_size}

  @doc """
  Selects a piece for placement
  """
  def select_piece(%__MODULE__{} = state, piece_id) do
    case find_available_piece(state.available_pieces, piece_id) do
      nil ->
        if piece_placed?(state.placed_pieces, piece_id) do
          {:error, :piece_not_available}
        else
          {:error, :piece_not_found}
        end
      
      piece ->
        {:ok, %{state | current_piece: piece}}
    end
  end

  @doc """
  Places the current piece at the given position
  """
  def place_piece(%__MODULE__{current_piece: nil}, _position) do
    {:error, :no_piece_selected}
  end

  def place_piece(%__MODULE__{} = state, position) do
    with {:ok, _} <- validate_placement(state, position) do
      placed_piece = %{
        id: state.current_piece.id,
        shape: state.current_piece.shape,
        position: position,
        color: state.current_piece.color
      }
      
      new_state = %{state |
        placed_pieces: [placed_piece | state.placed_pieces],
        available_pieces: remove_piece_by_id(state.available_pieces, state.current_piece.id),
        current_piece: nil,
        history: add_to_history(state.history, state)
      }
      
      {:ok, new_state}
    end
  end

  @doc """
  Rotates the current piece
  """
  def rotate_current_piece(%__MODULE__{current_piece: nil}, _direction) do
    {:error, :no_piece_selected}
  end

  def rotate_current_piece(%__MODULE__{} = state, direction) do
    rotated_piece = Piece.rotate_piece(state.current_piece, direction)
    {:ok, %{state | current_piece: rotated_piece}}
  end

  @doc """
  Flips the current piece
  """
  def flip_current_piece(%__MODULE__{current_piece: nil}, _direction) do
    {:error, :no_piece_selected}
  end

  def flip_current_piece(%__MODULE__{} = state, direction) do
    flipped_piece = Piece.flip_piece(state.current_piece, direction)
    {:ok, %{state | current_piece: flipped_piece}}
  end

  @doc """
  Removes a placed piece from the board
  """
  def remove_piece(%__MODULE__{} = state, piece_id) do
    case find_placed_piece(state.placed_pieces, piece_id) do
      nil ->
        {:error, :piece_not_placed}
      
      _placed_piece ->
        # Find the original piece definition
        original_piece = Piece.get_piece(piece_id)
        
        new_state = %{state |
          placed_pieces: Enum.reject(state.placed_pieces, & &1.id == piece_id),
          available_pieces: [original_piece | state.available_pieces],
          history: add_to_history(state.history, state)
        }
        
        {:ok, new_state}
    end
  end

  @doc """
  Undoes the last action
  """
  def undo(%__MODULE__{history: []}) do
    {:error, :no_history}
  end

  def undo(%__MODULE__{history: [previous | rest]}) do
    {:ok, %{previous | history: rest}}
  end

  @doc """
  Gets the game progress as a percentage
  """
  def get_progress(%__MODULE__{} = state) do
    Board.calculate_coverage(state.placed_pieces, state.board_size)
  end
  
  # Fallback for maps (used in tests)
  def get_progress(%{placed_pieces: placed_pieces, board_size: board_size}) do
    Board.calculate_coverage(placed_pieces, board_size)
  end

  @doc """
  Checks if the game is complete
  """
  def is_complete?(%__MODULE__{} = state) do
    Board.is_complete?(state.placed_pieces, state.board_size)
  end
  
  # Fallback for maps (used in tests)
  def is_complete?(%{placed_pieces: placed_pieces, board_size: board_size}) do
    Board.is_complete?(placed_pieces, board_size)
  end

  @doc """
  Converts state to a map for serialization
  """
  def to_map(%__MODULE__{} = state) do
    %{
      board_size: state.board_size,
      placed_pieces: state.placed_pieces,
      available_pieces: Enum.map(state.available_pieces, &piece_to_map/1),
      current_piece: if(state.current_piece, do: piece_to_map(state.current_piece), else: nil)
    }
  end

  @doc """
  Creates state from a map
  """
  def from_map(map) when is_map(map) do
    with {:ok, board_size} <- validate_saved_board_size(map[:board_size]),
         {:ok, placed_pieces} <- validate_placed_pieces(map[:placed_pieces]),
         {:ok, available_pieces} <- validate_available_pieces(map[:available_pieces]),
         {:ok, current_piece} <- validate_current_piece(map[:current_piece]) do
      
      state = %__MODULE__{
        board_size: board_size,
        placed_pieces: placed_pieces || [],
        available_pieces: available_pieces || [],
        current_piece: current_piece,
        history: []
      }
      
      {:ok, state}
    else
      _ -> {:error, :invalid_data}
    end
  end

  def from_map(_), do: {:error, :invalid_data}

  # Private functions

  defp find_available_piece(pieces, piece_id) do
    Enum.find(pieces, & &1.id == piece_id)
  end

  defp find_placed_piece(placed_pieces, piece_id) do
    Enum.find(placed_pieces, & &1.id == piece_id)
  end

  defp piece_placed?(placed_pieces, piece_id) do
    Enum.any?(placed_pieces, & &1.id == piece_id)
  end

  defp remove_piece_by_id(pieces, piece_id) do
    Enum.reject(pieces, & &1.id == piece_id)
  end

  defp validate_placement(%__MODULE__{} = state, position) do
    absolute_positions = Piece.get_absolute_positions(state.current_piece.shape, position)
    
    cond do
      not Board.within_bounds?(absolute_positions, state.board_size) ->
        {:error, :out_of_bounds}
      
      Board.has_collision?(absolute_positions, state.placed_pieces) ->
        {:error, :collision}
      
      true ->
        {:ok, :valid}
    end
  end

  defp add_to_history(history, state) do
    # Remove current_piece from state before adding to history
    state_for_history = %{state | current_piece: nil, history: []}
    [state_for_history | Enum.take(history, @history_limit - 1)]
  end

  defp piece_to_map(%Piece{} = piece) do
    %{
      id: piece.id,
      shape: piece.shape,
      color: piece.color
    }
  end


  defp validate_placed_pieces(nil), do: {:ok, []}
  defp validate_placed_pieces(pieces) when is_list(pieces) do
    if Enum.all?(pieces, &valid_placed_piece?/1) do
      {:ok, pieces}
    else
      {:error, :invalid_placed_pieces}
    end
  end
  defp validate_placed_pieces(_), do: {:error, :invalid_placed_pieces}

  defp valid_placed_piece?(%{id: id, shape: shape, position: {x, y}, color: color})
       when is_binary(id) and is_list(shape) and is_integer(x) and is_integer(y) and is_binary(color) do
    true
  end
  defp valid_placed_piece?(_), do: false

  defp validate_available_pieces(nil), do: {:ok, []}
  defp validate_available_pieces(pieces) when is_list(pieces) do
    pieces = Enum.map(pieces, &map_to_piece/1)
    if Enum.all?(pieces, & &1) do
      {:ok, pieces}
    else
      {:error, :invalid_available_pieces}
    end
  end
  defp validate_available_pieces(_), do: {:error, :invalid_available_pieces}

  defp validate_current_piece(nil), do: {:ok, nil}
  defp validate_current_piece(piece_map) do
    case map_to_piece(piece_map) do
      nil -> {:error, :invalid_current_piece}
      piece -> {:ok, piece}
    end
  end

  defp map_to_piece(%{id: id, shape: shape, color: color}) when is_binary(id) and is_list(shape) and is_binary(color) do
    %Piece{id: id, shape: shape, color: color}
  end
  defp map_to_piece(_), do: nil
end