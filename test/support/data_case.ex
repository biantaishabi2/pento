defmodule Pento.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Pento.DataCase
    end
  end

  setup _tags do
    # No database setup needed
    :ok
  end

  # Database sandbox setup removed - not needed for this project

  # Changeset error helper removed - not needed without Ecto
end
