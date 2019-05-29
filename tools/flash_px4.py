#!/usr/bin/python -u

# 获取本地或下载最新飞控固件ArduSub-v2.px4并调用px_uploader.py文件执行

import os
from urllib2 import urlopen
import time
import sys
import signal
from optparse import OptionParser

# 回调函数
def timeout(signum, frame):
    print 'Timed out waiting for firmware on stdin!'
    exit(1)

# 创建实例命令行参数实例
parser = OptionParser()
# 添加参数选项及属性，dest='url' 将该用户输入的参数保存到变量url中，可以通过options.url方式来获取该值
parser.add_option("--url",dest="url",help="Firmware download URL (optional)")
parser.add_option("--stdin",action="store_true",dest="fromStdin",default=False,help="Expect input from stdin")
parser.add_option("--file", dest="file", default=None, help="Load from file")
parser.add_option("--latest",action="store_true",dest="latest",default=False,help="Upload latest development firmware")
# 解析命令行参数，返回一个字典和一个列表
(options,args) = parser.parse_args()

# 当option.fromStdin = true，从标准输入读取px4文件
if options.fromStdin:
                # Get firmware from stdin if possible
                print "Trying to read file from stdin..."
                
				# 收到SIGALRM信号后执行回调函数timeout
                signal.signal(signal.SIGALRM, timeout)
				# 定时器
                signal.alarm(5)
				# sys.stdin标准输入
                fileIn = sys.stdin.read()
                signal.alarm(0)

                if fileIn:
                                file = open("/tmp/ArduSub-v2.px4","w")
                                file.write(fileIn)
                                file.close()
                                print "Got firmware file from stdin!"      
                else:
                                error("Read error on stdin!")
# 当option.fromStdin ！= true
# 当option.file != none，直接加载文件								
elif options.file is not None:
                try:
                    print("Attempting upload from file %s") % options.file
                    open(options.file)
                except Exception as e:
                    print("Error opening file %s: %s") % (options.file, e)
                    exit(1)
else:
                # Download most recent firmware
				# 下载px4文件
                if options.url:
								# %s格式化字符，字符串
                                firmwareURL = options.url
                                print "Downloading ArduSub firmware from %s" % firmwareURL
                elif options.latest:
                                firmwareURL = "http://firmware.ardupilot.org/Sub/latest/PX4/ArduSub-v2.px4"
                                print "Downloading latest ArduSub firmware from %s" % firmwareURL
                else:
                                firmwareURL = "http://firmware.ardupilot.org/Sub/stable/PX4/ArduSub-v2.px4"
                                print "Downloading stable ArduSub firmware from %s" % firmwareURL
                
                try:
								# 以文件方式打开url
                                firmwarefile = urlopen(firmwareURL)
                                with open("/tmp/ArduSub-v2.px4", "wb") as local_file:
                                    local_file.write(firmwarefile.read())
                                    
                                local_file.close()
                
                except Exception as e:
                                print(e)
                                print "Error downloading firmware! Do you have an internet connection? Try 'ping ardusub.com'"
                                exit(1)
                                
                
# Stop screen session with mavproxy
print "Stopping mavproxy"
os.system("screen -X -S mavproxy quit")

# Flash Pixhawk
print "Flashing Pixhawk..."
if options.file is not None:
	# --port 后都是命令行参数
    if(os.system("python -u /home/pi/companion/tools/px_uploader.py --port /dev/serial/by-id/usb-3D_Robotics_PX4_FMU_v2.x_0-if00 '%s'" % options.file) != 0):
                print "Error flashing pixhawk!"
                exit(1)
else:
    if(os.system("python -u /home/pi/companion/tools/px_uploader.py --port /dev/serial/by-id/usb-3D_Robotics_PX4_FMU_v2.x_0-if00 /tmp/ArduSub-v2.px4") != 0):
                print "Error flashing pixhawk! Do you have most recent version of companion? Try 'git pull' or scp."
                exit(1)
                

# Wait a few seconds
print "Waiting to restart mavproxy..."
time.sleep(10)

# Start screen session with mavproxy
print "Restarting mavproxy"
os.system("screen -dm -S mavproxy /home/pi/companion/scripts/start_mavproxy_telem_splitter.sh")

print "Complete!"
