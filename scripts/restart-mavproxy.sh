#!/bin/bash

# 重启mavproxy

screen -X -S mavproxy quit
sudo -H -u pi screen -dm -S mavproxy \
    $COMPANION_DIR/scripts/start_mavproxy_telem_splitter.sh
