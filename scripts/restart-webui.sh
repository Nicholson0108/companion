#!/bin/bash

# 重启webui

screen -X -S webui quit
/home/pi/companion/scripts/start_webui.sh