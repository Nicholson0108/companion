#!/bin/bash

# 安装mavlink和MAVProxy，校验github密钥
# 安装pynmea2，grequests
# 拷贝默认参数，设置默认密码人companion
# 当使用raspberry pi camera时要安装bcm v412驱动
# 将本地companion设为远程仓库
# 输出信息，关闭更新锁

cd /home/pi/companion

# https://git-scm.com/docs/git-submodule#git-submodule-status--cached--recursive--ltpathgt82308203

# Remove old mavlink directory if it exists
# 使用setup.sh安装时，会在companion下克隆有mavlink目录，如果存在，将他删除
[ -d ~/mavlink ] && sudo rm -rf ~/mavlink
echo 'Installing mavlink...'
# 使用pymavlink中的setup.py安装mavlink
cd /home/pi/companion/submodules/mavlink/pymavlink
sudo python setup.py build install

#$? 是显示最后命令的退出状态，0表示没有错误，其他表示有错误
if [ $? -ne 0 ] # If mavlink installation update failed:重启
then
    echo 'Failed to install mavlink; Aborting update'
    echo 'Rebooting to repair installation, this will take a few minutes'
    echo 'Please DO NOT REMOVE POWER FROM THE ROV! (until QGC makes a connection again)'
    sleep 0.1
    sudo reboot
fi

cd /home/pi/companion

echo 'Installing MAVProxy...'
cd /home/pi/companion/submodules/MAVProxy
sudo python setup.py build install
if [ $? -ne 0 ] # If MAVProxy installation update failed:重启
then
    echo 'Failed to install MAVProxy; Aborting update'
    echo 'Rebooting to repair installation, this will take a few minutes'
    echo 'Please DO NOT REMOVE POWER FROM THE ROV! (until QGC makes a connection again)'
    sleep 0.1
    sudo reboot
fi


echo 'checking for github in known_hosts'

# Check for github key in known_hosts
#  -F hostname 用于查找散列过的主机名/ip地址，还可以和-H选项联用打印找到的公钥的散列值。
if ! ssh-keygen -H -F github.com; then
    mkdir ~/.ssh

    # Get gihub public key
    ssh-keyscan -t rsa -H github.com > /tmp/githost

    # Verify fingerprint
    if ssh-keygen -lf /tmp/githost | grep -q 16:27:ac:a5:76:28:2d:36:63:1b:56:4d:eb:df:a6:48; then
        # Add to known_hosts
        cat /tmp/githost >> ~/.ssh/known_hosts
    fi
fi

# install pynmea2 if neccessary
if pip list | grep pynmea2; then
    echo 'pynmea2 already installed'
else
    echo 'installing pynmea2...'
    sudo pip install --no-index --find-links /home/pi/update-dependencies/pynmea2-pip pynmea2
    if [ $? -ne 0 ] # If "pip install pynmea2" failed:
    then
        echo 'Failed to install pynmea2; Aborting update'
        echo 'Rebooting to repair installation, this will take a few minutes'
        echo 'Please DO NOT REMOVE POWER FROM THE ROV! (until QGC makes a connection again)'
        sleep 0.1
        sudo reboot
    fi
fi

# install grequests if neccessary
if pip list | grep grequests; then
    echo 'grequests already installed'
else
    echo 'grequests needs install'
    echo 'Extracting prebuilt packages...'
    sudo unzip -q -o /home/pi/update-dependencies/grequests.zip -d /
    echo 'installing grequests...'
    sudo pip install --no-index --find-links /home/pi/update-dependencies/grequests-pip grequests
    if [ $? -ne 0 ] # If "pip install grequests" failed:
    then
        echo 'Failed to install grequests; Aborting update'
        echo 'Rebooting to repair installation, this will take a few minutes'
        echo 'Please DO NOT REMOVE POWER FROM THE ROV! (until QGC makes a connection again)'
        sleep 0.1
        sudo reboot
    fi
fi

# copy default parameters if neccessary，并删除末尾.default
cd /home/pi/companion/params

for default_param_file in *; do
    if [[ $default_param_file == *".param.default" ]]; then
        param_file="/home/pi/"$(echo $default_param_file | sed "s/.default//")
        if [ ! -e "$param_file" ]; then
            cp $default_param_file $param_file
        fi
    fi
done

# 设置默认密码companion
echo "changing default password to 'companion'..."
echo "pi:companion" | sudo chpasswd

# We need to load bcm v4l2 driver in case Raspberry Pi camera is in use
echo "restarting video stream"
~/companion/scripts/start_video.sh $(cat ~/companion/params/vidformat.param.default)

# add local repo as a remote so it will show up in webui
# 在本地添加仓库作为远端，使得可以在webui中显示
cd ~/companion
# 如果remote中没有local
if ! git remote | grep -q local; then
    echo 'Adding local reference'
	# 添加新的远程仓库关联git remote add <name> <url>
    git remote add local ~/companion
fi

rm -rf /home/pi/update-dependencies

echo 'Update Complete, refresh your browser'

sleep 0.1

echo 'quit webui' >> /home/pi/.update_log
screen -X -S webui quit

echo 'restart webui' >> /home/pi/.update_log
sudo -H -u pi screen -dm -S webui /home/pi/companion/scripts/start_webui.sh

echo 'removing lock' >> /home/pi/.update_log
rm -f /home/pi/.updating
