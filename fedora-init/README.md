# Feddora系统初始化

## 一、软件源配置

### 1.添加RPMFusion源

```bash
## free仓库
sudo dnf install http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm

## non-free仓库
sudo dnf install http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
```

最后运行`sudo dnf makecache`生成缓存

### 2.官方源替换中科大源

将以下保存为`fedora.repo`:

```ini
[fedora]
name=Fedora $releasever - $basearch - ustc
failovermethod=priority
baseurl=https://mirrors.ustc.edu.cn/fedora/releases/$releasever/Everything/$basearch/os/
#metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch
enabled=1
metadata_expire=7d
repo_gpgcheck=0
type=rpm
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[fedora-debuginfo]
name=Fedora $releasever - $basearch - Debug - ustc
failovermethod=priority
baseurl=https://mirrors.ustc.edu.cn/fedora/releases/$releasever/Everything/$basearch/debug/tree/
#metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-debug-$releasever&arch=$basearch
enabled=0
metadata_expire=7d
repo_gpgcheck=0
type=rpm
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[fedora-source]
name=Fedora $releasever - Source - ustc
failovermethod=priority
baseurl=https://mirrors.ustc.edu.cn/fedora/releases/$releasever/Everything/source/tree/
#metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-source-$releasever&arch=$basearch
enabled=0
metadata_expire=7d
repo_gpgcheck=0
type=rpm
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
```

将以下保存为`fedora-updates.repo`:

```ini
[updates]
name=Fedora $releasever - $basearch - Updates - ustc
failovermethod=priority
baseurl=https://mirrors.ustc.edu.cn/fedora/updates/$releasever/Everything/$basearch/
#metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-f$releasever&arch=$basearch
enabled=1
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-debuginfo]
name=Fedora $releasever - $basearch - Updates - Debug - ustc
failovermethod=priority
baseurl=https://mirrors.ustc.edu.cn/fedora/updates/$releasever/Everything/$basearch/debug/tree/
#metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-debug-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-source]
name=Fedora $releasever - Updates Source - ustc
failovermethod=priority
baseurl=https://mirrors.ustc.edu.cn/fedora/updates/$releasever/Everything/source/tree/
#metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-source-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
```

最后运行`sudo dnf makecache`生成缓存

### 3.flatpak包支持

```bash
sudo dnf install flatpak

sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```

