#!/bin/bash
echo "Starting to build ORB-SLAM3 ROS2 wrapper..."
# rm -rf /root/colcon_ws/build/ /root/colcon_ws/install/ /root/colcon_ws/logs/
cd /home/orb/ORB_SLAM3/ && sudo chmod +x build.sh && ./build.sh
cd /root/colcon_ws/ && colcon build --symlink-install && source install/setup.bash
echo "ORB-SLAM3 ROS2 wrapper build completed successfully."