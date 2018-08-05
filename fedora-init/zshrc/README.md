## 安装zsh

```bash
sudo dnf install zsh

# 将zsh设置为当前用户的默认shell
chsh -s /bin/zsh

# 将zsh设置为root用户的默认shell
sudo chsh -s /bin/zsh
```

## 安装powerline字体

如果终端字体powerline不生效，需要检查下终端模拟器的配置项，将等宽字体设置为对应的powerline等宽字体

```bash
git clone https://github.com/powerline/fonts.git

cd fonts

./install.sh
```

## 安装awesome-powerline字体

```bash
git clone https://github.com/gabrielelana/awesome-terminal-fonts.git

cd  awesome-terminal-fonts

./install.sh
```

## 安装oh-my-zsh

```bash
## 克隆oh-my-zsh仓库
git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh

## 克隆powerlevel9k主题
git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k

## 备份之前的zsh配置
cp ~/.zshrc ~/.zshrc.backup

## 从github复制配置
curl -o ~/.zshrc https://raw.githubusercontent.com/legolasng/notes/master/fedora-init/zshrc/.zshrc

## 使配置生效
source ~/.zshrc
```