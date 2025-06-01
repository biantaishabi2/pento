defmodule PentoWeb.Components.ToolPalette do
  use Phoenix.Component

  @doc """
  Renders the tool palette showing available pentomino pieces
  """
  attr :available_pieces, :list, default: []
  attr :used_pieces, :any, default: MapSet.new()
  attr :current_piece, :map

  def palette(assigns) do
    ~H"""
    <div class="palette-container bg-white rounded-lg shadow-lg p-4">
      <h2 class="text-lg font-semibold mb-2 text-gray-800 text-sm">可用方块</h2>
      
      <%= if Enum.empty?(@available_pieces) do %>
        <p class="text-gray-500 text-center py-4 text-sm">所有方块已使用</p>
      <% else %>
        <div class="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-6 gap-1.5 max-h-[200px] overflow-y-auto">
          <%= for piece <- @available_pieces do %>
            <div
              data-piece-id={piece.id}
              class={piece_container_class(piece, @used_pieces, @current_piece)}
              phx-click={unless MapSet.member?(@used_pieces, piece.id), do: "select_piece"}
              phx-value-id={piece.id}
              role="button"
              aria-label={"选择方块 #{piece.id}"}
              tabindex={unless MapSet.member?(@used_pieces, piece.id), do: "0"}
            >
              <div class="piece-name text-xs font-bold text-gray-700 text-center mb-1">
                <%= piece.id %>
              </div>
              <svg width="48" height="48" viewBox="0 0 48 48" class="mx-auto">
                <g transform={center_piece_transform(piece.shape)}>
                  <%= for {x, y} <- piece.shape do %>
                    <rect
                      x={x * 9}
                      y={y * 9}
                      width="9"
                      height="9"
                      fill={piece.color}
                      stroke="#374151"
                      stroke-width="1"
                      rx="1"
                      class={if piece.id in @used_pieces, do: "opacity-30"}
                    />
                  <% end %>
                </g>
              </svg>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  # Private functions

  defp piece_container_class(piece, used_pieces, current_piece) do
    base_class = "palette-piece p-1.5 rounded-lg border-2 transition-all"
    
    cond do
      piece.id in used_pieces ->
        "#{base_class} piece-used piece-unavailable border-gray-200 bg-gray-50 cursor-not-allowed opacity-50"
        
      current_piece && current_piece.id == piece.id ->
        "#{base_class} piece-selected border-blue-500 bg-blue-50 ring-2 ring-blue-300"
        
      true ->
        "#{base_class} piece-available border-gray-300 hover:border-blue-400 hover:bg-blue-50 cursor-pointer"
    end
  end

  defp center_piece_transform(shape) do
    # Find bounds of the shape
    {min_x, max_x} = shape |> Enum.map(&elem(&1, 0)) |> Enum.min_max()
    {min_y, max_y} = shape |> Enum.map(&elem(&1, 1)) |> Enum.min_max()
    
    # Calculate piece dimensions (using smaller cell size)
    cell_size = 9
    width = (max_x - min_x + 1) * cell_size
    height = (max_y - min_y + 1) * cell_size
    
    # Center in 48x48 viewbox
    translate_x = (48 - width) / 2 - min_x * cell_size
    translate_y = (48 - height) / 2 - min_y * cell_size
    
    "translate(#{translate_x}, #{translate_y})"
  end
end