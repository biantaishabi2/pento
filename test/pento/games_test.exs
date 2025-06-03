defmodule Pento.GamesTest do
  use Pento.DataCase, async: true
  
  alias Pento.Games
  alias Pento.Games.GameSession
  import PentoWeb.GameTestHelpers
  import Ecto.Query

  describe "get_or_create_session/2" do
    test "creates new session if not exists" do
      session_id = "new-session-#{System.unique_integer()}"
      
      assert {:ok, session} = Games.get_or_create_session(session_id)
      assert session.session_id == session_id
      assert session.game_state != nil
      assert session.board_size == %{cols: 10, rows: 6} or session.board_size == %{"cols" => 10, "rows" => 6}
      assert session.progress == 0.0
      assert session.is_completed == false
    end
    
    test "returns existing session if exists" do
      session_id = "existing-session-#{System.unique_integer()}"
      {:ok, original} = Games.get_or_create_session(session_id)
      
      # Place a piece to modify state
      new_state = create_test_game_state([test_placed_piece("F", {0, 0})])
      {:ok, _} = Games.save_game_state(session_id, new_state)
      
      # Get session again
      {:ok, retrieved} = Games.get_or_create_session(session_id)
      assert retrieved.id == original.id
      assert length(retrieved.game_state["placed_pieces"]) == 1
    end

    test "creates session without user_id" do
      session_id = "user-session-#{System.unique_integer()}"
      
      assert {:ok, session} = Games.get_or_create_session(session_id)
      assert session.user_id == nil
    end
  end

  describe "save_game_state/2" do
    setup do
      session_id = "save-test-#{System.unique_integer()}"
      {:ok, session} = Games.get_or_create_session(session_id)
      {:ok, session: session}
    end

    test "updates game state and progress", %{session: session} do
      new_state = %{
        board_size: %{cols: 10, rows: 6},
        placed_pieces: [
          test_placed_piece("F", {0, 0}),
          test_placed_piece("I", {3, 0})
        ],
        available_pieces: ["L", "N", "P", "T", "U", "V", "W", "X", "Y", "Z"],
        current_piece: nil,
        history: []
      }
      
      assert {:ok, updated} = Games.save_game_state(session.session_id, new_state)
      # Reload to get updated state
      updated = Repo.get!(GameSession, updated.id)
      assert length(updated.game_state["placed_pieces"]) == 2
      assert updated.progress == calculate_progress(2)
      assert DateTime.compare(updated.last_active_at, session.last_active_at) in [:gt, :eq]
    end
    
    test "marks game as completed when progress is 100", %{session: session} do
      # Create state with all pieces placed
      all_pieces = ["F", "I", "L", "N", "P", "T", "U", "V", "W", "X", "Y", "Z"]
      placed_pieces = Enum.with_index(all_pieces) |> Enum.map(fn {id, idx} ->
        test_placed_piece(id, {rem(idx, 10), div(idx, 10)})
      end)
      
      complete_state = %{
        board_size: %{cols: 10, rows: 6},
        placed_pieces: placed_pieces,
        available_pieces: [],
        current_piece: nil,
        history: []
      }
      
      {:ok, updated} = Games.save_game_state(session.session_id, complete_state)
      assert updated.is_completed == true
      assert updated.progress == 100.0
    end

    test "handles invalid session_id" do
      assert {:error, :not_found} = Games.save_game_state("non-existent", %{})
    end

    test "calculates progress correctly" do
      pieces_to_test = [
        {["F"], 8.3},
        {["F", "I"], 16.7},
        {["F", "I", "L"], 25.0},
        {["F", "I", "L", "N", "P", "T"], 50.0},
        {["F", "I", "L", "N", "P", "T", "U", "V", "W"], 75.0}
      ]
      
      for {piece_ids, expected_progress} <- pieces_to_test do
        session_id = "progress-test-#{System.unique_integer()}"
        {:ok, _session} = Games.get_or_create_session(session_id)
        
        placed_pieces = Enum.with_index(piece_ids) |> Enum.map(fn {id, idx} ->
          test_placed_piece(id, {idx, 0})
        end)
        
        state = create_test_game_state(placed_pieces)
        {:ok, updated} = Games.save_game_state(session_id, state)
        
        assert updated.progress == expected_progress
      end
    end
  end

  describe "load_game_state/1" do
    test "loads existing session" do
      session_id = "load-test-#{System.unique_integer()}"
      {:ok, original} = Games.get_or_create_session(session_id)
      
      # Modify state
      state = create_test_game_state([test_placed_piece("F", {0, 0})])
      {:ok, _} = Games.save_game_state(session_id, state)
      
      # Load
      assert {:ok, loaded} = Games.load_game_state(session_id)
      assert loaded.id == original.id
      assert length(loaded.game_state["placed_pieces"]) == 1
    end

    test "returns error for non-existent session" do
      assert {:error, :not_found} = Games.load_game_state("non-existent")
    end
  end

  describe "delete_old_sessions/1" do
    test "deletes sessions older than specified days" do
      # Create old session (31 days ago)
      old_date = DateTime.utc_now() |> DateTime.add(-31, :day) |> DateTime.truncate(:second)
      old_attrs = %{
        session_id: "old-session-#{System.unique_integer()}",
        game_state: create_test_game_state(),
        board_size: %{cols: 10, rows: 6},
        last_active_at: old_date,
        progress: 0.0
      }
      {:ok, old_session} = %GameSession{}
      |> GameSession.changeset(old_attrs)
      |> Repo.insert()
      
      # Force update to set the old date
      from(gs in GameSession, where: gs.id == ^old_session.id)
      |> Repo.update_all(set: [last_active_at: old_date])
      
      # Create recent session
      {:ok, new_session} = Games.get_or_create_session("new-session-#{System.unique_integer()}")
      
      # Delete old sessions
      deleted_count = Games.delete_old_sessions(30)
      
      assert deleted_count == 1
      assert Repo.get(GameSession, old_session.id) == nil
      assert Repo.get(GameSession, new_session.id) != nil
    end

    test "keeps sessions within the time window" do
      # Create session 29 days ago (should be kept)
      recent_date = DateTime.utc_now() |> DateTime.add(-29, :day)
      attrs = %{
        session_id: "recent-session",
        game_state: create_test_game_state(),
        board_size: %{cols: 10, rows: 6},
        last_active_at: recent_date
      }
      {:ok, session} = %GameSession{}
      |> GameSession.changeset(attrs)
      |> Repo.insert()
      
      deleted_count = Games.delete_old_sessions(30)
      
      assert deleted_count == 0
      assert Repo.get(GameSession, session.id) != nil
    end
  end

  describe "get_session_by_id/1" do
    test "retrieves session by session_id" do
      session_id = "get-by-id-test"
      {:ok, created} = Games.get_or_create_session(session_id)
      
      retrieved = Games.get_session_by_id(session_id)
      assert retrieved != nil
      assert retrieved.id == created.id
    end

    test "returns nil for non-existent session" do
      assert Games.get_session_by_id("non-existent") == nil
    end
  end

  # Skip user-related tests since we don't have user system
end