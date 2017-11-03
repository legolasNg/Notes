# Rsync 说明

## 1、centos下安装和配置

### 安装

````
$ sudo yum install xinetd rsync
````

### 配置

编辑/etc/xinetd.d/rsync，如果没有就创建

````
service rsync
{
        disable = no
        flags           = IPv6
        socket_type     = stream
        wait            = no
        user            = root
        server          = /usr/bin/rsync
        server_args     = --daemon
        log_on_failure  += USERID
}
````

或者直接编辑/etc/rsync.conf，如果没有就创建

````
port =  873
uid = root
gid = root
use chroot=no
read only = yes
hosts allow=*
max connextions = 4

[www]
path = /data/
auth users = legolas
secrets file = /etc/rsync.pass
read noly = yes
list = no
hosts allow = *
````

然后编辑密码文件/etc/rsync.pass

````
legolas:123456
````

### 启动守护进程deamon

````
$ sudo systemctl enable xinetd
$ sudo systemctl start xinetd
````


## 2、windows下安装和配置

### 下载cwRsyncServer和cwRsync

````
cwRsyncServer 4.0.5
https://www.itefix.no/i2/sites/default/files/cwRsyncServer_4.0.5_Installer.zip

cwRsync 4.0.5
https://www.itefix.no/i2/sites/default/files/cwRsync_4.0.5_Installer.zip
````

### 配置

windows下，编辑C:\Program Files (x86)\ICW\rsyncd.conf

````
use chroot = false
strict modes = false		#验证用户密码
hosts allow = *				#允许所有IP访问
max connections = 5
log file = rsyncd.log		#日志文件
lock file = rsyncd.lock		#lock文件
port = 873					#服务端口号
pid file = rsyncd.pid 		#进程文件
uid = 0						#不限定用户
gid = 0 					#不限定组

# Module definitions
# Remember cygwin naming conventions : c:\work becomes /cygwin/c/work
#
[test]                      #认证的模块名
path = /cygdrive/d/httpserver                           #模块路径
auth users = legolas	                                #可访问用户名(密码文件中的用户名)
secrets file = /cygdrive/c/rsync.pas                    #用户名对应的密码文件
read only = false
transfer logging = yes
````

_ 路径需要以posix风格来书写，即前面加上**cygdrive** _

然后编辑密码文件/cygdrive/c/rsync.pas

````
legolas:123456
````

### 环境变量配置

将"D:\Program Files (x86)\cwRsync\bin"加入环境变量PATH中

### 修改密码文件的权限

"/cygdrive/c/rsync.pas"文件的权限加入Rsycn服务运行服务的用户名(假如为legolas)的读取权限及设置其为该文件为所有者

### 启动守护进程deamon

> 我的电脑右键->管理->服务和应用程序->服务(或者直接运行services.msc)。
> 选择服务"RsyncServer"配置启动类型为"自动"，后启动该服务


## 3、客户端使用

命令形式(源文件 => 目标文件)

````
$ async /src /dest
````

同步文件(rsync协议)

````
$ rsync -avzP --port=873 admin@192.168.2.22::test /dest
$ rsync -avzP rsync://admin@192.168.2.22:873/test /dest
````

通过ssh同步

````
$ rsync -avzP -e ssh admin@192.168.2.22:873:/test /dest
$ rsync -avzP -e "/bin/ssh" admin@192.168.2.22:873:/test /dest
$ rsync -e "/usr/bin/sshpass -p'eir2Didei8haelu' /usr/bin/ssh" -avzP admin@192.168.2.22:873:/test /dest
$ rsync -e "/usr/bin/ssh -i /root/.ec2-user.pem" -avzP admin@192.168.2.22:873:/test /dest
````

参数

````
-a 参数，相当于-rlptgoD：
-r 是递归
-l 是链接文件，意思是拷贝链接文件
-p 表示保持文件原有权限
-t 保持文件原有时间
-g 保持文件原有用户组
-o 保持文件原有属主
-D 相当于块设备文件

-v 详细模式输出
-z 传输时压缩
-P 显示传输进度

--progress 显示备份同步过程
--delete 删除Client中有Server没有的文件
--port指定端口
--password-file指定密码文件
````
