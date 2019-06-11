#!/usr/bin/python
# encoding=utf-8

# 找到控制站参数文件，默认/fw/standard.params
# 设置端口linux(/dev/ttyACM0)/darwin(/dev/tty.usbmodem1)，读取并设置参数

import platform
import csv
import time
import os
from pymavlink import mavutil
from pymavlink.dialects.v10 import common as mavlink
from pymavlink import mavparm
from optparse import OptionParser

timeout = 1

# 设置命令行参数
parser = OptionParser()
parser.add_option("--file", dest="file", default=None, help="Load from file")
(options,args) = parser.parse_args()

# 设置读取文件，默认/fw/standard.params
if options.file is not None:
    try:
        print("Attempting upload from file %s") % options.file
        filename = options.file
    except Exception as e:
        print("Error opening file %s: %s") % (options.file, e)
        exit(1)
else:
    filename = 'standard.params'

# Port settings
port = ''
if platform.system() == 'Linux':
	port = '/dev/ttyACM0'
elif platform.system() == 'Darwin':
	port = '/dev/tty.usbmodem1'

print "Waiting for heartbeat."

# 连接端口，等待心跳包
try:
	master = mavutil.mavlink_connection(port)
	master.wait_heartbeat()
except:
	print "Trying again."
	time.sleep(6)
	master = mavutil.mavlink_connection(port)
	master.wait_heartbeat()

# Stop screen session with mavproxy
print "Stopping mavproxy"
os.system("screen -X -S mavproxy quit")

# Upload parameter file
print "Uploading parameter file."

failed = []

# 打开文件
with open(filename,'r') as f:
	for line in f:
		# 读取参数
		line = line.split(',')
		name = line[0]
		value = float(line[1])
		
		verified = False
		attempts = 0
		
		print "Sending " + name + " = " + str(value) + "\t\t\t", 
		
		# 尝试修改参数，至多尝试三次
		while not verified and attempts < 3:
			master.param_set_send(name,value)
			start = time.time()
						
			while time.time() < start + timeout:
				msg = master.recv_match()
				if msg is not None:
					if msg.get_type() == "PARAM_VALUE" and msg.param_id == name and msg.param_value == value:
						print " OK"
						verified = True
						break
				time.sleep(0.01)
				
			attempts = attempts + 1
			
		if not verified:
			print " FAIL!"
			failed.append(name)

	f.close()
	if len(failed) > 0:
		print("Failed to set %s") % failed
	else:
		print("Parameter flash successful!")

# Wait a few seconds
print "Waiting to restart mavproxy..."
time.sleep(4)

# Start screen session with mavproxy
print "Restarting mavproxy"
os.system("screen -dm -S mavproxy /home/pi/companion/scripts/start_mavproxy_telem_splitter.sh")
