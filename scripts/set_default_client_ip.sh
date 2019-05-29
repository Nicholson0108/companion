#!/bin/sh

# 设置默认的客户端ip，将ip=${1}添加到cmdline.txt文件末尾并拷贝到/boot/cmdline.txt

# Copy default cmdline to temp
cp /home/pi/companion/tools/cmdline.txt /tmp/
# Add ip in the end of cmdline
echo "ip=${1}" >> /tmp/cmdline.txt
# Cat everything to make sure
cat /tmp/cmdline.txt
# Change owner
# 递归的改变文件和子文件权限所有组：所有者
sudo chown -R root:root /tmp/cmdline.txt
# Move it to /boot
sudo mv /tmp/cmdline.txt /boot/cmdline.txt