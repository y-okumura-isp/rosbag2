#!/bin/bash

# setting (change me. Values are example)
FOXY_PATH=/home/rosuser/src/ros2_foxy
ROLLING_PATH=/home/rosuser/src/ros2_rolling

# unset local_setup.bash environment variables
unset AMENT_PREFIX_PATH
unset CMAKE_PREFIX_PATH
unset COLCON_PREFIX_PATH
unset LD_LIBRARY_PATH
unset PATH
unset PKG_CONFIG_PATH
unset PYTHONPATH

_term() {
  echo "Caught SIGTERM signal!"
  kill -TERM "$child" 2>/dev/null
  exit 2
}

_kill() {
  echo "Caught SIGKILL signal!"
  kill -KILL "$child" 2>/dev/null
  exit 2
}

_interup() {
  echo "Caught SIGINT signal!"
  kill -INT "$child" 2>/dev/null
  exit 2
}

trap _term SIGTERM
trap _kill SIGKILL
trap _interup SIGINT

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/ros/foxy/lib/x86_64-linux-gnu/

## Foxyg
cd ${FOXY_PATH}
. install/local_setup.bash
cd ${ROLLING_PATH}
echo "run foxy record: ros2 bag record -a $@"
ros2 bag record -a $@ &

## Rolling
# cd ${ROLLING_PATH}
# . install/local_setup.bash
# echo "run rolling record: ros2 bag record -a $@"
# ros2 bag record -a $@ &



child=$!
wait "$child"

