defmodule PentoWeb.Components.ToolPaletteTest do
  use PentoWeb.ComponentCase, async: true
  alias PentoWeb.Components.ToolPalette

  describe "palette/1" do
    test "renders all available pieces" do
      available_pieces = [
        %{id: "F", shape: [{0, 1}, {1, 0}, {1, 1}, {1, 2}, {2, 1}], color: "#FF6B6B"},
        %{id: "I", shape: [{0, 0}, {0, 1}, {0, 2}, {0, 3}, {0, 4}], color: "#4ECDC4"},
        %{id: "L", shape: [{0, 0}, {0, 1}, {0, 2}, {0, 3}, {1, 3}], color: "#45B7D1"}
      ]
      
      assigns = %{
        available_pieces: available_pieces,
        used_pieces: MapSet.new(),
        current_piece: nil
      }
      
      html = render_test_component(&ToolPalette.palette/1, assigns)
      
      # Check all pieces are rendered
      assert html =~ ~s(phx-value-id="F")
      assert html =~ ~s(phx-value-id="I")
      assert html =~ ~s(phx-value-id="L")
    end

    test "marks used pieces differently" do
      available_pieces = [
        %{id: "F", shape: [{0, 1}, {1, 0}, {1, 1}, {1, 2}, {2, 1}], color: "#FF6B6B"},
        %{id: "I", shape: [{0, 0}, {0, 1}, {0, 2}, {0, 3}, {0, 4}], color: "#4ECDC4"}
      ]
      
      assigns = %{
        available_pieces: available_pieces,
        used_pieces: MapSet.new(["F"]), # F is already placed
        current_piece: nil
      }
      
      html = render_test_component(&ToolPalette.palette/1, assigns)
      
      # Check F is marked as used
      assert html =~ "opacity-30"
      assert html =~ ~s(phx-value-id="F")
    end

    test "highlights currently selected piece" do
      available_pieces = [
        %{id: "F", shape: [{0, 1}, {1, 0}, {1, 1}, {1, 2}, {2, 1}], color: "#FF6B6B"},
        %{id: "I", shape: [{0, 0}, {0, 1}, {0, 2}, {0, 3}, {0, 4}], color: "#4ECDC4"}
      ]
      
      assigns = %{
        available_pieces: available_pieces,
        used_pieces: MapSet.new(),
        current_piece: %{id: "I", shape: [{0, 0}, {0, 1}, {0, 2}, {0, 3}, {0, 4}], color: "#4ECDC4"} # I is selected
      }
      
      html = render_test_component(&ToolPalette.palette/1, assigns)
      
      # Check I is highlighted
      assert html =~ "ring-2"
      assert html =~ ~s(phx-value-id="I")
    end

    test "includes click handlers for available pieces" do
      available_pieces = [
        %{id: "F", shape: [{0, 1}, {1, 0}, {1, 1}, {1, 2}, {2, 1}], color: "#FF6B6B"}
      ]
      
      assigns = %{
        available_pieces: available_pieces,
        used_pieces: MapSet.new(),
        current_piece: nil
      }
      
      html = render_test_component(&ToolPalette.palette/1, assigns)
      
      # Check click handler
      assert html =~ "phx-click"
      assert html =~ "select_piece"
    end

    test "shows palette title" do
      assigns = %{
        available_pieces: [],
        used_pieces: MapSet.new(),
        current_piece: nil
      }
      
      html = render_test_component(&ToolPalette.palette/1, assigns)
      
      # Check title
      assert html =~ "palette-container"
      assert html =~ "可用方块"
    end

    test "shows empty state when no pieces available" do
      assigns = %{
        available_pieces: [],
        used_pieces: MapSet.new(),
        current_piece: nil
      }
      
      html = render_test_component(&ToolPalette.palette/1, assigns)
      
      # Should still show container even if empty
      assert html =~ "palette-container"
    end
  end
end