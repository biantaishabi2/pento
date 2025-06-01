defmodule PentoWeb.Components.GameBoard do
  use Phoenix.Component

  @doc """
  Renders the game board with grid, placed pieces, and interaction layers
  """
  attr :board_size, :any, required: true
  attr :placed_pieces, :list, default: []
  attr :dragging, :boolean, default: false
  attr :cursor, :any, default: {0, 0}
  attr :ghost_position, :any
  attr :ghost_piece, :map
  attr :valid_positions, :list, default: []
  attr :cell_size, :integer, default: 30

  def board(assigns) do
    {cols, rows} = assigns.board_size
    svg_width = cols * assigns.cell_size
    svg_height = rows * assigns.cell_size
    
    assigns = assigns
    |> assign(:svg_width, svg_width)
    |> assign(:svg_height, svg_height)
    |> assign(:cols, cols)
    |> assign(:rows, rows)
    
    ~H"""
    <div class="game-board-container bg-white rounded-lg shadow-lg p-2">
      <svg
        id="board"
        class="game-board cursor-crosshair w-full h-auto"
        viewBox={"0 0 #{@svg_width} #{@svg_height}"}
        preserveAspectRatio="xMidYMid meet"
        phx-mousemove="mouse_move"
        phx-mouseup="drop_piece"
      >
        <!-- Grid Background -->
        <g class="grid-layer">
          <%= for x <- 0..(@cols - 1), y <- 0..(@rows - 1) do %>
            <rect
              x={x * @cell_size}
              y={y * @cell_size}
              width={@cell_size}
              height={@cell_size}
              fill="transparent"
              stroke="#e5e7eb"
              stroke-width="1"
              class="grid-cell hover:fill-gray-100"
              style={if not @dragging, do: "pointer-events: none;", else: ""}
              phx-click={if @dragging, do: "drop_at_cell", else: nil}
              phx-value-x={x}
              phx-value-y={y}
            />
          <% end %>
        </g>

        <!-- Valid Positions Highlights -->
        <%= if @dragging do %>
          <g class="valid-positions-layer" pointer-events="none">
            <%= for {x, y} <- @valid_positions do %>
              <rect
                x={x * @cell_size}
                y={y * @cell_size}
                width={@cell_size}
                height={@cell_size}
                fill="#10b981"
                fill-opacity="0.15"
                stroke="#10b981"
                stroke-width="1"
                stroke-dasharray="3,3"
                class="valid-position"
                pointer-events="none"
              />
            <% end %>
          </g>
        <% end %>

        <!-- Placed Pieces -->
        <g class="placed-pieces-layer">
          <%= for piece <- @placed_pieces do %>
            <g 
              class="placed-piece group"
              data-id={piece.id}
              transform={"translate(#{elem(piece.position, 0) * @cell_size}, #{elem(piece.position, 1) * @cell_size})"}
            >
              <%= for {x, y} <- piece.shape do %>
                <rect
                  x={x * @cell_size}
                  y={y * @cell_size}
                  width={@cell_size}
                  height={@cell_size}
                  fill={piece.color}
                  stroke="#374151"
                  stroke-width="2"
                  rx="4"
                  class="piece-cell group-hover:opacity-80 transition-opacity cursor-pointer"
                  style="pointer-events: auto;"
                  phx-click="remove_piece"
                  phx-value-id={piece.id}
                />
              <% end %>
              <!-- Remove hint on hover -->
              <title>点击移除</title>
            </g>
          <% end %>
        </g>

        <!-- Ghost Piece Preview -->
        <%= if @dragging and @ghost_position != nil and @ghost_piece != nil do %>
          <g 
            class="ghost-piece-layer"
            transform={"translate(#{elem(@ghost_position, 0) * @cell_size}, #{elem(@ghost_position, 1) * @cell_size})"}
            opacity="0.5"
            pointer-events="none"
          >
            <% valid = @ghost_position in @valid_positions %>
            <%= for {x, y} <- @ghost_piece.shape do %>
              <rect
                x={x * @cell_size}
                y={y * @cell_size}
                width={@cell_size}
                height={@cell_size}
                fill={if valid, do: @ghost_piece.color, else: "#ef4444"}
                stroke={if valid, do: "#374151", else: "red"}
                stroke-width="2"
                rx="4"
                class={if valid, do: "ghost-valid", else: "ghost-invalid"}
              />
            <% end %>
          </g>
        <% end %>

        <!-- Cursor Indicator -->
        <%= if @dragging do %>
          <circle
            cx={elem(@cursor, 0) * @cell_size + @cell_size / 2}
            cy={elem(@cursor, 1) * @cell_size + @cell_size / 2}
            r="3"
            fill="#3b82f6"
            class="cursor-indicator animate-ping"
            pointer-events="none"
          />
        <% end %>
      </svg>
    </div>
    """
  end
end