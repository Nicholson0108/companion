#!/bin/bash

# RPi2 setup script for use as companion computer. This script is simplified for use with
# the ArduSub code.
cd /home/pi

# Update package lists and current packages 
# 非交互参数 -Y 默认是 -q 输出到日志
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -yq

# Update Raspberry Pi 
# 通过rpi-update软件包一键更新树莓派固件
sudo DEBIAN_FRONTEND=noninteractive apt-get install -yq rpi-update
sudo rpi-update -y

# install python and pip 
# python-dev开发包编译用的 python-pip是python的包管理工具 python-libxml2C语言解析和构造xml文档
sudo apt-get install -y python-dev python-pip python-libxml2

# dependencies 
# libxslt1-dev用来扩展libxml2包使其兼容XSLT文件 future一个异步容器
sudo apt-get install -y libxml2-dev libxslt1-dev

sudo pip install future

# install git
sudo apt-get install -y git

# download and install pymavlink from source in order to have up to date ArduSub support
git clone https://github.com/tjocean-bluerov/mavlink.git /home/pi/mavlink

pushd mavlink
git submodule init && git submodule update --recursive
pushd pymavlink
sudo python setup.py build install
popd
popd

# install MAVLink tools
# mavproxy地面站程序 dronekit在companion上使用的用于控制无人机的API
# 通过MAVLINK与飞控通信 dronekit-sitl开源软件模拟器 这些都是仿真用的
sudo pip install mavproxy dronekit dronekit-sitl # also installs pymavlink

# install screen
# 可以在多个进程间多路复用一个物理终端的窗口管理器，用户可以在一个screen会话中创建多个screen窗口
sudo apt-get install -y screen

# web ui dependencies, separate steps to avoid conflicts
# node和nodejs是让JAVASCRIPT运行在服务器端的开发平台，适用于数据密集的情况下处理实时数据，
# WEB开发 npm是解决NODEJS代码部署的包管理工具
sudo apt-get install -y node
sudo apt-get install -y nodejs-legacy
sudo apt-get install -y npm

# node updater
# -g全局安装 n模块用来管理node.js版本
sudo npm install n -g

# Get recent version of node
sudo n 5.6.0

# browser based terminal
# 基于浏览器的终端模拟器
sudo npm install tty.js -g

# clone bluerobotics companion repository
git clone https://github.com/tjocean-bluerov/companion.git /home/pi/companion

cd $HOME/companion/br-webui

# 安装package.json中标注的依赖包
npm install

# Disable camera LED
# 正则表达式 -i修改读取的文件内容，删除sed -i '\%要选中的文字%d' file.txt
# 在最后一行$插入sed -i '$a\要插入的文字' file.txt
sudo sed -i '\%disable_camera_led=1%d' /boot/config.txt
sudo sed -i '$a disable_camera_led=1' /boot/config.txt

# Enable RPi camera interface
sudo sed -i '\%start_x=%d' /boot/config.txt
sudo sed -i '\%gpu_mem=%d' /boot/config.txt
sudo sed -i '$a start_x=1' /boot/config.txt
sudo sed -i '$a gpu_mem=128' /boot/config.txt

# source startup script
# expand_fs.sh调整文件系统的大小，然后从/etc/rc.local中删除$HOME/companion/scripts/expand_fs.sh，也就是只运行一次
S1="$HOME/companion/scripts/expand_fs.sh"
# .companion.rc负责参数配置，以及运行每次启动时需要运行的一些脚本
S2=". $HOME/companion/.companion.rc"

# this will produce desired result if this script has been run already,
# and commands are already in place
# delete S1 if it already exists
# insert S1 above the first uncommented exit 0 line in the file在第一个未标注的exit 0行前插入S1和S2
# 0,/^[^#]*exit 0/    0，// 0-//行之间 ^锁定开头 []字符组 [^]不包含的字符组 *0个或多个前面的字符
# s%%$S1\n$S2\n&% 取代指令s/old/new/g %作为分隔符 &符号用来替代命令中匹配到的整个字符串，放在末尾也就是在之前插入$S1\n$S2\n
sudo sed -i -e "\%$S1%d" \
-e "\%$S2%d" \
-e "0,/^[^#]*exit 0/s%%$S1\n$S2\n&%" \
/etc/rc.local

# compile and install gstreamer 1.8 from source
if [ "$1" = "gst" ]; then
    $HOME/companion/scripts/setup_gst.sh
fi

sudo reboot now
