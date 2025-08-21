#!/bin/bash
set -e  # Exit on any error

echo "Starting Streamlit application..."

# Change to application directory
cd /home/ec2-user/streamlit-calculator

# Install Python dependencies globally (not --user)
echo "Installing Python dependencies..."
pip3 install -r requirements.txt

# Kill any existing Streamlit processes
echo "Stopping any existing Streamlit processes..."
pkill -f streamlit || true  # Don't fail if no processes found

# Wait a moment for processes to stop
sleep 2

# Start Streamlit in the background
echo "Starting Streamlit server..."
nohup python3 -m streamlit run calculator.py --server.port=8501 --server.address=0.0.0.0 > /home/ec2-user/streamlit.log 2>&1 &

# Wait for the server to start
sleep 10

# Check if the server is running
if pgrep -f streamlit > /dev/null; then
    echo "Streamlit server started successfully"
    echo "Server logs:"
    tail -10 /home/ec2-user/streamlit.log
    exit 0
else
    echo "Failed to start Streamlit server"
    echo "Error logs:"
    cat /home/ec2-user/streamlit.log
    exit 1
fi
