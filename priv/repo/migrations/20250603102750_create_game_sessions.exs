defmodule Pento.Repo.Migrations.CreateGameSessions do
  use Ecto.Migration

  def change do
    create table(:game_sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :session_id, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all)
      add :game_state, :map, null: false
      add :board_size, :map, null: false
      add :progress, :float, null: false, default: 0.0
      add :is_completed, :boolean, default: false, null: false
      add :last_active_at, :utc_datetime, null: false

      timestamps()
    end

    create unique_index(:game_sessions, [:session_id])
    create index(:game_sessions, [:user_id])
    create index(:game_sessions, [:last_active_at])
    create index(:game_sessions, [:is_completed])
  end
end