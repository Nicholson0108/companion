#!/usr/bin/python

# 创建socket网络连接端点，监听0.0.0.0：18990端口，并实现对端口字典ENDPOINTS的操作

import socket
import time
import json
import endpoint

debug = False

# load configuration from file
try:
    print 'loading configuration from file...'
    endpoint.load('/home/pi/routing.conf')
    print 'configuration successfully loaded'
except Exception as e:
    print 'error loading configuration'
    print e
    pass

# we will listen here for requests
# 创建socket网络连接端点
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
# 设置成非阻塞式，如果所做的动作将导致阻塞，将会引起error异常
sock.setblocking(False)
# 绑定指定IP和端口
sock.bind(('0.0.0.0', 18990))

# 监听端口
while True:
    # don't hog the cpu
	# 推迟调用线程的运行，括号里是秒数
    time.sleep(0.01)
    
    # read all endpoints and write all routes
    for _endpoint in endpoint.endpoints:
        _endpoint.read()
        
    try:
        # see ifinbound traffic there is a new request
		# recvfrom返回数据和地址，括号里是缓存空间
        data, address = sock.recvfrom(1024)
        print("\n%s sent %s\n") % (address, data)
        
		# 将JSON格式转换成字典
        msg = json.loads(data)
        
        try:
            request = msg['request']
            print("Got request %s") % request
        except:
            print "No request!"
            continue
        
        if request == 'add endpoint':
            endpoint.add(endpoint.from_json(msg))
            
        elif request == 'remove endpoint':
            endpoint.remove(msg['id'])
			# 将字典转成JSON格式并发送到监听到的地址           
			sock.sendto(endpoint.to_json(), address)
            
        elif request == 'connect endpoints':
            print('got connect request: %s') % data
            endpoint.connect(msg['source'], msg['target'])
            
        elif request == 'disconnect endpoints':
            endpoint.disconnect(msg['source'], msg['target'])
            
        elif request == 'save all':
            endpoint.save(msg['filename'])
            
        # Hard load用加载的配置直接覆盖当前配置
        # Soft load在当前配置后添加加载的配置
        elif request == 'load all':
            if msg['soft'] == False:
                print("Hard load")
                # TODO: garbage collect?
                endpoint.endpoints = []
            endpoint.load(msg['filename'])
            
        # send updated list of endpoints
        sock.sendto(endpoint.to_json(), address)
        
        # save current list of endpoints
        endpoint.save('/home/pi/routing.conf')
        
    except socket.error as e:
        continue
    except Exception as e:
        print("Error: %s") % e
        continue
