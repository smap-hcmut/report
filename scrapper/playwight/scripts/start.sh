#!/bin/bash

set -e

# Function to cleanup on exit
cleanup() {
    echo "Cleaning up processes..."
    if [ ! -z "$XVFB_PID" ] && kill -0 $XVFB_PID 2>/dev/null; then
        kill $XVFB_PID
    fi
    if [ ! -z "$DBUS_PID" ] && kill -0 $DBUS_PID 2>/dev/null; then
        kill $DBUS_PID
    fi
}

trap cleanup EXIT

# Clean up stale X11 lock files (prevents "display already active" errors)
rm -f /tmp/.X99-lock /tmp/.X11-unix/X99

# Start dbus daemon (required for some Chromium features)
# Use session bus instead of system bus for non-root user
echo "Starting D-Bus session..."
export DBUS_SESSION_BUS_ADDRESS="unix:path=/tmp/dbus-session"
dbus-daemon --session --address="$DBUS_SESSION_BUS_ADDRESS" --nofork --nopidfile --syslog-only &
DBUS_PID=$!
sleep 2

# Start Xvfb (Virtual Framebuffer for headless GUI applications)
export DISPLAY=:99
echo "Starting Xvfb on DISPLAY=:99..."
Xvfb :99 -screen 0 1920x1080x24 -ac +extension GLX +render -noreset &
XVFB_PID=$!

# Wait for Xvfb to be ready
sleep 5

# Verify Xvfb is running
if ! pgrep -x "Xvfb" > /dev/null; then
    echo "ERROR: Xvfb failed to start"
    exit 1
fi

echo "Xvfb started successfully (PID: $XVFB_PID)"

# Start Node.js Playwright Server in background
echo "Starting Playwright WebSocket server on port 4444..."
node node_modules/playwright-core/cli.js run-server --host 0.0.0.0 --port 4444 2>&1 &

# Start Python FastAPI Service
echo "Starting Playwright REST API on port 8001..."
python cmd/api/main.py