在 [flathub](https://flathub.org/home) 找相应的app，可以安装flatpak软件:

```
sudo flatpak install flathub com.visualstudio.code
```

### 4.添加fedy源

依赖于RPMFusion源

```bash
sudo dnf install https://dl.folkswithhats.org/fedora/$(rpm -E %fedora)/RPMS/fedy-release.rpm

sudo dnf install fedy
```

## 二、配置修改

### 1.修改dnf配置

修改`/etc/dnf/dnf.conf`配置文件

```ini
[main]
; 是否开启gpg校验
gpgcheck=1
; 允许保留多少旧内核包
installonly_limit=3
; 删除软件同时删除依赖包
clean_requirements_on_remove=True
; 查找最快镜像
fastestmirror=true
; 下载增量包
deltarpm=true
; 最大并发下载数量
max_parallel_downloads=6
```

### 2.修改SELinux配置

查看SELinux状态:

```bash
/usr/sbin/sestatus -v 
```

如果状态是enabled，则代表SELinux开启，需要修改`/etc/selinux/config`配置文件，将SELINUX修改为disabled:

```ini
SELINUX=disabled
```

### 3. 修改sudo配置

在root用户下安装sudo:

```bash
dnf install sudo
```

修改`/etc/sudoers`配置文件:

```bash
root                ALL=(ALL)       ALL

%wheel          ALL=(ALL)       ALL
USERNAME    ALL=(ALL)       ALL
```

其他需要sudo的用户，可以将用户添加到wheel组:

```bash
usermod -aG wheel USERNAME
```

## 三、必备软件

### 1.常用软件

```bash
sudo dnf install htop 
sudo dnf install screenfetch
sudo dnf install vim git
sudo dnf install zsh
sudo dnf install gcc gcc-c++ gdb
sudo dnf install mpv 
sudo dnf install unrar unzip
```

### 2.安装chrome

```bash
## 安装第三方软件源
sudo dnf install fedora-workstation-repositories

## 启用chrome仓库
sudo dnf config-manager --set-enabled google-chrome

## 安装
sudo dnf install google-chrome-stable
```

### 3.安装steam

```bash
sudo dnf install fedora-workstation-repositories

sudo dnf config-manager --set-enabled rpmfusion-nonfree-steam

sudo dnf install steam
```

### 4.安装gnome-tweaks

```bash
sudo dnf install gnome-tweaks

## 安装浏览器gnome扩展组件
sudo dnf install chrome-gnome-shell

## 安装菜单编辑器
sudo dnf install menulibre
```

常见的gnome扩展插件:

- Alternative tab

- Applications menu

- Dash to dock

- Launch new instance

- Media player indicator

- Places Status Indicator

- Removable Drive Menu

- Topicons / Topicons plus(好像有bug)

- User themes

- Windows list

- System-monitor

### 5.安装"右键终端打开"

```bash
sudo dnf install nautilus-open-terminal
```

### 6.安装vscode

```
## 导入密钥
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

## 创建repo
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'

## 安装vscode
dnf check-update
sudo dnf install code
```

### 7.安装non-free解码器

```bash
sudo dnf install gstreamer-plugins-base gstreamer1-plugins-base gstreamer-plugins-bad gstreamer-plugins-ugly gstreamer1-plugins-ugly gstreamer-plugins-good-extras gstreamer1-plugins-good-extras gstreamer1-plugins-bad-freeworld ffmpeg gstreamer-ffmpeg ffmpeg-libs xvidcore libdvdread libdvdnav lsdvd libmpg123
```

### 8.安装音频组件

```bash
sudo dnf install pulseaudio
```

如果系统没有声音，可能是alsamixer配置问题，默认是静音。通过命令`alsamixer`启动，按下`F6`选择声卡，将`Auto-Mute Mod`一项修改为"disabled"。

### 9.安装fcitx

```bash
sudo dnf install fcitx fcitx-cloudpinyin fcitx-configtool fcitx-gtk2 fcitx-gtk3
```

如果使用的是`Wayland`显示管理器，在`/etc/environment`中加入:

```bash
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
```

由于系统自带ibus输入法，ibus和gnome依赖关系，卸载ibus可能会删除gnome。只需要在设置"Region & Language" => "输入源"中删除中文相关的输入源，只保留英语(美国)即可。

### 10.安装shadowsocks-qt5

```bash
## 添加shadowsocks的Copr源
sudo dnf copr enable librehat/shadowsocks

## 安装
sudo dnf update
sudo dnf install shadowsocks-qt5

## 出现libbotan-2.so.5 was missing的问题，是由于libbotan版本过高，做个软链接即可解决
sudo ln -s /usr/lib64/libbotan-2.so.7 /usr/lib64/libbotan-2.so.5

## 命令行使用代理，只需要设置环境变量即可，协议名与开放端口协议一致:
export http_proxy="socks5://1.1.1.1:1080"
export https_proxy="socks5://1.1.1.1:1080"
```

### 11.安装字体和主题

```bash
## 安装numix主题
sudo dnf install numix-gtk-theme

## 安装numix和numix-circle图标
sudo dnf install numix-icon-theme numix-icon-theme-circle

## 安装paper图标
sudo dnf config-manager --add-repo https://download.opensuse.org/repositories/home:snwh:paper/Fedora_25/home:snwh:paper.repo
sudo dnf install paper-icon-theme

## 安装思源字体(等宽、衬线)
sudo dnf install adobe-source-code-pro-fonts adobe-source-sans-pro-fonts adobe-source-serif-pro-fonts 
## 安装思源黑体(建议中文字体使用这个)
sudo dnf install adobe-source-han-sans-cn-fonts
```

安装字体和主题后，通过`gnome-tweaks`来设置字体和主题

## 12.安装网易云音乐

```bash
## 安装解码器
sudo dnf install gstreamer-plugins-base gstreamer1-plugins-base gstreamer-plugins-bad gstreamer-plugins-ugly gstreamer1-plugins-ugly gstreamer-plugins-good-extras gstreamer1-plugins-good-extras gstreamer1-plugins-bad-freeworld ffmpeg gstreamer-ffmpeg ffmpeg-libs xvidcore libdvdread libdvdnav lsdvd libmpg123
## 安装依赖(1.1版本的网易云音乐将很多库都打包了，所以需要手动解决的依赖很少)
sudo dnf install vlc

## 下载官网的deb包
mkdir netease-cloud-music
cd netease-cloud-music
wget http://d1.music.126.net/dmusic/netease-cloud-music_1.1.0_amd64_ubuntu.deb

## 解压deb包
ar -xvf netease-cloud-music_1.1.0_amd64_ubuntu.deb
##  解压data包(control.tar.gz主要是用于文件校验，debian-binary是deb的版本)
tar -xvf data.tar.xz

## 复制文件到/usr
sudo cp -r usr/* /usr/
```