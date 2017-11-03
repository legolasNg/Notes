
## 防火墙介绍

CentOS7中，`firewalld`取代`iptables`。

## Firewalld

````
$ sudo firewall-cmd --list-all
$ sudo firewall-cmd --zone=public --add-port=9001-9010/tcp --permanent
$ sudo firewall-cmd --zone=public --remove-port=9005/tcp --permanent
$ sudo firewall-cmd --reload
````

### 简介

动态防火墙后台程序`firewalld`提供了一个动态管理的防火墙。

- 用以支持网络 “zones” ，以分配对一个网络及其相关链接和界面一定程度的信任。
- 具备对 IPv4 和 IPv6 防火墙设置的支持。它支持以太网桥，并有分离运行时间和永久性配置选择。
- 具备一个通向服务或者应用程序以直接增加防火墙规则的接口。

### 安装和使用

````
# yum install firewalld
# systemctl enable/disable firewalld
# systemctl start/stop/restart firewalld
````

检查是否运行

````
# systemctl status firewalld
# firewall-cmd --state
````

### 配置路径

`firewalld`将配置储存在`/usr/lib/firewalld/`和`/etc/firewalld/`中的各种XML文件里。

### 管理防火墙规则

`firewalld`规则更改，不会再创建任何新的规则，仅仅运行规则中的不同之处。因此，firewalld 可以在运行时间内，改变设置而不丢失现行连接。

### 网络区(zone)

基于用户对网络中设备和交通所给与的信任程度，防火墙可以用来将网络分割成不同的区域。`NetworkManager`通知`firewalld`一个接口归属某个区域。接口所分配的区域可以由`NetworkManager`改变，也可以通过能为您打开相关`NetworkManager`窗口的`firewall-config`工具进行。

> `drop(丢弃)`: 任何接收的网络数据包都被丢弃，没有任何回复。仅能有发送出去的网络连接。

> `block(限制)`: 任何接收的网络连接都被 IPv4 的 icmp-host-prohibited 信息和 IPv6 的 icmp6-adm-prohibited 信息所拒绝。

> `public(公共)`: 在公共区域内使用，不能相信网络内的其他计算机不会对您的计算机造成危害，只能接收经过选取的连接。

> `external(外部)`: 特别是为路由器启用了伪装功能的外部网。您不能信任来自网络的其他计算，不能相信它们不会对您的计算机造成危害，只能接收经过选择的连接。

> `dmz(非军事区)`: 用于您的非军事区内的电脑，此区域内可公开访问，可以有限地进入您的内部网络，仅仅接收经过选择的连接。

> `work(工作)`: 用于工作区。您可以基本相信网络内的其他电脑不会危害您的电脑。仅仅接收经过选择的连接。

> `home(家庭)`: 用于家庭网络。您可以基本信任网络内的其他计算机不会危害您的计算机。仅仅接收经过选择的连接。

> `internal(内部):`: 用于内部网络。您可以基本上信任网络内的其他计算机不会威胁您的计算机。仅仅接受经过选择的连接。

> `trusted(信任)`: 可接受所有的网络连接。

指定其中一个区域为默认区域是可行的。当接口连接加入了`NetworkManager`，它们就被分配为默认区域。安装时，`firewalld`里的默认区域被设定为公共区域。

### 服务

预定义的服务(以root用户执行)

````
# ls /usr/lib/firewalld/services/
````

系统或者用户创建的服务(以root用户执行)

````
# ls /etc/firewalld/services/
````

望增加或者改变服务，`/usr/lib/firewalld/services/`文件可以作为模板使用(以root用户执行)

````
# cp /usr/lib/firewalld/services/[service].xml /etc/firewalld/services/[service].xml
````

`firewalld`优先使用`/etc/firewalld/services/`里的文件，如果一份文件被删除且服务被重新加载后，会切换到`/usr/lib/firewalld/services/`。

`firewall-cmd`命令可以由`root`用户运行，也可以由管理员用户--`wheel`组(group)的成员运行。

### 直接接口

`firewalld`有一个被称为"direct interface"(直接接口)，它可以直接通过`iptables`，`ip6tables`和`ebtables`的规则。它适用于应用程序，而不是用户。
`firewalld`保持对所增加项目的追踪，所以它还能质询`firewalld`和发现由使用直接端口模式的程序造成的更改。直接端口由增加`--direct`选项到`firewall-cmd`命令来使用。

### 命令行操作

#### 注意事项

- *设置一个永久或者可执行命令，除了`--direct`命令(本质上是暂时的)之外，要向所有命令添加`--permanent`选择(更改将在防火墙重新加载、服务器重启或者系统重启之后生效)*
- *缺少`--permanent`选项的设定能立即生效，但是它仅仅在下次防火墙重新加载、系统启动或者 firewalld 服务重启之前可用*

#### 分区zone

获取当前生效的zone
````
# firewall-cmd --get-active-zones
````

获取分配的接口(interface)的zone
````
# firewall-cmd --get-zone-of-interface=[interface_name]
````

