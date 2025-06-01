defmodule PentoWeb.ComponentCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that test Phoenix components.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with Phoenix components
      import Phoenix.Component
      import Phoenix.LiveViewTest
      
      # The default endpoint for testing
      @endpoint PentoWeb.Endpoint
      
      # Helper to render components to string
      def render_test_component(component, assigns) do
        Phoenix.LiveViewTest.render_component(component, assigns)
      end
    end
  end
end