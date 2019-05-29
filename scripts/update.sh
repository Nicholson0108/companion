#!/bin/bash

# 做更新前准备，比如备份长裤，切换分支等

REMOTE=$1
REF=$2

echo 'The update process will begin momentarily.'
echo 'This update may take more than 15 minutes.'
echo 'Please be patient and DO NOT REMOVE POWER FROM THE ROV!'

sleep 10

echo 'adding lock'
touch /home/pi/.updating

# 有$4参数时跳过备份
if [ -z "$4" ]; then
    echo 'skipping backup...'
else
    echo 'removing old backup'
    rm -rf /home/pi/.companion

    echo 'backup current repo'
    cp -r /home/pi/companion /home/pi/.companion
fi

cd /home/pi/companion

echo 'stashing local changes'
# -c <name> = <value> 将配置参数传递给命令。给定的值将覆盖配置文件中的值。
# git stash保存当前工作进度
git -c user.name="companion-update" -c user.email="companion-update" stash

# 标记当前版本
echo 'tagging revert-point as' $(git rev-parse HEAD)
git tag revert-point -f

# 有$3参数有无决定回退到哪一版本分支
if [ -z "$3" ]; then
    echo 'using branch reference'
    git fetch $REMOTE
	# 强制退回到$1/$2分支
    echo 'moving to' $(git rev-parse $REMOTE/$REF)
    git reset --hard $REMOTE/$REF
else
    echo 'using tag reference'
    TAG=$3
    echo 'fetching'
	# 拉取远端所有标签的分支
    git fetch $REMOTE --tags
	# 强制退回到$3分支
    echo 'moving to' $(git rev-parse $TAG)
    git reset --hard $TAG
fi

echo 'running post-update'
/home/pi/companion/scripts/post-update.sh
