defmodule PentoWeb.GameLive do
  use PentoWeb, :live_view
  
  alias Pento.Game
  alias PentoWeb.Components.{GameBoard, ToolPalette, HelpModal}

  @impl true
  def mount(_params, session, socket) do
    game_state = load_or_create_game(session)
    
    if connected?(socket) do
      :timer.send_interval(30_000, self(), :auto_save)
    end
    
    socket = socket
    |> assign(:page_title, "Pentomino Puzzle")
    |> assign(:game_state, game_state)
    |> assign(:dragging, false)
    |> assign(:cursor, {0, 0})
    |> assign(:ghost_position, nil)
    |> assign(:valid_positions, [])
    |> assign(:game_won, Game.is_complete?(game_state))
    |> assign(:error_message, nil)
    |> assign(:last_saved, nil)
    |> assign(:cell_size, get_cell_size())
    |> assign(:show_help, false)
    
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="game" class="min-h-screen bg-gray-100" phx-window-keydown="handle_keydown">
      <div class="container mx-auto px-2 py-4">
        <header class="text-center mb-4">
          <h1 class="text-2xl font-bold text-gray-800 mb-2">Pentomino Puzzle</h1>
          <div class="max-w-md mx-auto">
            <div class="bg-white rounded-lg shadow p-3">
              <div class="flex items-center justify-between mb-2">
                <span class="text-sm font-medium text-gray-600">进度</span>
                <span class="text-sm font-bold text-gray-800">
                  <%= Float.round(Game.get_progress(@game_state), 1) %>% 完成
                </span>
              </div>
              <div class="w-full bg-gray-200 rounded-full h-3">
                <div 
                  class="bg-gradient-to-r from-blue-400 to-blue-600 h-3 rounded-full transition-all duration-300"
                  style={"width: #{Game.get_progress(@game_state)}%"}
                >
                </div>
              </div>
            </div>
          </div>
        </header>

        <div class="flex flex-col gap-2 max-w-full mx-auto">
          <!-- 游戏板 - 优化移动端显示 -->
          <div class="w-full px-2">
            <GameBoard.board
              board_size={@game_state.board_size}
              placed_pieces={@game_state.placed_pieces}
              dragging={@dragging}
              cursor={@cursor}
              ghost_position={@ghost_position}
              ghost_piece={@game_state.current_piece}
              valid_positions={@valid_positions}
              cell_size={@cell_size}
            />
          </div>

          <!-- 操作提示 - 选中拼图块时显示 -->
          <%= if @dragging do %>
            <div class="text-center mb-2">
              <div class="inline-flex items-center gap-3 bg-green-50 border border-green-200 rounded-lg px-3 py-2">
                <!-- 当前选中的方块预览 -->
                <%= if @game_state.current_piece do %>
                  <div class="flex items-center gap-2">
                    <span class="text-xs text-gray-500">当前方块:</span>
                    <svg width="30" height="30" viewBox="0 0 60 60" class="border border-gray-300 rounded bg-white">
                      <g transform={center_piece_for_preview(@game_state.current_piece.shape)}>
                        <%= for {x, y} <- @game_state.current_piece.shape do %>
                          <rect
                            x={x * 10}
                            y={y * 10}
                            width="10"
                            height="10"
                            fill={@game_state.current_piece.color}
                            stroke="#374151"
                            stroke-width="1"
                            rx="1"
                          />
                        <% end %>
                      </g>
                    </svg>
                  </div>
                <% end %>
                
                <p class="text-sm text-gray-600">
                  <span class="text-green-600 font-semibold">✓</span> 
                  点击绿色虚线框放置
                </p>
              </div>
            </div>
            
            <!-- 控制按钮 -->
            <div class="flex justify-center gap-2 mb-2">
              <button
                phx-click="rotate_piece"
                phx-value-direction="clockwise"
                class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center gap-2 min-w-[120px]"
              >
                <.icon name="hero-arrow-path" class="w-5 h-5" />
                旋转
              </button>
              
              <button
                phx-click="flip_piece"
                phx-value-direction="horizontal"
                class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center gap-2 min-w-[120px]"
              >
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
                </svg>
                水平翻转
              </button>
              
              <button
                phx-click="flip_piece"
                phx-value-direction="vertical"
                class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center gap-2 min-w-[120px]"
              >
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16V4m0 0L3 8m4-4l4 4m6 0v12m0 0l4-4m-4 4l-4-4" />
                </svg>
                垂直翻转
              </button>
            </div>
          <% end %>

          <!-- 拼图块选择器 - 紧凑布局 -->
          <div class="w-full px-2">
            <ToolPalette.palette
              available_pieces={@game_state.available_pieces}
              used_pieces={get_used_pieces(@game_state)}
              current_piece={@game_state.current_piece}
            />
          </div>
        </div>

        <div class="mt-4 flex flex-col sm:flex-row items-center justify-center gap-2 sm:gap-4">
          <div class="flex gap-2">
            <button
              phx-click="undo"
              disabled={!can_undo?(@game_state)}
              class="px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              <.icon name="hero-arrow-uturn-left" class="w-5 h-5 inline mr-1" />
              撤销
            </button>
            
            <button
              phx-click="reset"
              disabled={Enum.empty?(@game_state.placed_pieces)}
              class="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              <.icon name="hero-arrow-path" class="w-5 h-5 inline mr-1" />
              重置
            </button>
          </div>

          <div class="text-xs sm:text-sm text-gray-600 text-center">
            点击选择方块，再点击放置
          </div>
        </div>

        <%= if @error_message do %>
          <div class="mt-4 max-w-md mx-auto">
            <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative" role="alert">
              <span class="block sm:inline"><%= @error_message %></span>
            </div>
          </div>
        <% end %>
        
        <!-- Debug: Test remove buttons -->
        <%= if not Enum.empty?(@game_state.placed_pieces) do %>
          <div class="mt-4 p-4 bg-gray-100 rounded">
            <h3 class="font-bold mb-2">Debug: 已放置的方块</h3>
            <div class="flex flex-wrap gap-2">
              <%= for piece <- @game_state.placed_pieces do %>
                <button
                  phx-click="remove_piece"
                  phx-value-id={piece.id}
                  class="px-3 py-1 bg-red-500 text-white rounded hover:bg-red-600"
                >
                  移除 <%= piece.id %>
                </button>
              <% end %>
            </div>
          </div>
        <% end %>

        <%= if @game_won do %>
          <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
            <div class="bg-white rounded-lg shadow-xl p-8 max-w-md animate-bounce-in">
              <h2 class="text-3xl font-bold text-center text-green-600 mb-4">
                🎉 恭喜完成！
              </h2>
              <p class="text-center text-gray-700 mb-6">
                你成功完成了拼图！
              </p>
              <button
                phx-click="new_game"
                class="w-full px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
              >
                开始新游戏
              </button>
            </div>
          </div>
        <% end %>

        <%= if @last_saved do %>
          <div class="fixed bottom-4 right-4 text-sm text-gray-600">
            已保存于 <%= format_time(@last_saved) %>
          </div>
        <% end %>

        <HelpModal.help_modal show={@show_help} />
        <HelpModal.help_button />
      </div>
    </div>
    """
  end

  # Event Handlers

  @impl true
  def handle_event(event, params, socket) do
    require Logger
    Logger.debug("GameLive received event: #{event} with params: #{inspect(params)}")
    
    case event do
      e when e in ["select_piece", "mouse_move", "drop_at_cell", "drop_piece", "rotate_piece", "flip_piece", "remove_piece", "undo", "reset", "new_game", "handle_keydown", "show_help", "close_help", "touch_start", "touch_move", "touch_end"] ->
        do_handle_event(event, params, socket)
      _ ->
        Logger.warning("Unhandled event: #{event} with params: #{inspect(params)}")
        {:noreply, socket}
    end
  end
  
  defp do_handle_event(event, params, socket) do
    handle_specific_event(event, params, socket)
  end

  defp handle_specific_event("select_piece", %{"id" => piece_id}, socket) do
    require Logger
    Logger.info("select_piece event: piece_id=#{piece_id}")
    
    case Game.select_piece(socket.assigns.game_state, piece_id) do
      {:ok, new_state} ->
        Logger.info("Piece #{piece_id} selected successfully")
        socket = socket
        |> assign(:game_state, new_state)
        |> assign(:dragging, true)
        |> assign(:valid_positions, Game.valid_positions(new_state))
        |> clear_error()
        
        {:noreply, socket}
        
      {:error, :piece_not_found} ->
        {:noreply, put_error(socket, "方块不存在")}
        
      {:error, :piece_not_available} ->
        {:noreply, put_error(socket, "方块已使用")}
    end
  end

  defp handle_specific_event("mouse_move", params, socket) do
    if socket.assigns.dragging do
      # Get coordinates from SVG event
      {x, y} = extract_svg_coordinates(params)
      cursor = pixel_to_grid({x, y}, socket.assigns.cell_size)
      ghost_position = cursor
      
      socket = socket
      |> assign(:cursor, cursor)
      |> assign(:ghost_position, ghost_position)
      
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  defp handle_specific_event("drop_at_cell", %{"x" => x, "y" => y}, socket) do
    require Logger
    Logger.info("drop_at_cell event: x=#{x}, y=#{y}, dragging=#{socket.assigns.dragging}")
    
    if socket.assigns.dragging do
      position = {String.to_integer(x), String.to_integer(y)}
      Logger.info("Attempting to place piece at position: #{inspect(position)}")
      
      case Game.place_piece(socket.assigns.game_state, position) do
        {:ok, new_state} ->
          socket = socket
          |> assign(:game_state, new_state)
          |> assign(:dragging, false)
          |> assign(:ghost_position, nil)
          |> assign(:valid_positions, [])
          |> check_win_condition()
          |> clear_error()
          
          {:noreply, socket}
          
        {:error, :no_piece_selected} ->
          {:noreply, put_error(socket, "请先选择一个方块")}
          
        {:error, :out_of_bounds} ->
          {:noreply, put_error(socket, "方块超出棋盘边界")}
          
        {:error, :collision} ->
          {:noreply, put_error(socket, "方块位置重叠")}
      end
    else
      {:noreply, socket}
    end
  end

  defp handle_specific_event("drop_piece", params, socket) do
    require Logger
    Logger.info("drop_piece event: params=#{inspect(params)}, dragging=#{socket.assigns.dragging}")
    
    if socket.assigns.dragging do
      {x, y} = extract_svg_coordinates(params)
      position = pixel_to_grid({x, y}, socket.assigns.cell_size)
      Logger.info("Calculated position from pixels: #{inspect({x, y})} -> grid: #{inspect(position)}")
      
      case Game.place_piece(socket.assigns.game_state, position) do
        {:ok, new_state} ->
          socket = socket
          |> assign(:game_state, new_state)
          |> assign(:dragging, false)
          |> assign(:ghost_position, nil)
          |> assign(:valid_positions, [])
          |> check_win_condition()
          |> clear_error()
          
          {:noreply, socket}
          
        {:error, :no_piece_selected} ->
          {:noreply, put_error(socket, "请先选择一个方块")}
          
        {:error, :out_of_bounds} ->
          {:noreply, put_error(socket, "方块超出棋盘边界")}
          
        {:error, :collision} ->
          {:noreply, put_error(socket, "方块位置重叠")}
      end
    else
      {:noreply, socket}
    end
  end

  defp handle_specific_event("rotate_piece", %{"direction" => direction}, socket) do
    if socket.assigns.dragging do
      direction = String.to_atom(direction)
      
      case Game.rotate_piece(socket.assigns.game_state, direction) do
        {:ok, new_state} ->
          socket = socket
          |> assign(:game_state, new_state)
          |> assign(:valid_positions, Game.valid_positions(new_state))
          
          {:noreply, socket}
          
        {:error, _} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  defp handle_specific_event("flip_piece", %{"direction" => direction}, socket) do
    if socket.assigns.dragging do
      direction = String.to_atom(direction)
      
      case Game.flip_piece(socket.assigns.game_state, direction) do
        {:ok, new_state} ->
          socket = socket
          |> assign(:game_state, new_state)
          |> assign(:valid_positions, Game.valid_positions(new_state))
          
          {:noreply, socket}
          
        {:error, _} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  defp handle_specific_event("remove_piece", %{"id" => piece_id}, socket) do
    require Logger
    Logger.info("Remove piece event triggered for: #{piece_id}")
    IO.puts("CONSOLE: Remove piece event triggered for: #{piece_id}")
    IO.inspect(socket.assigns.game_state.placed_pieces, label: "Current placed pieces")
    
    # Check if dragging to prevent accidental removes while placing
    if socket.assigns.dragging do
      Logger.info("Ignoring remove_piece while dragging")
      {:noreply, socket}
    else
      case Game.remove_piece(socket.assigns.game_state, piece_id) do
        {:ok, new_state} ->
          Logger.info("Successfully removed piece: #{piece_id}")
          IO.puts("CONSOLE: Successfully removed piece: #{piece_id}")
          IO.inspect(new_state.placed_pieces, label: "New placed pieces after removal")
          
          socket = socket
          |> assign(:game_state, new_state)
          |> assign(:game_won, false)
          |> clear_error()
          
          {:noreply, socket}
          
        {:error, reason} ->
          Logger.error("Failed to remove piece: #{piece_id}, reason: #{inspect(reason)}")
          IO.puts("CONSOLE: Failed to remove piece: #{piece_id}, reason: #{inspect(reason)}")
          {:noreply, put_error(socket, "无法移除方块")}
      end
    end
  end

  defp handle_specific_event("undo", _, socket) do
    case Game.undo(socket.assigns.game_state) do
      {:ok, new_state} ->
        socket = socket
        |> assign(:game_state, new_state)
        |> assign(:game_won, Game.is_complete?(new_state))
        |> clear_error()
        
        {:noreply, socket}
        
      {:error, _} ->
        {:noreply, socket}
    end
  end

  defp handle_specific_event("reset", _, socket) do
    new_state = Game.reset_game(socket.assigns.game_state)
    
    socket = socket
    |> assign(:game_state, new_state)
    |> assign(:dragging, false)
    |> assign(:ghost_position, nil)
    |> assign(:valid_positions, [])
    |> assign(:game_won, false)
    |> put_flash(:info, "游戏已重置")
    
    {:noreply, socket}
  end

  defp handle_specific_event("new_game", _, socket) do
    {:noreply, push_navigate(socket, to: "/")}
  end

  defp handle_specific_event("handle_keydown", %{"key" => key} = params, socket) do
    socket = handle_keyboard(key, params, socket)
    {:noreply, socket}
  end

  defp handle_specific_event("show_help", _, socket) do
    {:noreply, assign(socket, :show_help, true)}
  end

  defp handle_specific_event("close_help", _, socket) do
    {:noreply, assign(socket, :show_help, false)}
  end

  # Touch events for mobile
  defp handle_specific_event("touch_start", params, socket) do
    handle_specific_event("select_piece", params, socket)
  end

  defp handle_specific_event("touch_move", params, socket) do
    handle_specific_event("mouse_move", params, socket)
  end

  defp handle_specific_event("touch_end", params, socket) do
    handle_specific_event("drop_piece", params, socket)
  end

  @impl true
  def handle_info(:auto_save, socket) do
    save_game_state(socket.assigns.game_state)
    socket = assign(socket, :last_saved, DateTime.utc_now())
    {:noreply, socket}
  end

  def handle_info({:update_game_state, new_state}, socket) do
    # For testing
    socket = socket
    |> assign(:game_state, new_state)
    |> check_win_condition()
    
    {:noreply, socket}
  end

  def handle_info({:set_game_won, true}, socket) do
    # For testing - directly set game won
    {:noreply, assign(socket, :game_won, true)}
  end

  # Private functions

  defp load_or_create_game(session) do
    case session["game_state"] do
      nil -> Game.new_game()
      saved_state ->
        case Game.load_game(saved_state) do
          {:ok, state} -> state
          _ -> Game.new_game()
        end
    end
  end

  defp save_game_state(game_state) do
    # In a real app, would save to database or session
    # For now, just log
    IO.inspect(Game.save_game(game_state), label: "Saving game state")
  end

  defp pixel_to_grid({pixel_x, pixel_y}, cell_size) do
    # Handle negative coordinates correctly
    x = if pixel_x < 0 do
      div(pixel_x - cell_size + 1, cell_size)
    else
      div(pixel_x, cell_size)
    end
    
    y = if pixel_y < 0 do
      div(pixel_y - cell_size + 1, cell_size)
    else
      div(pixel_y, cell_size)
    end
    
    {x, y}
  end
  
  defp center_piece_for_preview(shape) do
    # 计算方块的边界
    {min_x, max_x} = shape |> Enum.map(&elem(&1, 0)) |> Enum.min_max()
    {min_y, max_y} = shape |> Enum.map(&elem(&1, 1)) |> Enum.min_max()
    
    # 计算方块尺寸
    width = (max_x - min_x + 1) * 10
    height = (max_y - min_y + 1) * 10
    
    # 居中在 60x60 的视图框中
    translate_x = (60 - width) / 2 - min_x * 10
    translate_y = (60 - height) / 2 - min_y * 10
    
    "translate(#{translate_x}, #{translate_y})"
  end

  defp get_used_pieces(game_state) do
    game_state.placed_pieces
    |> Enum.map(& &1.id)
    |> MapSet.new()
  end

  defp can_undo?(game_state) do
    not Enum.empty?(game_state.history)
  end

  defp check_win_condition(socket) do
    if Game.is_complete?(socket.assigns.game_state) do
      assign(socket, :game_won, true)
    else
      socket
    end
  end

  defp handle_keyboard("r", _, socket) when socket.assigns.dragging do
    case Game.rotate_piece(socket.assigns.game_state, :clockwise) do
      {:ok, new_state} ->
        socket
        |> assign(:game_state, new_state)
        |> assign(:valid_positions, Game.valid_positions(new_state))
      {:error, _} ->
        socket
    end
  end

  defp handle_keyboard("R", _, socket) when socket.assigns.dragging do
    case Game.rotate_piece(socket.assigns.game_state, :counter_clockwise) do
      {:ok, new_state} ->
        socket
        |> assign(:game_state, new_state)
        |> assign(:valid_positions, Game.valid_positions(new_state))
      {:error, _} ->
        socket
    end
  end

  defp handle_keyboard("f", _, socket) when socket.assigns.dragging do
    case Game.flip_piece(socket.assigns.game_state, :horizontal) do
      {:ok, new_state} ->
        socket
        |> assign(:game_state, new_state)
        |> assign(:valid_positions, Game.valid_positions(new_state))
      {:error, _} ->
        socket
    end
  end

  defp handle_keyboard("F", _, socket) when socket.assigns.dragging do
    case Game.flip_piece(socket.assigns.game_state, :vertical) do
      {:ok, new_state} ->
        socket
        |> assign(:game_state, new_state)
        |> assign(:valid_positions, Game.valid_positions(new_state))
      {:error, _} ->
        socket
    end
  end

  defp handle_keyboard("Escape", _, socket) do
    socket
    |> assign(:game_state, %{socket.assigns.game_state | current_piece: nil})
    |> assign(:dragging, false)
    |> assign(:ghost_position, nil)
    |> assign(:valid_positions, [])
  end

  defp handle_keyboard("z", %{"ctrlKey" => true}, socket) do
    case Game.undo(socket.assigns.game_state) do
      {:ok, new_state} ->
        socket
        |> assign(:game_state, new_state)
        |> assign(:game_won, Game.is_complete?(new_state))
        |> clear_error()
      {:error, _} ->
        socket
    end
  end

  defp handle_keyboard(_, _, socket), do: socket

  defp put_error(socket, message) do
    assign(socket, :error_message, message)
  end

  defp clear_error(socket) do
    assign(socket, :error_message, nil)
  end

  defp format_time(datetime) do
    Calendar.strftime(datetime, "%H:%M:%S")
  end

  defp extract_svg_coordinates(params) do
    # Phoenix LiveView provides offsetX and offsetY for mouse events
    x = params["offsetX"] || params["clientX"] || 0
    y = params["offsetY"] || params["clientY"] || 0
    {x, y}
  end

  defp get_cell_size do
    # 默认使用更大的单元格尺寸，适合移动设备
    40
  end
end