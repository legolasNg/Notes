# Memcache说明

## 1、安装

````
$ sudo yum install libmemcached memcached libevent
````

## 2、命令行参数

````
-d  以守护进程形式运行
-u  运行memcached的用户
-m  使用的内存空间大小
-M  内存使用超出配置值时，禁止自动清除缓存中的数据项
-c  最大并发连接数(默认1024)
-p  监听的TCP端口
-U  监听的UDP端口
-l  监听的ip地址
-s  监听的UNIX socket文件
-a  设置-s选项指定的UNIX socket文件的权限
-P  pid文件
-t  用来处理请求的线程数(默认4)
-f  用于计算缓存数据项的内存块大小的乘数因子(默认1.25)
-n  为缓存数据项的key、value、flag设置最小分配字节数(默认48)
-k  设置锁定所有分页的内存，对于大缓存应用场景
-r  产生core文件大小
-C  禁用CAS
-h  显示Memcached版本和摘要信息
-V  输出警告和错误信息
-vv 打印信息比-v更详细：不仅输出警告和错误信息，也输出客户端请求和响应信息
-i  打印libevent和Memcached的licenses信息
-D  用于统计报告中Key前缀和ID之间的分隔符(默认是冒号":")
-L  尝试使用大内存分页(HugePage)
-B  指定使用的协议，默认行为是自动协商(autonegotiate)，可能使用的选项有auto、ascii、binary
-I  覆盖默认的STAB页大小(默认1M)
-F	禁用flush_all命令
-o  指定逗号分隔的选项，一般用于用于扩展或实验性质的选项
````

通过命令行，启动一个memcached守护进程
````
$ sudo memcached -d -m 512 -c 5000 -t 8 -f 1.1 -n 100 -u zbgame -l 172.31.8.123 -p 15000 -P /data/memcached/memcachedLogin.pid
$ sudo memcached -d -m 1024 -c 3000 -t 4 -f 1.25 -n 180 -u zbgame -l 10.162.87.55 -p 15001 -P /data/memcached/memcachedServer1.pid
````

## 3.使用systemd开启memcached守护进程

修改`/etc/sysconfig/memcached`配置文件:

```
# 端口(等同于-p)
PORT="15000"
# 运行用户(等同于-u)
USER="zbgame"
# 最大连接数(等同于-c)
MAXCONN="2048"
# 使用内存大小(等同于-m)
CACHESIZE="256"
# 附加参数
OPTIONS="-t 4 -f 1.25 -n 120 -l 10.30.47.227 -P /data/memcached/memcached.pid"
```

使用systemd操作memcached服务:

```bash
$ sudo systemctl enable memcached
$ sudo systemctl start memcached
$ sudo systemctl stop memcached
$ sudo systemctl restart memcached
```

## 4.使用

通过telnet连接到memcached服务器`telnet [IP] [PORT]`，在telnet交互中输入命令，可以操作memcached:

```
# 显示服务器信息和统计数据
stats
# 显示各个slab的信息，包括chunk的大小、数目、使用情况等
stats slabs
# 显示各个slab中item的数目和最老item的时间
stats items
# 设置或者显示详细操作记录
# on，打开详细操作记录
# off，关闭详细操作记录
# dump，显示详细操作记录(每一个键值get、set、hit、del的次数)
stats detail [on|off|dump]
# 打印内存分配信息
stats malloc
# 打印缓存使用信息
stats sizes
# 重置统计信息
stats reset

# 获取缓存的数据(可以多个key)
get <key>
# 修改key的数据
set <key> <flags> <exptime> <bytes> [noreply]\r\n<value>\r\n
# 删除缓存中key
delete <key>
# 添加key
add <key> <flags> <exptime> <bytes> [noreply]\r\n<value>\r\n
# 覆盖一个已经存在Key及其对应的Value，替换一定要保证替换后的值的长度原始长度相同，否则replace失败
replace <key> <flags> <exptime> <bytes> [noreply]\r\n<value>\r\n
# 在一个已经存在的数据值(value)上追加，是在数据值的后面追加
append <key> <flags> <exptime> <bytes> [noreply]\r\n<value>\r\n
# 在一个已经存在的数据值（value）上追加，是在数据值的前面追加
prepend <key> <flags> <exptime> <bytes> [noreply]\r\n<value>\r\n
# 计数命令，可以在原来已经存在的数字上进行累加求和，计算并存储新的数值
incr <key> <value> [noreply]\r\n
# 计数命令，可以在原来已经存在的数字上进行减法计算，计算并存储新的数值
decr <key> <value> [noreply]\r\n
# 使缓存中的数据项失效，可选参数是在多少秒后失效
flush_all [<time>] [noreply]\r\n
# 返回Memcached服务器的版本信息
version
# 退出telnet终端
quit
```
