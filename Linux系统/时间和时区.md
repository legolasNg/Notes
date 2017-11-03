# 时间和时区

## 1、确认时区代码

确认所在地区的时区代码
````
# tzselect
````

## 2、设置时区的系统变量(可选)

编辑/etc/profile
````
# echo "TZ='Asia/Shanghai'; export TZ" >> /etc/profile
# source /etc/profile
````

## 3、修改时区

覆盖时区文件
````
# cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
````

## 4、设置时间

 > date [OPTION]... [+FORMAT]
 > date [-u|--utc|--universal] [MMDDhhmm[[CC]YY][.ss]]

设置时间
````
# date -s 2016/08/21 12:10:10
````
_date命令修改的时间，在系统重启后会重置_
格式化显示时间
````
# date "+%Y-%m-%d %H:%M:%S"
````
强制将系统时间写入CMOS
````
# clock –w
````

## 5、时间同步

查看硬件时间
````
# hwclock --show
````

安装ntpdate
````
# yum install ntpdate
````
时间同步

 > ntpdate [SEREVR]

````
# ntpdate 0.asia.pool.ntp.org
# ntpdate cn.pool.ntp.org
````
