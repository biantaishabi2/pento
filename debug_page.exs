#!/usr/bin/env elixir

# 调试脚本：检查当前页面状态
# 运行: elixir debug_page.exs

IO.puts("请在浏览器的开发者控制台中运行以下 JavaScript 代码：")
IO.puts("")
IO.puts(~S"""
// 检查拖拽状态
console.log("=== 游戏状态调试 ===");

// 1. 检查是否有选中的拼图块
const draggingIndicator = document.querySelector('.valid-positions-layer');
console.log("是否处于拖拽状态:", draggingIndicator ? "是" : "否");

// 2. 检查格子是否有点击事件
const gridCells = document.querySelectorAll('.grid-cell');
console.log("格子总数:", gridCells.length);

// 3. 检查有多少格子有 phx-click 属性
const clickableCells = document.querySelectorAll('.grid-cell[phx-click]');
console.log("可点击的格子数:", clickableCells.length);

// 4. 检查第一个格子的属性
if (gridCells.length > 0) {
  console.log("第一个格子的属性:");
  console.log("- phx-click:", gridCells[0].getAttribute('phx-click'));
  console.log("- phx-value-x:", gridCells[0].getAttribute('phx-value-x'));
  console.log("- phx-value-y:", gridCells[0].getAttribute('phx-value-y'));
}

// 5. 检查是否有绿色高亮
const validPositions = document.querySelectorAll('.valid-position');
console.log("绿色高亮格子数:", validPositions.length);

// 6. 尝试手动触发点击事件
if (clickableCells.length > 0) {
  console.log("尝试点击第一个可点击格子...");
  clickableCells[0].click();
} else if (gridCells.length > 0) {
  console.log("没有可点击格子，尝试点击第一个普通格子...");
  gridCells[0].click();
}
""")

IO.puts("")
IO.puts("复制上面的代码到浏览器控制台运行，然后告诉我输出结果。")