#!/bin/bash

echo "🛑 Stopping all servers..."

# Kill all node processes related to our servers
echo "🔄 Finding Node.js processes..."
node_processes=$(ps aux | grep "node.*server.js" | grep -v grep | awk '{print $2}')

if [ ! -z "$node_processes" ]; then
    echo "🗑️  Stopping Node.js server processes: $node_processes"
    echo $node_processes | xargs kill -9
    sleep 2
else
    echo "ℹ️  No Node.js server processes found"
fi

# Also check specific ports
echo "🔄 Checking port 3000..."
pids_3000=$(lsof -ti:3000 2>/dev/null)
if [ ! -z "$pids_3000" ]; then
    echo "🗑️  Killing processes on port 3000: $pids_3000"
    kill -9 $pids_3000
fi

echo "🔄 Checking port 4000..."
pids_4000=$(lsof -ti:4000 2>/dev/null)
if [ ! -z "$pids_4000" ]; then
    echo "🗑️  Killing processes on port 4000: $pids_4000"
    kill -9 $pids_4000
fi

echo "✅ All servers stopped!"
echo "💡 You can now run ./start-clean.sh to restart them" 