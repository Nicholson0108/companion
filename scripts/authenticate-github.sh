#!/bin/bash

# 接受两个命令行参数，$1=USERNAME，$2=PASSWORD
# 修改密语，并将公钥上传给github服务器https://api.github.com/user/keys

USERNAME=$1
PASSWORD=$2

# 如果~/.ssh/id_rsa存在
if [ ! -e ~/.ssh/id_rsa ]; then
  echo 'Generating new ssh key'
  # ssh-keygen - 生成、管理和转换认证密钥 -f filename指定密钥文件名
  # -q 安静模式。用于在 /etc/rc 中创建新密钥的时候  -N 提供一个新的密语，这里是""。
  ssh-keygen -f ~/.ssh/id_rsa -q -N ""
fi

echo 'Registering key with ssh-agent'
# ssh-add把专用密钥添加到ssh-agent的高速缓存中。
ssh-add ~/.ssh/id_rsa

# spit out the public key and form JSON request
# 准备将公钥上传github服务器
PUBKEY=$(cat ~/.ssh/id_rsa.pub)
PAYLOAD='{"title":"companion-access","key":"'$PUBKEY'"}'

#echo 'Authenticating github with new key'
RESPONSE=$(curl -u "$USERNAME:$PASSWORD" --data "$PAYLOAD" https://api.github.com/user/keys)

exit $(echo $RESPONSE | grep -q '"verified": true')
