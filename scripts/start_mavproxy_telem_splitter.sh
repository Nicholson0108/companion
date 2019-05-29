# this starts mavproxy so that the serial link to the companion computer (on /dev/ttyACM0)
# is available to a companion computer and external GCSs via UDP. This broadcasts so that
# multiple IP addresses can receive the telemetry.
# 启动mavproxy,使得companion和外部的GCS可以通过UDP知道与
# companion连接的串口(linux(/dev/ttyACM0)/darwin(/dev/tty.usbmodem1))
# 并且通过UDP的广播，可以让多个IP收到遥测数据

# For PixHawk or other connected via USB on Raspberry Pi
cd /home/pi
# Determine if the param file exists.  If not, use default.
if [ -e mavproxy.param ]; then
    paramFile="mavproxy.param"
else
    paramFile="companion/params/mavproxy.param.default"
fi
# Replace all whitespace characters between quote marks with the hex
# representation of a space, remove quote marks
# 用十六进制的空格替换引号之间的所有空格字符，删除引号
mavOptions=$(cat $paramFile \
    | awk '!(NR%2){gsub(FS,"\\x20")}1' RS=\" ORS=)
mavproxy.py $mavOptions
