#!/bin/bash
cd /home/wangbo/document/pento
export MIX_ENV=dev
nohup mix phx.server > server.log 2>&1 &
echo $! > server.pid
echo "Phoenix server started with PID: $(cat server.pid)"
echo "Log file: /home/wangbo/document/pento/server.log"