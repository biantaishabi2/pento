#!/usr/bin/env elixir

# 调试脚本：测试组件渲染
# 运行: elixir debug_render.exs

defmodule DebugRender do
  def test_conditional_attribute do
    IO.puts("\n=== 测试条件属性渲染 ===\n")
    
    # 测试不同的条件渲染方式
    dragging_true = true
    dragging_false = false
    dragging_nil = nil
    
    # 方式1：当前的实现
    IO.puts("1. 当前实现：phx-click={if @dragging, do: \"drop_at_cell\"}")
    IO.puts("   dragging=true:  #{inspect(if dragging_true, do: "drop_at_cell")}")
    IO.puts("   dragging=false: #{inspect(if dragging_false, do: "drop_at_cell")}")
    IO.puts("   dragging=nil:   #{inspect(if dragging_nil, do: "drop_at_cell")}")
    
    # 方式2：更明确的实现
    IO.puts("\n2. 明确实现：phx-click={if @dragging == true, do: \"drop_at_cell\", else: nil}")
    IO.puts("   dragging=true:  #{inspect(if dragging_true == true, do: "drop_at_cell", else: nil)}")
    IO.puts("   dragging=false: #{inspect(if dragging_false == true, do: "drop_at_cell", else: nil)}")
    IO.puts("   dragging=nil:   #{inspect(if dragging_nil == true, do: "drop_at_cell", else: nil)}")
    
    # 方式3：使用 && 操作符
    IO.puts("\n3. 使用 &&：phx-click={@dragging && \"drop_at_cell\"}")
    IO.puts("   dragging=true:  #{inspect(dragging_true && "drop_at_cell")}")
    IO.puts("   dragging=false: #{inspect(dragging_false && "drop_at_cell")}")
    IO.puts("   dragging=nil:   #{inspect(dragging_nil && "drop_at_cell")}")
    
    # 测试 HEEx 模板引擎的处理
    IO.puts("\n4. HEEx 属性处理：")
    IO.puts("   当属性值为 nil 时，HEEx 不会渲染该属性")
    IO.puts("   当属性值为 false 时，HEEx 也不会渲染该属性")
    IO.puts("   只有当属性值为字符串时，HEEx 才会渲染该属性")
  end
end

DebugRender.test_conditional_attribute()