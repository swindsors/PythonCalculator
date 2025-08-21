#!/bin/bash

# Kill any existing Streamlit processes
pkill -f streamlit

# Wait a moment for processes to terminate
sleep 2

# Check if any Streamlit processes are still running
if pgrep -f streamlit > /dev/null; then
    echo "Warning: Some Streamlit processes may still be running"
    # Force kill if necessary
    pkill -9 -f streamlit
    sleep 1
fi

if ! pgrep -f streamlit > /dev/null; then
    echo "Streamlit server stopped successfully"
    exit 0
else
    echo "Failed to stop Streamlit server"
    exit 1
fi
