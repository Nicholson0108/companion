#!/bin/bash

# 启动webui，设置ssh代理，并将输出写入.webui.log

export COMPANION_DIR=/home/pi/companion

cd $COMPANION_DIR/br-webui/

# limit logfile size to 10k lines把日志长度现在在10000行以内
tail -n 10000 /home/pi/.webui.log > /tmp/.webui.log
cp /tmp/.webui.log /home/pi/.webui.log
rm -f /tmp/.webui.log

# start ssh-agent for git/ssh authentication
# 启动代理并添加密钥
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa

# start webserver
# 标准错误重定向到标准输出并追加到/.webui.log
node index.js 2>&1 | tee -a /home/pi/.webui.log
