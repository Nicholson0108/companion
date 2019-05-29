#!/bin/bash

# 备份现有仓库，并用$1提供的归档替换现有仓库
# 调用/scripts/post-sideload.sh

cd /home/pi/companion

#验证归档（压缩文件）
echo 'validating archive'
# 解压缩归档，检查是否存在 companion/.git文件
# -l 显示压缩文件内所包含的文件 -q 不显示任何信息
# $1是归档文件
if unzip -l $1 | grep -q companion/.git; then
    echo 'archive validated ok'
else
    echo 'Archive does not look like a companion update!'
    exit 1
fi

# 设置更新锁
echo 'adding lock'
touch /home/pi/.updating

# 删除旧的备份仓库
echo 'removing old backup'
rm -rf /home/pi/.companion

# 备份现有仓库
echo 'backing up repository'
mv /home/pi/companion /home/pi/.companion

# 提取归档（压缩文件）
echo 'extracting archive: ' $1
unzip -q $1 -d /home/pi

# 调用/scripts/post-sideload.sh
echo 'running post-sideload.sh'
/home/pi/companion/scripts/post-sideload.sh
