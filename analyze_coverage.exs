#!/usr/bin/env elixir

# Script to analyze test coverage of Pento game

defmodule TestCoverageAnalyzer do
  @moduledoc """
  Analyzes test coverage by comparing design documents with actual tests
  """

  def analyze do
    IO.puts("=== Pento Test Coverage Analysis ===\n")
    
    # Check existing test files
    test_files = Path.wildcard("test/**/*_test.exs")
    
    IO.puts("## Test Files Found:")
    Enum.each(test_files, fn file ->
      IO.puts("  - #{file}")
    end)
    
    IO.puts("\n## Backend Test Coverage:")
    check_backend_coverage()
    
    IO.puts("\n## Frontend Test Coverage:")
    check_frontend_coverage()
    
    IO.puts("\n## Missing Tests:")
    check_missing_tests()
    
    IO.puts("\n## Test Quality Issues:")
    check_test_quality()
  end
  
  defp check_backend_coverage do
    # Check core modules
    modules = [
      {"Pento.Game", "test/pento/game_test.exs", ["new_game", "select_piece", "place_piece", "rotate_piece", "flip_piece", "remove_piece", "undo", "reset_game", "get_progress", "is_complete?", "valid_positions", "save_game", "load_game"]},
      {"Pento.Game.Piece", "test/pento/game/piece_test.exs", ["all_pieces", "get_piece", "rotate_piece", "flip_piece", "get_absolute_positions", "normalize_shape", "is_connected?"]},
      {"Pento.Game.Board", "test/pento/game/board_test.exs", ["within_bounds?", "has_collision?", "get_occupied_cells", "valid_positions", "calculate_coverage", "is_complete?"]},
      {"Pento.Game.State", "test/pento/game/state_test.exs", ["new", "select_piece", "place_piece", "rotate_current_piece", "flip_current_piece", "remove_piece", "undo", "get_progress", "is_complete?", "to_map", "from_map"]},
      {"Pento.Game.Boundary", "test/pento/game/boundary_test.exs", ["board boundary validation", "piece placement boundary validation", "collision detection near boundaries", "valid positions calculation with boundaries", "board size validation"]}
    ]
    
    Enum.each(modules, fn {module, file, functions} ->
      if File.exists?(file) do
        content = File.read!(file)
        tested = Enum.filter(functions, &String.contains?(content, &1))
        missing = functions -- tested
        coverage = length(tested) / length(functions) * 100
        
        IO.puts("  #{module}: #{round(coverage)}% coverage")
        if length(missing) > 0 do
          IO.puts("    Missing: #{Enum.join(missing, ", ")}")
        end
      else
        IO.puts("  #{module}: NO TEST FILE FOUND")
      end
    end)
  end
  
  defp check_frontend_coverage do
    # Check LiveView and component tests
    components = [
      {"GameLive", "test/pento_web/live/game_live_test.exs", ["mount", "select_piece", "drop_at_cell", "rotate_piece", "flip_piece", "remove_piece", "undo", "reset", "auto_save"]},
      {"GameLive Interactions", "test/pento_web/live/game_live_interaction_test.exs", ["drag and drop", "keyboard shortcuts", "touch interactions", "error handling"]},
      {"Coordinate Conversion", "test/pento_web/live/coordinate_conversion_test.exs", ["pixel_to_grid", "grid_to_pixel", "SVG coordinates", "clamping"]},
      {"GameBoard Component", "test/pento_web/components/game_board_test.exs", ["render board", "placed pieces", "ghost piece", "valid positions"]},
      {"ToolPalette Component", "test/pento_web/components/tool_palette_test.exs", ["render pieces", "used pieces", "selection"]}
    ]
    
    Enum.each(components, fn {component, file, features} ->
      if File.exists?(file) do
        content = File.read!(file)
        tested = Enum.filter(features, &String.contains?(content, &1))
        missing = features -- tested
        coverage = length(tested) / length(features) * 100
        
        IO.puts("  #{component}: #{round(coverage)}% coverage")
        if length(missing) > 0 do
          IO.puts("    Missing: #{Enum.join(missing, ", ")}")
        end
      else
        IO.puts("  #{component}: NO TEST FILE FOUND")
      end
    end)
  end
  
  defp check_missing_tests do
    # Features from design docs that might be missing tests
    missing_features = [
      "History limit (10 entries) - partially tested",
      "Perfect win condition with 100% board coverage - mocked instead of real",
      "Complex rotation/flip combinations - basic tests only",
      "Performance tests (rapid operations, memory leaks) - basic implementation",
      "Responsive design tests - basic structure only",
      "Touch gesture support (pinch zoom) - not implemented",
      "Theme system - not tested",
      "Game modes (timed, tutorial) - not implemented",
      "Accessibility features (ARIA, screen reader) - not tested",
      "Sound effects toggle - not implemented",
      "Animation effects - basic tests only",
      "WebSocket reconnection - not tested",
      "Session persistence across page reloads - basic test only",
      "Concurrent game state updates - not tested",
      "Edge case: corrupted save data recovery - basic test only"
    ]
    
    Enum.each(missing_features, &IO.puts("  - #{&1}"))
  end
  
  defp check_test_quality do
    issues = [
      "Win condition test uses mocked state instead of placing all 12 pieces correctly",
      "Some integration tests are marked as 'simplified' and don't test full scenarios",
      "Board completion test at 85% instead of 100% (test/pento/game/board_test.exs:276)",
      "Auto-save restore test doesn't actually verify restoration after reload",
      "Keyboard event tests have workarounds due to LiveView limitations",
      "Some boundary tests use simplified piece placements",
      "Performance tests use small datasets (10-100 operations)",
      "Touch events are tested through click handlers, not actual touch simulation"
    ]
    
    Enum.each(issues, &IO.puts("  - #{&1}"))
  end
end

# Run the analysis
TestCoverageAnalyzer.analyze()