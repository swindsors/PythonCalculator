#!/bin/bash
set -e  # Exit on any error

echo "Stopping Streamlit application..."

# Kill any existing Streamlit processes (don't fail if none exist)
pkill -f streamlit || true

# Wait a moment for processes to terminate
sleep 3

# Check if any Streamlit processes are still running
if pgrep -f streamlit > /dev/null; then
    echo "Warning: Some Streamlit processes still running, force killing..."
    # Force kill if necessary
    pkill -9 -f streamlit || true
    sleep 2
fi

# Final check - don't fail deployment if no processes were running
if ! pgrep -f streamlit > /dev/null; then
    echo "Streamlit server stopped successfully"
else
    echo "Warning: Some Streamlit processes may still be running, but continuing deployment"
fi

exit 0  # Always succeed to prevent deployment failure
