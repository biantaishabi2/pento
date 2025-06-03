defmodule Pento.Games.GameSessionTest do
  use Pento.DataCase, async: true
  
  alias Pento.Games.GameSession
  import PentoWeb.GameTestHelpers

  describe "changeset/2" do
    test "creates game session with valid attributes" do
      attrs = %{
        session_id: "test-session-123",
        game_state: create_test_game_state(),
        board_size: %{cols: 10, rows: 6},
        progress: 0.0,
        is_completed: false
      }
      
      changeset = GameSession.changeset(%GameSession{}, attrs)
      assert changeset.valid?
      
      {:ok, session} = Repo.insert(changeset)
      assert session.session_id == "test-session-123"
      assert session.progress == 0.0
      assert session.is_completed == false
    end

    test "requires session_id and game_state" do
      attrs = %{}
      changeset = GameSession.changeset(%GameSession{}, attrs)
      
      refute changeset.valid?
      assert %{
        session_id: ["can't be blank"], 
        game_state: ["can't be blank"],
        board_size: ["can't be blank"]
      } = errors_on(changeset)
    end

    test "validates progress range" do
      attrs = %{
        session_id: "test",
        game_state: %{},
        board_size: %{cols: 10, rows: 6},
        progress: 150.0
      }
      
      changeset = GameSession.changeset(%GameSession{}, attrs)
      assert %{progress: ["must be less than or equal to 100"]} = errors_on(changeset)
      
      attrs = %{attrs | progress: -10.0}
      changeset = GameSession.changeset(%GameSession{}, attrs)
      assert %{progress: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "properly serializes and deserializes game state" do
      placed_piece = test_placed_piece("F", {0, 0})
      game_state = create_test_game_state([placed_piece])
      
      attrs = %{
        session_id: "test-json",
        game_state: game_state,
        board_size: %{cols: 10, rows: 6},
        progress: calculate_progress(1)
      }
      
      {:ok, session} = %GameSession{}
      |> GameSession.changeset(attrs)
      |> Repo.insert()
      
      # Reload from database
      retrieved = Repo.get!(GameSession, session.id)
      
      assert retrieved.game_state["placed_pieces"] |> length() == 1
      assert hd(retrieved.game_state["placed_pieces"])["id"] == "F"
      assert retrieved.progress == 8.3
    end

    test "sets timestamps automatically" do
      attrs = %{
        session_id: "test-timestamps",
        game_state: create_test_game_state(),
        board_size: %{cols: 10, rows: 6}
      }
      
      {:ok, session} = %GameSession{}
      |> GameSession.changeset(attrs)
      |> Repo.insert()
      
      assert session.inserted_at != nil
      assert session.updated_at != nil
      assert session.last_active_at != nil
    end

    test "unique constraint on session_id" do
      attrs = %{
        session_id: "unique-test",
        game_state: create_test_game_state(),
        board_size: %{cols: 10, rows: 6}
      }
      
      {:ok, _} = %GameSession{}
      |> GameSession.changeset(attrs)
      |> Repo.insert()
      
      {:error, changeset} = %GameSession{}
      |> GameSession.changeset(attrs)
      |> Repo.insert()
      
      assert %{session_id: ["has already been taken"]} = errors_on(changeset)
    end
  end

  describe "update_changeset/2" do
    setup do
      {:ok, session} = %GameSession{}
      |> GameSession.changeset(%{
        session_id: "update-test",
        game_state: create_test_game_state(),
        board_size: %{cols: 10, rows: 6}
      })
      |> Repo.insert()
      
      {:ok, session: session}
    end

    test "updates game state and progress", %{session: session} do
      placed_pieces = [
        test_placed_piece("F", {0, 0}),
        test_placed_piece("I", {3, 0})
      ]
      new_state = create_test_game_state(placed_pieces)
      
      attrs = %{
        game_state: new_state,
        progress: calculate_progress(2)
      }
      
      {:ok, updated} = session
      |> GameSession.update_changeset(attrs)
      |> Repo.update()
      
      # Reload to get the updated game_state
      updated = Repo.get!(GameSession, updated.id)
      
      assert updated.game_state["placed_pieces"] |> length() == 2
      assert updated.progress == 16.7
      assert DateTime.compare(updated.last_active_at, session.last_active_at) == :gt ||  DateTime.compare(updated.last_active_at, session.last_active_at) == :eq
    end

    test "sets is_completed when progress reaches 100", %{session: session} do
      all_pieces = ["F", "I", "L", "N", "P", "T", "U", "V", "W", "X", "Y", "Z"]
      placed_pieces = Enum.map(all_pieces, fn id ->
        test_placed_piece(id, random_position())
      end)
      
      attrs = %{
        game_state: create_test_game_state(placed_pieces),
        progress: 100.0
      }
      
      {:ok, updated} = session
      |> GameSession.update_changeset(attrs)
      |> Repo.update()
      
      assert updated.is_completed == true
      assert updated.progress == 100.0
    end
  end
end