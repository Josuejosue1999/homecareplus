#!/bin/bash

echo "🧹 Cleaning up ports 3000 and 4000..."

# Kill any processes on port 3000
echo "🔄 Checking port 3000..."
pids_3000=$(lsof -ti:3000 2>/dev/null)
if [ ! -z "$pids_3000" ]; then
    echo "🗑️  Killing processes on port 3000: $pids_3000"
    kill -9 $pids_3000
    sleep 2
else
    echo "✅ Port 3000 is free"
fi

# Kill any processes on port 4000
echo "🔄 Checking port 4000..."
pids_4000=$(lsof -ti:4000 2>/dev/null)
if [ ! -z "$pids_4000" ]; then
    echo "🗑️  Killing processes on port 4000: $pids_4000"
    kill -9 $pids_4000
    sleep 2
else
    echo "✅ Port 4000 is free"
fi

echo "🧹 Cleanup completed!"
echo ""
echo "🚀 Starting main server on port 3000..."
npm start &

sleep 5

echo ""
echo "🏥 Starting admin dashboard on port 4000..."
cd admin-dashboard
npm start &

echo ""
echo "✅ Both servers are starting..."
echo "📱 Main app: http://localhost:3000"
echo "🏥 Admin dashboard: http://localhost:4000"
echo ""
echo "💡 Press Ctrl+C to stop both servers"

# Wait for user interrupt
wait 