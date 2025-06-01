#!/usr/bin/env elixir

# 调试脚本：检查LiveView渲染
# 运行: elixir debug_live.exs

IO.puts("请在浏览器控制台运行以下JavaScript代码来调试：")
IO.puts("")
IO.puts(~S"""
// 1. 检查当前是否有选中的拼图块
const dragging = document.querySelector('.valid-positions-layer');
console.log('是否处于选中状态:', dragging ? '是' : '否');

// 2. 检查所有rect元素
const allRects = document.querySelectorAll('svg rect');
console.log('总共rect元素数量:', allRects.length);

// 3. 检查有phx-click属性的rect
const clickableRects = document.querySelectorAll('rect[phx-click]');
console.log('有phx-click属性的rect数量:', clickableRects.length);

// 4. 检查第一个格子的所有属性
const firstRect = document.querySelector('.grid-cell');
if (firstRect) {
  console.log('第一个格子的属性:');
  console.log('- class:', firstRect.getAttribute('class'));
  console.log('- phx-click:', firstRect.getAttribute('phx-click'));
  console.log('- phx-value-x:', firstRect.getAttribute('phx-value-x'));
  console.log('- phx-value-y:', firstRect.getAttribute('phx-value-y'));
  console.log('- 完整HTML:', firstRect.outerHTML);
}

// 5. 检查Phoenix LiveView是否正常工作
console.log('LiveSocket是否连接:', window.liveSocket && window.liveSocket.isConnected());

// 6. 尝试手动触发事件
if (clickableRects.length > 0) {
  console.log('尝试点击第一个可点击格子...');
  const rect = clickableRects[0];
  console.log('要点击的格子:', rect.outerHTML);
  
  // 创建并触发点击事件
  const event = new MouseEvent('click', {
    view: window,
    bubbles: true,
    cancelable: true
  });
  rect.dispatchEvent(event);
}

// 7. 检查是否有错误
window.addEventListener('phx:error', (e) => {
  console.error('Phoenix错误:', e.detail);
});
""")