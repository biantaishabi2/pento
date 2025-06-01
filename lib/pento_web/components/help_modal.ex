defmodule PentoWeb.Components.HelpModal do
  use Phoenix.Component

  @doc """
  游戏帮助模态框组件
  """
  attr :show, :boolean, default: false

  def help_modal(assigns) do
    ~H"""
    <div 
      :if={@show}
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
      phx-click="close_help"
    >
      <div 
        class="bg-white rounded-lg shadow-xl p-6 max-w-2xl max-h-[90vh] overflow-y-auto m-4"
        phx-click-away="close_help"
      >
        <div class="flex justify-between items-center mb-4">
          <h2 class="text-2xl font-bold text-gray-800">游戏说明</h2>
          <button
            phx-click="close_help"
            class="text-gray-500 hover:text-gray-700"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
            </svg>
          </button>
        </div>

        <div class="space-y-6">
          <!-- 游戏简介 -->
          <section>
            <h3 class="text-lg font-semibold text-gray-700 mb-2">🎮 游戏简介</h3>
            <p class="text-gray-600">
              Pentomino（五格骨牌）是一个经典的拼图游戏。游戏包含12个不同形状的方块，
              每个方块由5个小方格组成。您的目标是将所有方块放置到棋盘上，填满整个游戏区域。
            </p>
          </section>

          <!-- 操作说明 -->
          <section>
            <h3 class="text-lg font-semibold text-gray-700 mb-2">🖱️ 操作说明</h3>
            <div class="space-y-3">
              <div class="flex items-start">
                <span class="text-blue-500 mr-2">•</span>
                <div>
                  <strong>选择方块：</strong>点击左侧调色板中的方块
                </div>
              </div>
              <div class="flex items-start">
                <span class="text-blue-500 mr-2">•</span>
                <div>
                  <strong>放置方块：</strong>拖动到棋盘上的绿色高亮位置，然后释放鼠标
                </div>
              </div>
              <div class="flex items-start">
                <span class="text-blue-500 mr-2">•</span>
                <div>
                  <strong>移除方块：</strong>点击已放置的方块即可移除
                </div>
              </div>
            </div>
          </section>

          <!-- 键盘快捷键 -->
          <section>
            <h3 class="text-lg font-semibold text-gray-700 mb-2">⌨️ 键盘快捷键</h3>
            <div class="grid grid-cols-2 gap-4">
              <div class="bg-gray-50 p-3 rounded">
                <kbd class="px-2 py-1 text-sm font-semibold text-gray-800 bg-gray-200 rounded">R</kbd>
                <span class="ml-2 text-gray-600">顺时针旋转</span>
              </div>
              <div class="bg-gray-50 p-3 rounded">
                <kbd class="px-2 py-1 text-sm font-semibold text-gray-800 bg-gray-200 rounded">Shift + R</kbd>
                <span class="ml-2 text-gray-600">逆时针旋转</span>
              </div>
              <div class="bg-gray-50 p-3 rounded">
                <kbd class="px-2 py-1 text-sm font-semibold text-gray-800 bg-gray-200 rounded">F</kbd>
                <span class="ml-2 text-gray-600">水平翻转</span>
              </div>
              <div class="bg-gray-50 p-3 rounded">
                <kbd class="px-2 py-1 text-sm font-semibold text-gray-800 bg-gray-200 rounded">Shift + F</kbd>
                <span class="ml-2 text-gray-600">垂直翻转</span>
              </div>
              <div class="bg-gray-50 p-3 rounded">
                <kbd class="px-2 py-1 text-sm font-semibold text-gray-800 bg-gray-200 rounded">Esc</kbd>
                <span class="ml-2 text-gray-600">取消当前操作</span>
              </div>
              <div class="bg-gray-50 p-3 rounded">
                <kbd class="px-2 py-1 text-sm font-semibold text-gray-800 bg-gray-200 rounded">Ctrl + Z</kbd>
                <span class="ml-2 text-gray-600">撤销上一步</span>
              </div>
            </div>
          </section>

          <!-- 游戏提示 -->
          <section>
            <h3 class="text-lg font-semibold text-gray-700 mb-2">💡 游戏提示</h3>
            <ul class="space-y-2 text-gray-600">
              <li class="flex items-start">
                <span class="text-green-500 mr-2">✓</span>
                <span>绿色高亮显示可以放置方块的位置</span>
              </li>
              <li class="flex items-start">
                <span class="text-green-500 mr-2">✓</span>
                <span>半透明预览显示方块将要放置的位置</span>
              </li>
              <li class="flex items-start">
                <span class="text-green-500 mr-2">✓</span>
                <span>红色预览表示该位置无法放置（超出边界或重叠）</span>
              </li>
              <li class="flex items-start">
                <span class="text-green-500 mr-2">✓</span>
                <span>从角落开始放置通常更容易</span>
              </li>
              <li class="flex items-start">
                <span class="text-green-500 mr-2">✓</span>
                <span>先放置形状独特的方块（如I、L、T）</span>
              </li>
            </ul>
          </section>

          <!-- 方块介绍 -->
          <section>
            <h3 class="text-lg font-semibold text-gray-700 mb-2">🧩 方块种类</h3>
            <p class="text-gray-600 mb-3">
              游戏包含12种不同形状的方块，每个都由5个小方格组成，以字母命名：
            </p>
            <div class="grid grid-cols-6 gap-2 text-center">
              <div class="p-2 bg-gray-50 rounded">
                <div class="font-bold text-lg" style="color: #FF6B6B">F</div>
              </div>
              <div class="p-2 bg-gray-50 rounded">
                <div class="font-bold text-lg" style="color: #4ECDC4">I</div>
              </div>
              <div class="p-2 bg-gray-50 rounded">
                <div class="font-bold text-lg" style="color: #45B7D1">L</div>
              </div>
              <div class="p-2 bg-gray-50 rounded">
                <div class="font-bold text-lg" style="color: #96CEB4">N</div>
              </div>
              <div class="p-2 bg-gray-50 rounded">
                <div class="font-bold text-lg" style="color: #FFEAA7">P</div>
              </div>
              <div class="p-2 bg-gray-50 rounded">
                <div class="font-bold text-lg" style="color: #DDA0DD">T</div>
              </div>
              <div class="p-2 bg-gray-50 rounded">
                <div class="font-bold text-lg" style="color: #F8B500">U</div>
              </div>
              <div class="p-2 bg-gray-50 rounded">
                <div class="font-bold text-lg" style="color: #6C5CE7">V</div>
              </div>
              <div class="p-2 bg-gray-50 rounded">
                <div class="font-bold text-lg" style="color: #A8E6CF">W</div>
              </div>
              <div class="p-2 bg-gray-50 rounded">
                <div class="font-bold text-lg" style="color: #FF8B94">X</div>
              </div>
              <div class="p-2 bg-gray-50 rounded">
                <div class="font-bold text-lg" style="color: #C7CEEA">Y</div>
              </div>
              <div class="p-2 bg-gray-50 rounded">
                <div class="font-bold text-lg" style="color: #FFDAC1">Z</div>
              </div>
            </div>
          </section>

          <!-- 触屏支持 -->
          <section>
            <h3 class="text-lg font-semibold text-gray-700 mb-2">📱 触屏操作</h3>
            <p class="text-gray-600">
              游戏支持触屏设备操作：
            </p>
            <ul class="mt-2 space-y-1 text-gray-600">
              <li>• 触摸方块选择</li>
              <li>• 拖动手指移动方块</li>
              <li>• 松开手指放置方块</li>
              <li>• 点击已放置的方块移除</li>
            </ul>
          </section>
        </div>

        <div class="mt-6 pt-4 border-t text-center">
          <button
            phx-click="close_help"
            class="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            开始游戏
          </button>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  帮助按钮组件
  """
  def help_button(assigns) do
    ~H"""
    <button
      phx-click="show_help"
      class="fixed bottom-4 left-4 p-3 bg-blue-600 text-white rounded-full shadow-lg hover:bg-blue-700 transition-all hover:scale-110"
      title="游戏帮助"
    >
      <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
      </svg>
    </button>
    """
  end
end