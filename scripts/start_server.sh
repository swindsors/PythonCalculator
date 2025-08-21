#!/bin/bash
cd /home/ec2-user/streamlit-calculator

# Install Python dependencies
pip3 install --user -r requirements.txt

# Kill any existing Streamlit processes
pkill -f streamlit

# Start Streamlit in the background
nohup python3 -m streamlit run calculator.py --server.port=8501 --server.address=0.0.0.0 > /home/ec2-user/streamlit.log 2>&1 &

# Wait a moment for the server to start
sleep 5

# Check if the server is running
if pgrep -f streamlit > /dev/null; then
    echo "Streamlit server started successfully"
    exit 0
else
    echo "Failed to start Streamlit server"
    exit 1
fi
