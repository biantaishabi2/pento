defmodule Pento.Games.GameSession do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  
  schema "game_sessions" do
    field :session_id, :string
    field :user_id, :integer
    field :game_state, :map
    field :board_size, :map
    field :progress, :float, default: 0.0
    field :is_completed, :boolean, default: false
    field :last_active_at, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(game_session, attrs) do
    game_session
    |> cast(attrs, [:session_id, :user_id, :game_state, :board_size, :progress, :is_completed, :last_active_at])
    |> validate_required([:session_id, :game_state, :board_size])
    |> validate_number(:progress, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> unique_constraint(:session_id)
    |> put_last_active_at()
  end

  @doc false
  def update_changeset(game_session, attrs) do
    game_session
    |> cast(attrs, [:game_state, :progress, :is_completed])
    |> validate_required([:game_state])
    |> validate_number(:progress, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> maybe_mark_completed()
    |> put_last_active_at()
  end

  defp put_last_active_at(changeset) do
    put_change(changeset, :last_active_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  defp maybe_mark_completed(changeset) do
    progress = get_field(changeset, :progress)
    
    if progress == 100.0 do
      put_change(changeset, :is_completed, true)
    else
      changeset
    end
  end
end