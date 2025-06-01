defmodule Pento.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :username, :string, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      
      # 统计字段
      add :games_played, :integer, default: 0
      add :games_won, :integer, default: 0
      add :total_score, :integer, default: 0
      add :best_time, :integer
      
      # JSONB for preferences
      add :preferences, :map, default: %{}
      
      timestamps()
    end
    
    create unique_index(:users, [:email])
    create unique_index(:users, [:username])
    create index(:users, [:total_score])  # 用于排行榜
  end
end
