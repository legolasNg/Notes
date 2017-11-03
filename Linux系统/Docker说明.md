## 1.安装

### fedora

````
# 删除非官方的不兼容版本
sudo dnf -y remove docker docker-selinux

# 添加官方repo
sudo dnf config-manager --add-repo https://docs.docker.com/engine/installation/linux/repo_files/fedora/docker.repo
sudo dnf config-manager --set-disabled docker-testing

# 安装
sudo dnf -y install docker-engine

# 列出可选版本
dnf list docker-engine.x86_64  --showduplicates |sort -r
sudo dnf -y install docker-engine-<VERSION_STRING>

# 启动docker
sudo systemctl start docker

# 检验是否安装成功
sudo docker run hello-world
````

### centos

````
# 删除非官方的不兼容版本
sudo yum -y remove docker docker-selinux

# 添加官方repo
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://docs.docker.com/engine/installation/linux/repo_files/centos/docker.repo
sudo yum-config-manager --disable docker-testing

# 安装
sudo yum -y install docker-engine

# 列出可选版本
yum list docker-engine.x86_64  --showduplicates |sort -r
sudo yum -y install docker-engine-<VERSION_STRING>

# 启动docker
sudo systemctl start docker

# 检验是否安装成功
sudo docker run hello-world
````

## 2.修改镜像源

编辑`/etc/docker/daemon.json`文件，添加如下内容：

````
{
    "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn"]
}
````

## 3.使用docker

````
# 搜索可用镜像
docker search [iamge-name]

# 下载容器镜像
docker pull [full-name]

# 运行容器(第一次运行，会从网上下载)
docker run [args...] IMAGE [COMMAND] [ARG...]

# 列出所有运行的容器
docker ps [args...]

# 保存对容器的修改
docker commit [container-id] [name]

# 查看容器详细信息
docker inspect [container-id]

# 守护进程模式下，启停容器
docker [satrt | stop | restart] [container-id]

# 移除已停止的容器
docker [rm | rmi] [container-id]

# 连接到后台运行的容器
docker attach [container-id]

# 发布容器镜像
docker push [full-name]
````
