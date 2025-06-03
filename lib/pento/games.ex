defmodule Pento.Games do
  @moduledoc """
  The Games context for managing game sessions and persistence.
  """

  import Ecto.Query, warn: false
  alias Pento.Repo
  alias Pento.Games.GameSession

  @doc """
  Gets or creates a game session by session_id.
  """
  def get_or_create_session(session_id, user_id \\ nil) do
    case get_session_by_id(session_id) do
      nil ->
        create_session(session_id, user_id)
      
      session ->
        {:ok, session}
    end
  end

  @doc """
  Creates a new game session.
  """
  def create_session(session_id, user_id \\ nil) do
    initial_state = %{
      board_size: %{cols: 10, rows: 6},
      placed_pieces: [],
      available_pieces: ["F", "I", "L", "N", "P", "T", "U", "V", "W", "X", "Y", "Z"],
      current_piece: nil,
      history: []
    }

    attrs = %{
      session_id: session_id,
      user_id: user_id,
      game_state: initial_state,
      board_size: %{cols: 10, rows: 6},
      progress: 0.0,
      is_completed: false
    }

    %GameSession{}
    |> GameSession.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Saves the game state for a session.
  """
  def save_game_state(session_id, game_state) do
    case get_session_by_id(session_id) do
      nil ->
        {:error, :not_found}
      
      session ->
        # Calculate progress
        total_pieces = 12
        placed_count = length(Map.get(game_state, :placed_pieces, []))
        progress = Float.round(placed_count / total_pieces * 100, 1)

        attrs = %{
          game_state: game_state,
          progress: progress
        }

        session
        |> GameSession.update_changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Loads the game state for a session.
  """
  def load_game_state(session_id) do
    case get_session_by_id(session_id) do
      nil -> {:error, :not_found}
      session -> {:ok, session}
    end
  end

  @doc """
  Gets a game session by session_id.
  """
  def get_session_by_id(session_id) do
    Repo.get_by(GameSession, session_id: session_id)
  end

  # User-related functions removed - no user system in this game

  @doc """
  Deletes sessions older than the specified number of days.
  Returns the number of deleted sessions.
  """
  def delete_old_sessions(days \\ 30) do
    cutoff_date = DateTime.utc_now() |> DateTime.add(-days, :day)

    {deleted_count, _} = 
      GameSession
      |> where([s], s.last_active_at < ^cutoff_date)
      |> Repo.delete_all()

    deleted_count
  end

  @doc """
  Checks if a session exists.
  """
  def session_exists?(session_id) do
    GameSession
    |> where([s], s.session_id == ^session_id)
    |> Repo.exists?()
  end

  @doc """
  Gets statistics for a game session.
  """
  def get_session_stats(session_id) do
    case get_session_by_id(session_id) do
      nil ->
        {:error, :not_found}
      
      session ->
        stats = %{
          progress: session.progress,
          is_completed: session.is_completed,
          pieces_placed: length(session.game_state["placed_pieces"] || []),
          total_pieces: 12,
          created_at: session.inserted_at,
          last_active_at: session.last_active_at,
          duration: calculate_duration(session)
        }
        
        {:ok, stats}
    end
  end

  defp calculate_duration(%GameSession{} = session) do
    if session.is_completed do
      DateTime.diff(session.updated_at, session.inserted_at, :second)
    else
      DateTime.diff(DateTime.utc_now(), session.inserted_at, :second)
    end
  end
end