获取某个zone分配的所有接口
````
# firewall-cmd --zone=[zone_name] --list-interfaces
````

获取某个zone的所有设置
````
# firewall-cmd --zone=public --list-all
````

为zone增加接口(增加`--permanent`选项并重新加载防火墙，使之成为永久性设置。)
````
# firewall-cmd --zone=[zone_name] --add-interface=[interface_name]
````

通过编辑`ifcfg-[interface_name]`配置文件来为一个分区增加接口"interface_name"。`NetworkManager`程序将自动连接，相应分区将被设定
````
ZONE=[zone_name]
````

编辑`/etc/firewalld/firewalld.conf`配置默认分区zone，然后重新加载防火墙
````
# default zone
# The default zone used if an empty zone string is used.
# Default: public
DefaultZone=[zone_name]
````

````
# firewall-cmd --reload
````

输入以下命令来设置默认分区(更改将立刻生效，而且在此情况下不需要重新加载防火墙)
````
# firewall-cmd --set-default-zone=[zone_name]
````

查看某分区的所有开放端口
````
# firewall-cmd --zone=[zone_name] --list-ports
````

将一个端口加入一个分区(增加`--permanent`选项并重新加载防火墙，使之成为永久性设置)
````
# firewall-cmd --zone=[zone_name] --add-port=[port]/tcp
# firewall-cmd --zone=[zone_name] --add-port=[port]/udp

# firewall-cmd --zone=[zone_name] --add-port=[start_port]-[end_port]/tcp
# firewall-cmd --zone=[zone_name] --add-port=[start_port]-[end_port]/udp
````

#### 服务service

获取所有活跃的网络服务(列出`/usr/lib/firewalld/services/`中的服务名称，配置文件是以服务本身命名的`service-name.xml`)
````
# firewall-cmd --get-service
````

获取下次加载后将活跃网络服务
````
# firewall-cmd --get-service --permanent
````

将服务加入到分区(增加`--permanent`选项并重新加载防火墙，使之成为永久性设置)
````
# firewall-cmd --zone=[zone_name] --add-service=[service_name]
# firewall-cmd --reload
````

从分区移除服务(增加`--permanent`选项并重新加载防火墙，使之成为永久性设置)
````
# firewall-cmd --zone=[zone_name] --remove-service=[service_name]
# firewall-cmd --reload
````

查看默认分区模板
````
# ls /usr/lib/firewalld/zones/
=>  block.xml  drop.xml      home.xml      public.xml   work.xml
    dmz.xml    external.xml  internal.xml  trusted.xml
````

查看分区配置文件，如果不存在则从模板复制，并编辑XML文件为一个分区增加或者移除服务
(可以在`/etc/firewalld/zones/`目录中编辑该文件。如果您删除该文件，`firewalld`将切换到使用`/usr/lib/firewalld/zones/`里的默认文件)
````
# ls /etc/firewalld/zones/
=>  external.xml  public.xml
# cp /usr/lib/firewalld/zones/[zone_name].xml /etc/firewalld/zones/
# vi /etc/firewalld/zones/[zone_name].xml
=>  <service name="[service_name]"/>
````

#### 配置伪装IP地址

查看伪装IP是否能为某个分区启用(如果可用，屏幕会显示yes，退出状态为0； 否则，屏幕显示no，退出状态为1。如果省略zone ，默认区域将被使用。)
````
# firewall-cmd --zone=[zone_name] --query-masquerade
````




#### Panic模式

终止所有数据包(Panic模式)，所有输入和输出的数据包都将被终止。在一段休止状态之后，活动的连接将被终止；花费的时间由单个会话的超时值决定。
````
# firewall-cmd --panic-on
````

再次传输输入和输出的数据包
````
# firewall-cmd --panic-off
````

确定`panic`模式是否使用
````
# firewall-cmd --query-panic
````

重新加载防火墙(并不中断用户连接，即不丢失状态信息)
````
# firewall-cmd --reload
````

重新加载防火墙(并中断用户连接，即丢弃状态信息)
````
# firewall-cmd --complete-reload
````


## Iptables

### 安装和使用

先禁用`firewalld`

```
# systemctl disable firewalld
# systemctl stop firewalld
```

安装`iptables`和`ip6tables`

````
# yum install iptables-services
# systemctl enable/disable iptables
# systemctl start/stop/restart iptables
# systemctl status iptables

# systemctl enable/disable ip6tables
# systemctl start/stop/restart ip6tables
# systemctl status ip6tables
````

### 配置路径

`iptables service`在`/etc/sysconfig/iptables`中储存配置。

### 管理防火墙规则

`iptables service`，每一个规则更改意味着清除所有旧有的规则，然后从`/etc/sysconfig/iptables`里读取所有新的规则。

防火墙设置

````
-A:         指定链名   
-p:         指定协议类型
-d:         指定目标地址
--dport:    指定目标端口(destination port 目的端口)
--sport:    指定源端口(source port 源端口)
-j:         指定动作类型

iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A OUTPUT -p tcp --sport 22 -j ACCEPT
iptables -I INPUT -s 124.45.0.0/16 -j DROP
````
