# SSH说明

## 1、启动和关闭

centos 5.x、centos 6.x等发行版
````
$ sudo chkconfig sshd on
$ sudo service sshd start
$ sudo service sshd restart
$ sudo service sshd stop
````
centos 7等发行版
````
$ sudo systemctl enable sshd
$ sudo systemctl start sshd
$ sudo systemctl restart sshd
$ sudo systemctl stop sshd
````

## 2、配置/etc/ssh/sshd_config

````
# 是否允许root登录
#PermitRootLogin no
PermitRootLogin forced-commands-only

# 密码登录验证
PasswordAuthentication no

# 非对称密钥验证
UsePAM yes

# 端口
#Port 22

# 主机私钥位置
HostKey /etc/ssh/ssh_host_rsa_key
# 存放登录公钥位置
AuthorizedKeysFile .ssh/authorized_keys

# 是否允许质疑-应答
ChallengeResponseAuthentication no
````

重启sshd，使配置生效
````
# sudo systemctl restart sshd
````

## 3、密钥登录

生成公钥和私钥
````
# cd /root/.ssh/
# ssh-keygen -t rsa
````
将生成的id_rsa.pub文件内容复制到authorized_keys
````
# cat id_rsa.pub >> /root/.ssh/authorized_keys
````
将公钥id_rsa.pub删除(可选)，将私钥id_rsa下载至本地
修改对应的sshd配置，重启sshd后再重新登录

## 4、SSH命令

 > ssh [-c cipher] [-p port] [-i identity_file] [user@]hostname [command]

````
-l 指定用户名
-p 指定端口(默认22)
-C 对数据进行压缩
-c 加密算法
-D [bind_address:]port 绑定源地址(适用于机器有多个IP地址)
-b bind_address 绑定源地址
````
ssh连接
````
$ ssh -i /legolas/legolas.pem legolas@192.168.2.25
````
ssh远程执行命令
````
$ ssh -i /legolas/legolas.pem legolas@192.168.2.25 "cat /etc/os-release"
````

## 5、SCP和SFTP命令

scp传输文件
````
$ scp -P -i [identity-file] [port] [user]@[remote-ip]:[remote-file] [local-file]
$ scp -P -i [identity-file] [port] [local-file] [user]@[remote-ip]:[remote-file]
````
scp传输目录
````
$ scp -P [port] -i [identity-file] -r [user]@[remote-ip]:[remote-directory] [local-directory]
$ scp -P [port] -i [identity-file] -r [local-directory] [user]@[remote-ip]:[remote-directory]
````
sftp传输文件
````
$ sftp -i [identity_file] -o [ssh_option] -P [port] -c [cipher] [user]@[remote-ip]:[remote-file] [local-file]
$ sftp -i [identity_file] -o [ssh_option] -P [port] -c [cipher] -r [user]@[remote-ip]:[remote-directory] [local-directory]
````

## 6、sshpass工具

命令行中免输入ssh密码
````
sshpass -p'eir2Didei8haelu' /usr/bin/ssh
````

## 7、ssh连接时间过长

使用`ssh -vv`查看ssh连接时的debug信息，分析耗时具体在哪个环节，然后去修改`/etc/ssh/sshd_config`中的相关配置。

### Authentications方式冗余

如果连接在尝试Authentications(认证方式)时耗时太多，在下面这个地方停留时间过长。

````
debug1: SSH2_MSG_SERVICE_ACCEPT received
debug1: Authentications that can continue: publickey,gssapi-keyex,gssapi-with-mic,password
````

我们可以避免ssh去尝试不必要的认证方式，根据你自己的使用情况去禁用部分配置选项。例如：

````
# 密码验证
PasswordAuthentication yes
# 质疑-应答认证(ssh的时候会返回challenge，然后根据challenge生成response，用response登录)，可以禁用
ChallengeResponseAuthentication no
# 使用基于GSSAPI的用户认证，可以禁用
GSSAPIAuthentication no
# 用户退出登录后自动销毁用户凭证缓存
GSSAPICleanupCredentials no
# 非对称密钥验证是否开启。建议开启，关闭之后可能会password登陆失败
UsePAM yes
# 采用公/密钥的方式进行身份验证，这个可以保留。
PubkeyAuthentication yes
# X11转发，一般ssh都不会使用远程的X11图形，也可以禁用
X11Forwarding no
````

### 地址解析时间过长

如果减少了尝试的认证方式之后，ssh连接仍然在这个地方耗时过长，那就有可能是认证过程中的DNS解析太慢。
如果我们使用的ip地址去访问，不需要域名解析。大可省略DNS解析这个步骤。

````
# 禁用dns解析
UseDNS no
````

### 权限问题(权限过大或者过小，都会导致ssh无法访问)

`~/.ssh`如果不存在，应该创建该目录，目录权限是0700

```bash
mkdir ~/.ssh
sudo chmod 0700 ~/.ssh
```

`~/.ssh/authorized_keys`如果不存在，应该创建该文件，文件权限是0600

```bash
touch ~/.ssh/authorized_keys
sudo chmod 0600 ~/.ssh/authorized_keys
```
